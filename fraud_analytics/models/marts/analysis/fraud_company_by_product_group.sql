-- Company x product group crosstab of fraud complaints (long format).
-- New in v2: Fabric script 17 had no Supabase version, so this is written fresh.
-- pct_of_company_fraud = share of each company's fraud complaints in that product group
-- (sums to 100 within each company).
SELECT
    c.company_name,
    p.product_group,
    COUNT(*) AS fraud_complaints,
    CAST(COUNT(*) AS DECIMAL(10,4))
        / SUM(COUNT(*)) OVER (PARTITION BY c.company_name) * 100 AS pct_of_company_fraud
FROM {{ ref('fct_complaints') }} f
JOIN {{ ref('dim_company') }} c
    ON f.company_key = c.company_key
JOIN {{ ref('dim_product') }} p
    ON f.product_key = p.product_key
WHERE f.is_fraud_complaint = TRUE
GROUP BY
    c.company_name,
    p.product_group
ORDER BY
    c.company_name,
    fraud_complaints DESC
