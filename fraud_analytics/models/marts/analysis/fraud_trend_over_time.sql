SELECT
    d.year,
    c.company_name,
    COUNT(*) AS fraud_complaints
FROM {{ ref('fct_complaints') }} f
JOIN {{ ref('dim_date') }} d
    ON f.date_key = d.date_key
JOIN {{ ref('dim_company') }} c
    ON f.company_key = c.company_key
WHERE f.is_fraud_complaint = TRUE
GROUP BY
    d.year,
    c.company_name
ORDER BY
    d.year,
    c.company_name
