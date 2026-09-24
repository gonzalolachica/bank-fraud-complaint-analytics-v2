-- Central fact table: one row per complaint, linked to every dimension,
-- with the two-part fraud flag. Ported from v1 script 10.
-- Named fct_complaints (not fact_complaints) so it never collides with
-- the migrated base table of the same name.

SELECT
    c.complaint_id,
    TO_CHAR(c.date_received, 'YYYYMMDD')::int AS date_key,
    co.company_key,
    p.product_key,
    i.issue_key,
    g.geography_key,
    CASE
        WHEN i.is_fraud_related
          OR p.product_group = 'Money Transfer / Virtual Currency'
        THEN TRUE
        ELSE FALSE
    END AS is_fraud_complaint,
    c.company_response_to_consumer AS company_response,
    c.timely_response,
    c.submitted_via
FROM {{ ref('stg_complaints_clean') }} c
JOIN {{ ref('dim_company') }}   co ON c.company = co.company_name
JOIN {{ ref('dim_product') }}   p  ON c.product = p.product_name
JOIN {{ ref('dim_issue') }}     i
    ON c.issue = i.issue
   AND COALESCE(c.sub_issue, '') = COALESCE(i.sub_issue, '')
JOIN {{ ref('dim_geography') }} g  ON COALESCE(c.state, 'UNK') = g.state_code