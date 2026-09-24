SELECT
    p.product_group,
    COUNT(*) AS fraud_complaints,
    CAST(COUNT(*) AS DECIMAL(10,4))
        / SUM(COUNT(*)) OVER () * 100 AS pct_of_all_fraud
FROM {{ ref('fct_complaints') }} f
JOIN {{ ref('dim_product') }} p
    ON f.product_key = p.product_key
WHERE f.is_fraud_complaint = TRUE
GROUP BY p.product_group
ORDER BY fraud_complaints DESC
