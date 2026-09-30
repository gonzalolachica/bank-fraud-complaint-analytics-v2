-- dim_geography: one row per state/territory code found in the complaints data.
-- Names and regions come from the state_lookup seed (reference data kept out of SQL).
-- Codes missing from the seed fall back to name = code, region = 'Unknown'.

WITH distinct_states AS (
    SELECT DISTINCT COALESCE(state, 'UNK') AS state_code
    FROM {{ ref('stg_complaints_clean') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY d.state_code)  AS geography_key,
    d.state_code,
    COALESCE(s.state_name, d.state_code)       AS state_name,
    COALESCE(s.region, 'Unknown')              AS region
FROM distinct_states d
LEFT JOIN {{ ref('state_lookup') }} s
    ON s.state_code = d.state_code