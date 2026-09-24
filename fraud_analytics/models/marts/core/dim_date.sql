-- Calendar dimension: one row per day, 2020-01-01 to 2026-12-31.
-- Ported exactly from the Supabase version of script 06.
-- Known quirks (to fix later, deliberately):
--   1. TO_CHAR 'Month'/'Day' pad names with trailing spaces -> use 'FMMonth'/'FMDay'
--   2. Hard-coded end date -> 2027+ complaints would drop out of inner joins
-- day_of_week follows Postgres DOW: Sunday = 0 ... Saturday = 6

SELECT
    EXTRACT(YEAR FROM d)::int * 10000
      + EXTRACT(MONTH FROM d)::int * 100
      + EXTRACT(DAY FROM d)::int                                    AS date_key,
    d::date                                                         AS full_date,
    EXTRACT(YEAR FROM d)::int                                       AS year,
    EXTRACT(QUARTER FROM d)::int                                    AS quarter,
    EXTRACT(MONTH FROM d)::int                                      AS month,
    TO_CHAR(d, 'Month')                                             AS month_name,
    EXTRACT(DAY FROM d)::int                                        AS day,
    EXTRACT(DOW FROM d)::int                                        AS day_of_week,
    TO_CHAR(d, 'Day')                                               AS day_name,
    CASE WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend
FROM generate_series('2020-01-01'::date, '2026-12-31'::date, '1 day'::interval) AS d