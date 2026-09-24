-- The fact table uses INNER JOINs to every dimension. If any complaint fails to
-- match (e.g. a new company or product name not in the seeds), it silently drops.
-- Returns a row (= test FAILS) only if the fact has fewer/more rows than clean.
WITH counts AS (
    SELECT
        (SELECT COUNT(*) FROM {{ ref('stg_complaints_clean') }}) AS clean_rows,
        (SELECT COUNT(*) FROM {{ ref('fct_complaints') }})       AS fct_rows
)
SELECT clean_rows, fct_rows
FROM counts
WHERE clean_rows <> fct_rows
