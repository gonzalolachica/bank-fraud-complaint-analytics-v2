"""
Step 1 of the local ingestion: can this computer reach the CFPB API?

Fetches ONE year (2026) for the three companies and prints what came back.
Writes nothing to Supabase.

Run from the BankFraudAnalyticsDBT folder with the venv active:
    python ingestion\\test_api_access.py
"""
from io import StringIO
from urllib.parse import quote

import pandas as pd
import requests
import truststore

# Use the Windows certificate store (it fetches missing intermediate
# certificates automatically), with verification fully ON.
truststore.inject_into_ssl()

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


def enc(s):
    return quote(s, safe="")


query = "format=csv&" + "&".join(f"company={enc(c)}" for c in COMPANIES)
query += "&date_received_min=2026-01-01&date_received_max=2026-12-31"
url = BASE_URL + "?" + query

resp = requests.get(url, headers=HEADERS, timeout=120)
print("STATUS:", resp.status_code)

if resp.status_code != 200:
    print(resp.text[:500])
else:
    df = pd.read_csv(StringIO(resp.text))
    print("ROWS:", df.shape[0])
    print("COLUMNS:", df.columns.tolist())
    print("LATEST DATE:", df["Date received"].max())
    print(df["Company"].value_counts())
