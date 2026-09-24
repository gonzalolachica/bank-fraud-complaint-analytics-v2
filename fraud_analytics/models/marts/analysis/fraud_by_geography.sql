SELECT
    g.state_code,
    g.state_name,
    g.region,
    COUNT(*) AS fraud_complaints,
    CAST(COUNT(*) AS DECIMAL(10,4))
        / SUM(COUNT(*)) OVER () * 100 AS pct_of_all_fraud
FROM {{ ref('fct_complaints') }} f
JOIN {{ ref('dim_geography') }} g
    ON f.geography_key = g.geography_key
WHERE f.is_fraud_complaint = TRUE
GROUP BY g.state_code, g.state_name, g.region
ORDER BY fraud_complaints DESC
