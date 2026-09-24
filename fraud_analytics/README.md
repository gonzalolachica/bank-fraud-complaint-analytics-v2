# Bank Fraud & Scam Complaint Analytics — dbt (v2)

dbt transformation layer for a benchmarking analysis of fraud/scam-related CFPB consumer complaints across **Truist**, **JPMorgan Chase**, and **American Express** (2020–2026).

v2 of [bank-fraud-complaint-analytics](https://github.com/gonzalolachica/bank-fraud-complaint-analytics), migrated from Microsoft Fabric to Supabase (Postgres) + dbt.

## Architecture

```
CFPB data → Google Colab (Python ingestion)
  → Supabase Postgres
       public    = raw source (stg_complaints_raw)
       analytics = everything dbt builds
  → dbt (this project)
  → Power BI Desktop
```

## Project layout

```
models/
├── staging/          _sources.yml, stg_complaints_clean
└── marts/
    ├── core/         dim_date, dim_geography, dim_issue, fct_complaints
    └── analysis/     fraud_yoy_trend, fraud_seasonality, ...
seeds/                dim_company, dim_product, fraud_issue_allowlist
```

## Fraud classification

A complaint is flagged `is_fraud_complaint` when its product group is *Money Transfer / Virtual Currency*, **or** its issue/sub-issue pair matches the manually reviewed allow-list in `seeds/fraud_issue_allowlist.csv` (11 rules). This replaced an earlier keyword approach that produced false positives.

## Running

```
dbt seed
dbt run
```
