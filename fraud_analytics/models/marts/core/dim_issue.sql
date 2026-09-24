-- Every distinct issue/sub-issue pair in the data, flagged fraud-related
-- if it matches the manually reviewed allow-list (seeds/fraud_issue_allowlist.csv).
-- Ported from Supabase script 07 (Fabric script 08).-- Rules:
--   match_on = 'sub_issue' -> fraud if sub_issue matches (any issue)
--   match_on = 'issue'     -> fraud if issue matches AND sub_issue is NULL

WITH distinct_issues AS (
    SELECT DISTINCT issue, sub_issue
    FROM {{ ref('stg_complaints_clean') }}
),

numbered AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY issue, sub_issue) AS issue_key,
        issue,
        sub_issue
    FROM distinct_issues
)

SELECT
    n.issue_key,
    n.issue,
    n.sub_issue,
    EXISTS (
        SELECT 1
        FROM {{ ref('fraud_issue_allowlist') }} a
        WHERE (a.match_on = 'sub_issue' AND a.value = n.sub_issue)
           OR (a.match_on = 'issue' AND n.sub_issue IS NULL AND a.value = n.issue)
    ) AS is_fraud_related
FROM numbered n