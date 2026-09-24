-- Fraud complaints per company per year, with the current partial year
-- annualized and year-over-year % change.
-- Ported from v1 script 15. The elapsed-day count is computed from the data
-- (not hard-coded 238/260), so it stays correct after every refresh.
-- Reads from dbt models via ref() (fct_complaints, dim_date, dim_company).

WITH fraud_facts AS (
    SELECT
        d.year,
        d.full_date,
        c.company_name
    FROM {{ ref('fct_complaints') }} f
    JOIN {{ ref('dim_date') }} d
        ON f.date_key = d.date_key
    JOIN {{ ref('dim_company') }} c
        ON f.company_key = c.company_key
    WHERE f.is_fraud_complaint
),

latest AS (
    SELECT
        EXTRACT(YEAR FROM MAX(d.full_date))::int AS latest_year,
        EXTRACT(DOY  FROM MAX(d.full_date))::int AS days_elapsed
    FROM {{ ref('fct_complaints') }} f
    JOIN {{ ref('dim_date') }} d
        ON f.date_key = d.date_key
),

yearly_counts AS (
    SELECT
        year,
        company_name,
        COUNT(*) AS raw_count
    FROM fraud_facts
    GROUP BY year, company_name
),

annualized AS (
    SELECT
        y.year,
        y.company_name,
        y.raw_count,
        CASE
            WHEN y.year = l.latest_year
                THEN y.raw_count::numeric / l.days_elapsed * 365
            ELSE y.raw_count::numeric
        END AS adjusted_count,
        (y.year = l.latest_year) AS is_partial_year
    FROM yearly_counts y
    CROSS JOIN latest l
)

SELECT
    year,
    company_name,
    raw_count,
    ROUND(adjusted_count, 0) AS annualized_count,
    is_partial_year,
    ROUND(
        (adjusted_count - LAG(adjusted_count) OVER w)
        / NULLIF(LAG(adjusted_count) OVER w, 0)
        * 100
    , 1) AS yoy_pct_change
FROM annualized
WINDOW w AS (PARTITION BY company_name ORDER BY year)
ORDER BY company_name, year