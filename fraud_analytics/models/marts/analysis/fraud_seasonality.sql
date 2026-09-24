SELECT
    d.month,
    d.month_name,
    COUNT(*) AS fraud_complaints,
    CAST(COUNT(*) AS DECIMAL(10,4))
        / SUM(COUNT(*)) OVER () * 100 AS pct_of_all_fraud
FROM {{ ref('fct_complaints') }} f
JOIN {{ ref('dim_date') }} d
    ON f.date_key = d.date_key
WHERE f.is_fraud_complaint = TRUE
  AND d.year BETWEEN 2020 AND 2025
GROUP BY d.month, d.month_name
ORDER BY d.month
