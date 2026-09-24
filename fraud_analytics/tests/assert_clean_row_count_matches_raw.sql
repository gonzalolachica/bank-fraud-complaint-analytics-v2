-- Script 03 rule: cleaning must not add or drop rows.
-- Returns a row (= test FAILS) only if raw and clean row counts differ.
WITH counts AS (
    SELECT
        (SELECT COUNT(*) FROM {{ source('raw', 'stg_complaints_raw') }}) AS raw_rows,
        (SELECT COUNT(*) FROM {{ ref('stg_complaints_clean') }})         AS clean_rows
)
SELECT raw_rows, clean_rows
FROM counts
WHERE raw_rows <> clean_rows
