SELECT
    c.company_name,
    c.is_zelle_owner,
    COUNT(*) AS total_complaints,
    SUM(CASE WHEN f.is_fraud_complaint THEN 1 ELSE 0 END) AS fraud_complaints,
    CAST(
        SUM(CASE WHEN f.is_fraud_complaint THEN 1 ELSE 0 END) AS DECIMAL(10,4)
    ) / COUNT(*) * 100 AS fraud_share_pct
FROM {{ ref('fct_complaints') }} f
JOIN {{ ref('dim_company') }} c
    ON f.company_key = c.company_key
GROUP BY
    c.company_name,
    c.is_zelle_owner
ORDER BY
    fraud_share_pct DESC
