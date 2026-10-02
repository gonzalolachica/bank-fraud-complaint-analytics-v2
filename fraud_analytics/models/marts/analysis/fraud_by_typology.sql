-- fraud_by_typology: fraud complaints per bank x fraud type.
-- Size (count, share of bank's fraud), growth (prior year vs current year annualized),
-- and relief rates (closed complaints only).
-- Fraud complaints with no matching allow-list rule are fraud only via the
-- Money Transfer product path -> labeled 'Money transfer - other (not clearly fraud)'.

WITH bounds AS (
    -- latest complaint date over ALL complaints (not fraud-only: avoids the day-258 bug)
    SELECT
        EXTRACT(YEAR FROM MAX(d.full_date))::int                          AS cur_year,
        MAX(d.full_date) - DATE_TRUNC('year', MAX(d.full_date))::date + 1 AS elapsed_days
    FROM {{ ref('fct_complaints') }} f
    JOIN {{ ref('dim_date') }} d
      ON d.date_key = f.date_key
),

fraud AS (
    SELECT
        f.company_key,
        f.date_key / 10000                                                AS yr,
        COALESCE(i.fraud_type, 'Money transfer - other (not clearly fraud)') AS fraud_type,
        f.company_response IS NOT NULL
          AND f.company_response <> 'In progress'                         AS is_closed,
        f.company_response = 'Closed with monetary relief'                AS got_monetary,
        f.company_response IN ('Closed with monetary relief',
                               'Closed with non-monetary relief')         AS got_any_relief
    FROM {{ ref('fct_complaints') }} f
    JOIN {{ ref('dim_issue') }} i
      ON i.issue_key = f.issue_key
    WHERE f.is_fraud_complaint
),

agg AS (
    SELECT
        c.company_name,
        fr.fraud_type,
        COUNT(*)                                                   AS fraud_complaints,
        COUNT(*) FILTER (WHERE fr.yr = b.cur_year - 1)             AS prior_year_complaints,
        COUNT(*) FILTER (WHERE fr.yr = b.cur_year)                 AS current_year_ytd,
        MAX(b.elapsed_days)                                        AS elapsed_days,
        COUNT(*) FILTER (WHERE fr.is_closed)                       AS closed,
        COUNT(*) FILTER (WHERE fr.is_closed AND fr.got_monetary)   AS monetary_relief,
        COUNT(*) FILTER (WHERE fr.is_closed AND fr.got_any_relief) AS any_relief
    FROM fraud fr
    JOIN {{ ref('dim_company') }} c
      ON c.company_key = fr.company_key
    CROSS JOIN bounds b
    GROUP BY c.company_name, fr.fraud_type
)

SELECT
    company_name,
    fraud_type,
    fraud_complaints,
    ROUND(100.0 * fraud_complaints
          / SUM(fraud_complaints) OVER (PARTITION BY company_name), 2)       AS pct_of_bank_fraud,
    prior_year_complaints,
    current_year_ytd,
    ROUND(current_year_ytd * 365.0 / elapsed_days)                           AS current_year_annualized,
    ROUND(100.0 * (current_year_ytd * 365.0 / elapsed_days - prior_year_complaints)
          / NULLIF(prior_year_complaints, 0), 1)                             AS yoy_annualized_pct,
    closed,
    monetary_relief,
    any_relief,
    ROUND(100.0 * monetary_relief / NULLIF(closed, 0), 2)                    AS monetary_relief_pct,
    ROUND(100.0 * any_relief      / NULLIF(closed, 0), 2)                    AS any_relief_pct
FROM agg