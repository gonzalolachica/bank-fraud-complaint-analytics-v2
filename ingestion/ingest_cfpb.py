"""
CFPB complaint ingestion -> Supabase public.stg_complaints_raw

Runs on a local machine (CFPB's Akamai protection blocks cloud IPs such as Colab).

Usage (from the BankFraudAnalyticsDBT folder, venv active):
    python ingestion\\ingest_cfpb.py --dry-run   # fetch + validate only, writes nothing
    python ingestion\\ingest_cfpb.py             # fetch + validate + load

Safety rules:
  * Any failed request or failed check aborts the run BEFORE touching the database.
  * The table is never dropped (dbt views depend on it). It is emptied and refilled
    inside ONE transaction: if the load fails, the old data stays.
  * Column names and types match the existing table (14 text columns + bigint id).
  * The database password is typed in at run time and never stored in a file.
"""
import argparse
import getpass
import sys
from datetime import date
from io import StringIO
from urllib.parse import quote

import pandas as pd
import requests
import truststore
from sqlalchemy import BigInteger, Text, create_engine, text
from sqlalchemy.engine import URL

truststore.inject_into_ssl()  # Windows cert store, verification ON

# --- Config -------------------------------------------------------------------
BASE_URL = "https://www.consumerfinance.gov/data-research/consumer-complaints/search/api/v1/"

COMPANIES = [
    "TRUIST FINANCIAL CORPORATION",
    "JPMORGAN CHASE & CO.",
    "AMERICAN EXPRESS COMPANY",
]

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Accept": "text/csv,*/*",
}

FIRST_YEAR = 2020
EXPORT_CAP = 100_000  # CFPB caps filtered exports at 100k rows (Release 23, Jul 2026)

DB = dict(
    host="aws-0-us-east-1.pooler.supabase.com",
    port=5432,
    username="postgres.wzmciexafinrhmelabnk",
    database="postgres",
)
SCHEMA, TABLE = "public", "stg_complaints_raw"

RENAME = {
    "Date received": "date_received",
    "Product": "product",
    "Sub-product": "sub_product",
    "Issue": "issue",
    "Sub-issue": "sub_issue",
    "Company public response": "company_public_response",
    "Company": "company",
    "State": "state",
    "ZIP code": "zip_code",
    "Tags": "tags",
    "Submitted via": "submitted_via",
    "Date sent to company": "date_sent_to_company",
    "Company response to consumer": "company_response_to_consumer",
    "Timely response?": "timely_response",
    "Complaint ID": "complaint_id",
}
COLUMNS = list(RENAME.values())  # exact order of the existing table


def fail(msg):
    print(f"\nABORTED: {msg}\nNothing was written to the database.")
    sys.exit(1)


def enc(s):
    return quote(s, safe="")


# --- 1. Fetch year by year ------------------------------------------------------
def fetch():
    frames = []
    for year in range(FIRST_YEAR, date.today().year + 1):
        query = "format=csv&" + "&".join(f"company={enc(c)}" for c in COMPANIES)
        query += f"&date_received_min={year}-01-01&date_received_max={year}-12-31"
        resp = requests.get(BASE_URL + "?" + query, headers=HEADERS, timeout=180)

        if resp.status_code != 200:
            fail(f"year {year} returned HTTP {resp.status_code}: {resp.text[:300]}")

        # dtype=str: keep values exactly as CFPB sends them (e.g. ZIP leading zeros)
        year_df = pd.read_csv(StringIO(resp.text), dtype=str, keep_default_na=True)
        n = len(year_df)
        print(f"{year}: {n:,} rows")

        if n == 0:
            fail(f"year {year} returned 0 rows")
        if n >= EXPORT_CAP:
            fail(f"year {year} hit the {EXPORT_CAP:,}-row export cap (data would be truncated)")
        frames.append(year_df)

    return pd.concat(frames, ignore_index=True)


# --- 2. Shape to the table contract -------------------------------------------
def shape(df):
    df = df.drop(columns=["Consumer complaint narrative"], errors="ignore")

    missing = set(RENAME) - set(df.columns)
    extra = set(df.columns) - set(RENAME)
    if missing or extra:
        fail(f"CFPB columns changed. Missing: {sorted(missing)}  New: {sorted(extra)}")

    df = df.rename(columns=RENAME)[COLUMNS]

    # Real NULLs (not the text 'nan') for empty values
    df = df.astype(object).where(df.notna(), None)
    df["complaint_id"] = pd.to_numeric(df["complaint_id"], errors="raise").astype("int64")
    return df


# --- 3. Validate before loading -----------------------------------------------
def validate(df):
    if df["complaint_id"].duplicated().any():
        fail(f"{df['complaint_id'].duplicated().sum()} duplicate complaint_id values")
    if df["date_received"].isna().any():
        fail("some rows have no date_received")
    unexpected = set(df["company"].dropna()) - set(COMPANIES)
    if unexpected:
        fail(f"unexpected company names: {sorted(unexpected)}")

    print(f"\nTOTAL ROWS:  {len(df):,}")
    print(f"DATE RANGE:  {df['date_received'].min()}  ->  {df['date_received'].max()}")
    print(df["company"].value_counts().to_string())


# --- 4. Load (empty + refill in ONE transaction) --------------------------------
def load(df):
    password = getpass.getpass("\nSupabase database password: ")
    engine = create_engine(URL.create("postgresql+psycopg2", password=password, **DB))

    dtypes = {c: Text() for c in COLUMNS}
    dtypes["complaint_id"] = BigInteger()

    with engine.begin() as conn:  # commits only if everything inside succeeds
        before = conn.execute(text(f"SELECT COUNT(*) FROM {SCHEMA}.{TABLE}")).scalar()
        conn.execute(text(f"TRUNCATE {SCHEMA}.{TABLE}"))
        df.to_sql(TABLE, conn, schema=SCHEMA, if_exists="append", index=False,
                  dtype=dtypes, method="multi", chunksize=5_000)
        after = conn.execute(text(f"SELECT COUNT(*) FROM {SCHEMA}.{TABLE}")).scalar()
        if after != len(df):
            raise RuntimeError(f"row count mismatch after load: {after} vs {len(df)}")

    print(f"\nLOADED: {before:,} rows before  ->  {after:,} rows now")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="fetch and validate only")
    args = parser.parse_args()

    df = shape(fetch())
    validate(df)

    if args.dry_run:
        print("\nDRY RUN: all checks passed. Nothing was written.")
    else:
        load(df)
