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
    c.submitted_via,
    
    -- Fraud type: allow-list label when one matched; complaints flagged only
    -- by the Money Transfer product path get the transparent catch-all label.
    -- Non-fraud complaints have no fraud type (NULL).
    CASE
        WHEN i.is_fraud_related
          OR p.product_group = 'Money Transfer / Virtual Currency'
        THEN COALESCE(i.fraud_type, 'Money transfer - other (not clearly fraud)')
    END AS fraud_type,

    -- Relief flags: the business rules for "closed" and "relief" live here, once.
    -- DAX measures count these flags and never re-type the response strings.
    COALESCE(c.company_response_to_consumer NOT IN ('In progress'), FALSE)          AS is_closed,
    COALESCE(c.company_response_to_consumer = 'Closed with monetary relief', FALSE) AS got_monetary_relief,
    COALESCE(c.company_response_to_consumer IN ('Closed with monetary relief',
                                                'Closed with non-monetary relief'), FALSE) AS got_any_relief

FROM {{ ref('stg_complaints_clean') }} c
JOIN {{ ref('dim_company') }}   co ON c.company = co.company_name
JOIN {{ ref('dim_product') }}   p  ON c.product = p.product_name
JOIN {{ ref('dim_issue') }}     i
    ON c.issue = i.issue
   AND COALESCE(c.sub_issue, '') = COALESCE(i.sub_issue, '')
JOIN {{ ref('dim_geography') }} g  ON COALESCE(c.state, 'UNK') = g.state_code