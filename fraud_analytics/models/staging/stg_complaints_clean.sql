-- Cleans the raw CFPB load: typed dates/IDs, trimmed text,
-- and 'nan'/'None' text artifacts converted to real NULLs.
-- Ported from the Supabase version of script 03.
-- Note: try_cast_bigint / try_cast_date are custom functions that live in
-- Supabase's public schema (not built into Postgres).

SELECT
    public.try_cast_bigint(complaint_id::text)                   AS complaint_id,
    public.try_cast_date(date_received)                          AS date_received,
    public.try_cast_date(date_sent_to_company)                   AS date_sent_to_company,
    NULLIF(TRIM(product), 'nan')                                 AS product,
    NULLIF(TRIM(sub_product), 'nan')                             AS sub_product,
    NULLIF(TRIM(issue), 'nan')                                   AS issue,
    NULLIF(TRIM(sub_issue), 'nan')                               AS sub_issue,
    NULLIF(TRIM(company), 'nan')                                 AS company,
    NULLIF(NULLIF(TRIM(company_public_response), 'nan'), 'None') AS company_public_response,
    NULLIF(TRIM(company_response_to_consumer), 'nan')            AS company_response_to_consumer,
    NULLIF(TRIM(state), 'nan')                                   AS state,
    NULLIF(TRIM(zip_code), 'nan')                                AS zip_code,
    NULLIF(NULLIF(TRIM(tags), 'nan'), 'None')                    AS tags,
    NULLIF(TRIM(submitted_via), 'nan')                           AS submitted_via,
    NULLIF(TRIM(timely_response), 'nan')                         AS timely_response
FROM {{ source('raw', 'stg_complaints_raw') }}