-- Every fraud allow-list rule must match at least one complaint.
-- If CFPB renames or retires an issue/sub-issue value, its rule silently
-- matches nothing and fraud complaints disappear without an error.
-- This test turns that silent drop into a failed build.
-- Returns the rules that match zero complaints (any row = test fails).

SELECT a.match_on, a.value
FROM {{ ref('fraud_issue_allowlist') }} a
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ ref('stg_complaints_clean') }} c
    WHERE (a.match_on = 'sub_issue' AND c.sub_issue = a.value)
       OR (a.match_on = 'issue' AND c.sub_issue IS NULL AND c.issue = a.value)
)