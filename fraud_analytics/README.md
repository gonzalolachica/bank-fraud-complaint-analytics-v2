# fraud_analytics (dbt project)

This folder is the dbt part of the Bank Fraud & Scam Complaint Analytics project: it cleans the raw CFPB complaints, builds the star schema the dashboard reads, and tests every step.

For the full story (findings, how the pipeline works, how fraud is defined, and how to run it), see the [main README](../README.md).

Quick start, once your environment variables and `~/.dbt/profiles.yml` are set up as described there:

```
dbt build
```
