-- End date = Dec 31 of the year of the latest complaint, so new years extend the table automatically.
-- COALESCE keeps a sensible end date if the source is ever empty.
WITH bounds AS (
    SELECT
        COALESCE(
            (DATE_TRUNC('year', MAX(date_received)) + INTERVAL '1 year - 1 day')::date,
            '2026-12-31'::date
        ) AS end_date
    FROM {{ ref('stg_complaints_clean') }}
)

SELECT
    EXTRACT(YEAR FROM d)::int * 10000
      + EXTRACT(MONTH FROM d)::int * 100
      + EXTRACT(DAY FROM d)::int                                    AS date_key,
    d::date                                                         AS full_date,
    EXTRACT(YEAR FROM d)::int                                       AS year,
    EXTRACT(QUARTER FROM d)::int                                    AS quarter,
    EXTRACT(MONTH FROM d)::int                                      AS month,
    TO_CHAR(d, 'FMMonth')                                             AS month_name,
    EXTRACT(DAY FROM d)::int                                        AS day,
    (EXTRACT(DOW FROM d)::int + 1)                                        AS day_of_week,
    TO_CHAR(d, 'FMDay')                                               AS day_name,
    CASE WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend
FROM bounds
CROSS JOIN generate_series('2020-01-01'::date, bounds.end_date, '1 day'::interval) AS d