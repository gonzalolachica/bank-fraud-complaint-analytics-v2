-- fraud_relief_rate: how often complaints close with relief, per bank,
-- fraud vs non-fraud side by side.
-- Denominator = CLOSED complaints only ("In progress" and NULL excluded:
-- they have no outcome yet and would unfairly count as "no relief").

WITH closed AS (
    SELECT
        company_key,
        is_fraud_complaint,
        company_response = 'Closed with monetary relief'                  AS got_monetary,
        company_response IN ('Closed with monetary relief',
                             'Closed with non-monetary relief')           AS got_any_relief
    FROM {{ ref('fct_complaints') }}
    WHERE company_response IS NOT NULL
      AND company_response <> 'In progress'
)

SELECT
    c.company_name,

    -- fraud complaints
    COUNT(*) FILTER (WHERE cl.is_fraud_complaint)                          AS fraud_closed,
    COUNT(*) FILTER (WHERE cl.is_fraud_complaint AND cl.got_monetary)      AS fraud_monetary_relief,
    COUNT(*) FILTER (WHERE cl.is_fraud_complaint AND cl.got_any_relief)    AS fraud_any_relief,
    ROUND(100.0 * COUNT(*) FILTER (WHERE cl.is_fraud_complaint AND cl.got_monetary)
          / NULLIF(COUNT(*) FILTER (WHERE cl.is_fraud_complaint), 0), 2)   AS fraud_monetary_relief_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE cl.is_fraud_complaint AND cl.got_any_relief)
          / NULLIF(COUNT(*) FILTER (WHERE cl.is_fraud_complaint), 0), 2)   AS fraud_any_relief_pct,

    -- non-fraud complaints (the baseline to compare against)
    COUNT(*) FILTER (WHERE NOT cl.is_fraud_complaint)                      AS nonfraud_closed,
    COUNT(*) FILTER (WHERE NOT cl.is_fraud_complaint AND cl.got_monetary)  AS nonfraud_monetary_relief,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NOT cl.is_fraud_complaint AND cl.got_monetary)
          / NULLIF(COUNT(*) FILTER (WHERE NOT cl.is_fraud_complaint), 0), 2) AS nonfraud_monetary_relief_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NOT cl.is_fraud_complaint AND cl.got_any_relief)
          / NULLIF(COUNT(*) FILTER (WHERE NOT cl.is_fraud_complaint), 0), 2) AS nonfraud_any_relief_pct

FROM closed cl
JOIN {{ ref('dim_company') }} c
  ON c.company_key = cl.company_key
GROUP BY c.company_name