-- Script 03 rule: pandas 'nan' / 'None' text artifacts must be converted to real NULLs.
-- Returns every row that still contains one (= test FAILS if any come back).
SELECT complaint_id
FROM {{ ref('stg_complaints_clean') }}
WHERE product                      = 'nan'
   OR sub_product                  = 'nan'
   OR issue                        = 'nan'
   OR sub_issue                    = 'nan'
   OR company                      = 'nan'
   OR company_response_to_consumer = 'nan'
   OR state                        = 'nan'
   OR zip_code                     = 'nan'
   OR submitted_via                = 'nan'
   OR timely_response              = 'nan'
   OR company_public_response IN ('nan', 'None')
   OR tags                    IN ('nan', 'None')
