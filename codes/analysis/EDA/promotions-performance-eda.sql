-- -------------------------------------------------------------------
# # # # # # # # # # # # JL DEPT PROMOTIONS # # # # # # # # # # # # # # 
-- -------------------------------------------------------------------

-- Promotion trend by employees based on their working experience
SELECT
	yrs_since_last_hire AS wrking_yrs,
    COUNT(CASE WHEN fy20_07_01_dept = "Finance" THEN emp_id END) AS fi_promo,
    COUNT(CASE WHEN fy20_07_01_dept = "HR" THEN emp_id END) AS hr_promo,
    COUNT(CASE WHEN fy20_07_01_dept = "Internal Services" THEN emp_id END) AS is_promo,
    COUNT(CASE WHEN fy20_07_01_dept = "Operations" THEN emp_id END) AS ops_promo,
    COUNT(CASE WHEN fy20_07_01_dept = "Sales & Marketing" THEN emp_id END) AS sam_promo,
    COUNT(CASE WHEN fy20_07_01_dept = "Strategy" THEN emp_id END) AS strat_promo
FROM dim_emp
WHERE fy20_promo = "Yes"
GROUP BY 1
ORDER BY 1 	

-- Compare the promotions given in fy20 & fy21
-- STEP 1: Get total employees for start of FY20 & FY21 + number of emps promoted at the start of FY20 & FY21
-- CREATE TEMPORARY TABLE tot_emp_and_tot_promo_fy20_fy21
SELECT 
	COUNT(emp_id) AS fy20_total_emp,
    COUNT(CASE WHEN fy20_promo = "Yes" THEN emp_id END) AS fy20_promo_num,
    (SELECT COUNT(emp_id) FROM dim_emp WHERE leaver_fy != "FY20") AS fy21_total_emp,
    COUNT(CASE WHEN fy21_promo = "Yes" THEN emp_id END) AS fy21_promo_num
FROM dim_emp

-- STEP 2a: Split out fy20 data from table
-- CREATE TEMPORARY TABLE fy20_total_emp_and_num_promoted
SELECT 
	fy20_total_emp AS tot_emp,
    fy20_promo_num AS num_promoted
FROM tot_emp_and_tot_promo_fy20_fy21

-- STEP 2b: Split out fy21 data from table
-- CREATE TEMPORARY TABLE fy21_total_emp_and_num_promoted
SELECT 
	fy21_total_emp AS tot_emp,
    fy21_promo_num AS num_promoted
FROM tot_emp_and_tot_promo_fy20_fy21

-- STEP 3: Union two tabls back together (a.k.a unpivot the table)
-- CREATE TEMPORARY TABLE tot_emp_and_promo_unpivot
SELECT
	*
FROM fy20_total_emp_and_num_promoted
UNION
SELECT
	*
FROM fy21_total_emp_and_num_promoted

-- STEP 4: Create new year column for indication
-- CREATE TEMPORARY TABLE tot_emp_and_promoted_by_yr
SELECT 
	CASE 
		WHEN tot_emp = 500 THEN 2020
        ELSE 2021
	END AS yr,
	tot_emp, num_promoted
FROM tot_emp_and_promo_unpivot

-- STEP 5: Compare promotion percentage
SELECT
	*, 
    CONCAT(ROUND((num_promoted / tot_emp)*100,2), "%") AS pct_promoted
FROM tot_emp_and_promoted_by_yr

																						
                                            
-- Find where most of the promotions are happening in FY20 & FY21
-- STEP 1: Get promotions by dept for FY20
-- CREATE TEMPORARY TABLE fy20_promotions_by_dept
SELECT 
	fy20_last_dept AS dept,
	COUNT(emp_id) AS fy20_total_promo
FROM dim_emp
WHERE fy20_promo = "Yes" 
GROUP BY 1 									

-- STEP 2: Get promotions by dept for FY21
-- CREATE TEMPORARY TABLE fy21_promotions_by_dept
SELECT 
	fy20_last_dept AS dept,
	COUNT(emp_id) AS fy21_total_promo
FROM dim_emp
WHERE fy21_promo = "Yes" 
GROUP BY 1 

-- STEP 3: Join STEP 1 & STEP 2 tables & compare the pct increase for the departments
SELECT 
	fy20.dept,
    fy20_total_promo, fy21_total_promo,
    CONCAT(ROUND(((fy21_total_promo - fy20_total_promo) / fy20_total_promo)*100,2),"%") AS pct_increase
FROM fy20_promotions_by_dept fy20
	LEFT JOIN fy21_promotions_by_dept fy21
		ON fy21.dept = fy20.dept
																

-- Temp tables to find promotional trend by yr, dept & gender (3 - SENIOR MANAGER, INTERNAL SERVICES)
-- STEP 1a: Get total employees by gender (FY20, 3 - SENIOR MANAGER, INTERNAL SERVICES)
-- CREATE TEMPORARY TABLE fy20_is_sn_mngr_tot_emp_gender
SELECT
	gender,
	COUNT(emp_id) AS total_emp
FROM dim_emp
WHERE fy20_jl_aft_promo = "3 - Senior Manager"
AND fy20_last_dept = "Internal Services"
GROUP BY 1
ORDER BY 1 DESC

-- STEP 1b: Get total employees by gender  	(FY21, 3 - SENIOR MANAGER, INTERNAL SERVICES)
-- CREATE TEMPORARY TABLE fy21_is_sn_mngr_tot_emp_gender
SELECT
	gender,
	COUNT(emp_id) AS total_emp
FROM dim_emp
WHERE fy21_jl_aft_promo = "3 - Senior Manager"
AND fy20_last_dept = "Internal Services"
GROUP BY 1
ORDER BY 1 DESC

-- STEP 2a: Create a CTE table to get total emp promoted & join to STEP 1's table 			-- (FY20, 3 - SENIOR MANAGER, INTERNAL SERVICES)
-- CREATE TEMPORARY TABLE fy20_is_sn_mngr_tot_emp_promo_gender
WITH t2 AS (
  SELECT
    gender,
    COUNT(emp_id) AS total_promo
  FROM dim_emp
  WHERE fy20_jl_aft_promo = "3 - Senior Manager"
  AND fy20_last_dept = "Internal Services"
  AND fy20_promo = "Yes"
  GROUP BY 1
  ORDER BY 1 DESC
)

SELECT 
	t1.gender,  
    t1.total_emp, t2.total_promo
FROM fy20_is_sn_mngr_tot_emp_gender t1
LEFT JOIN t2
	ON t2.gender = t1.gender

-- STEP 2b: Create a CTE table to get total emp promoted & join to STEP 1's table 			-- (FY21, 3 - SENIOR MANAGER, INTERNAL SERVICES)
-- CREATE TEMPORARY TABLE fy21_is_sn_mngr_tot_emp_promo_gender
WITH t2 AS (
    SELECT
      gender,
      COUNT(emp_id) AS total_promo
    FROM dim_emp
    WHERE fy21_jl_aft_promo = "3 - Senior Manager"
    AND fy20_last_dept = "Internal Services"
    AND fy21_promo = "Yes"
    GROUP BY 1
    ORDER BY 1 DESC
)

SELECT 
	t1.gender,  
    t1.total_emp, t2.total_promo
FROM fy21_is_sn_mngr_tot_emp_gender t1
LEFT JOIN t2
	ON t2.gender = t1.gender

-- STEP 3a: Add a year column at the start to join back to 2021 promo table for comparison later 		-- (FY20, 3 - SENIOR MANAGER, INTERNAL SERVICES)
-- Also, change nulls to 0
-- CREATE TEMPORARY TABLE fy20_is_sn_mngr_tot_emp_and_promo_by_gender
SELECT 
	CASE WHEN gender = "M" THEN 2020 ELSE 2020 END AS yr,
	(SELECT COUNT(emp_id) FROM dim_emp WHERE fy20_jl_aft_promo = "3 - Senior Manager" AND fy20_last_dept = "Internal Services") AS tot_emp,
    CASE WHEN gender = "M" THEN total_emp ELSE 0 END AS fy20_males,
	CASE WHEN gender = "F" THEN total_emp ELSE 0 END AS fy20_females,
    CASE WHEN gender = "M" THEN total_promo ELSE 0 END AS fy20_m_promo,
	CASE WHEN gender = "F" AND total_promo IS NULL THEN 0 
		 WHEN gender = "F" THEN total_promo 
         ELSE 0 
	END AS fy20_f_promo
FROM fy20_is_sn_mngr_tot_emp_promo_gender

-- STEP 3b: Add a year column at the start to join back to 2020 promo table for comparison later 		-- (FY21, 3 - SENIOR MANAGER, INTERNAL SERVICES)
-- Also, change nulls to 0
-- CREATE TEMPORARY TABLE fy21_is_sn_mngr_tot_emp_and_promo_by_gender
SELECT 
	CASE WHEN gender = "M" THEN 2021 ELSE 2021 END AS yr,
	(SELECT COUNT(emp_id) FROM dim_emp WHERE fy21_jl_aft_promo = "3 - Senior Manager" AND fy20_last_dept = "Internal Services") AS tot_emp,
    CASE WHEN gender = "M" THEN total_emp ELSE 0 END AS fy21_males,
	CASE WHEN gender = "F" THEN total_emp ELSE 0 END AS fy21_females,
    CASE WHEN gender = "M" THEN total_promo ELSE 0 END AS fy21_m_promo,
	CASE WHEN gender = "F" AND total_promo IS NULL THEN 0 
		 WHEN gender = "F" THEN total_promo 
         ELSE 0 
	END AS fy21_f_promo
FROM fy21_is_sn_mngr_tot_emp_promo_gender

-- STEP 4: Join STEP 3a & 3b's table together to compare
-- Also, combine two rows into 1 single row through SUM( ) by getting rid of 0's
-- CREATE TEMPORARY TABLE merged_fy20_fy21_is_sn_mngr_gender_tot_emp_and_promo
SELECT 
	yr, tot_emp,
	SUM(fy20_males) AS males,
    SUM(fy20_females) AS females,
    SUM(fy20_m_promo + fy20_f_promo) AS tot_promo,
    SUM(fy20_m_promo) AS m_promo,
    SUM(fy20_f_promo) AS f_promo
FROM fy20_is_sn_mngr_tot_emp_and_promo_by_gender
UNION
SELECT
	yr, tot_emp,
    SUM(fy21_males) AS males,
    SUM(fy21_females) AS females,
    SUM(fy21_m_promo + fy21_f_promo) AS tot_promo,
    SUM(fy21_m_promo) AS m_promo,
    SUM(fy21_f_promo) AS f_promo
FROM fy21_is_sn_mngr_tot_emp_and_promo_by_gender								

-- Temp tables to find promotional trend by yr, dept & gender (3 - SENIOR MANAGER, SALES & MARKETING)
-- STEP 1a: Get total employees by gender (FY20, 3 - SENIOR MANAGER, SALES & MARKETING)
-- CREATE TEMPORARY TABLE fy20_sam_sn_mngr_tot_emp_gender
SELECT
	gender,
	COUNT(emp_id) AS total_emp
FROM dim_emp
WHERE fy20_jl_aft_promo = "3 - Senior Manager"
AND fy20_last_dept = "Sales & Marketing"
GROUP BY 1
ORDER BY 1 DESC

-- STEP 1b: Get total employees by gender  	(FY21, 3 - SENIOR MANAGER, SALES & MARKETING)
-- CREATE TEMPORARY TABLE fy21_sam_sn_mngr_tot_emp_gender
SELECT
	gender,
	COUNT(emp_id) AS total_emp
FROM dim_emp
WHERE fy21_jl_aft_promo = "3 - Senior Manager"
AND fy20_last_dept = "Sales & Marketing"
GROUP BY 1
ORDER BY 1 DESC

-- STEP 2a: Create a CTE table to get total emp promoted & join to STEP 1's table 			-- (FY20, 3 - SENIOR MANAGER, SALES & MARKETING)
-- CREATE TEMPORARY TABLE fy20_sam_sn_mngr_tot_emp_promo_gender
WITH t2 AS (
  SELECT
    gender,
    COUNT(emp_id) AS total_promo
  FROM dim_emp
  WHERE fy20_jl_aft_promo = "3 - Senior Manager"
  AND fy20_last_dept = "Sales & Marketing"
  AND fy20_promo = "Yes"
  GROUP BY 1
  ORDER BY 1 DESC
					)

SELECT 
	t1.gender,  
    t1.total_emp, t2.total_promo
FROM fy20_sam_sn_mngr_tot_emp_gender t1
LEFT JOIN t2
	ON t2.gender = t1.gender

-- STEP 2b: Create a CTE table to get total emp promoted & join to STEP 1's table 			-- (FY21, 3 - SENIOR MANAGER, SALES & MARKETING)
-- CREATE TEMPORARY TABLE fy21_sam_sn_mngr_tot_emp_promo_gender
WITH t2 AS (
  SELECT
    gender,
    COUNT(emp_id) AS total_promo
  FROM dim_emp
  WHERE fy21_jl_aft_promo = "3 - Senior Manager"
  AND fy20_last_dept = "Sales & Marketing"
  AND fy21_promo = "Yes"
  GROUP BY 1
  ORDER BY 1 DESC
)

SELECT 
	t1.gender,  
    t1.total_emp, t2.total_promo
FROM fy21_sam_sn_mngr_tot_emp_gender t1
LEFT JOIN t2
	ON t2.gender = t1.gender

-- STEP 3a: Add a year column at the start to join back to 2021 promo table for comparison later 		-- (FY20, 3 - SENIOR MANAGER, SALES & MARKETING)
-- Also, change nulls to 0
-- CREATE TEMPORARY TABLE fy20_sam_sn_mngr_tot_emp_and_promo_by_gender
SELECT 
	CASE WHEN gender = "M" THEN 2020 ELSE 2020 END AS yr,
	(SELECT COUNT(emp_id) FROM dim_emp WHERE fy20_jl_aft_promo = "3 - Senior Manager" AND fy20_last_dept = "Sales & Marketing") AS tot_emp,
    CASE WHEN gender = "M" THEN total_emp ELSE 0 END AS fy20_males,
	CASE WHEN gender = "F" THEN total_emp ELSE 0 END AS fy20_females,
    CASE WHEN gender = "M" THEN total_promo ELSE 0 END AS fy20_m_promo,
	CASE WHEN gender = "F" AND total_promo IS NULL THEN 0 
		 WHEN gender = "F" THEN total_promo 
         ELSE 0 
	END AS fy20_f_promo
FROM fy20_sam_sn_mngr_tot_emp_promo_gender

-- STEP 3b: Add a year column at the start to join back to 2020 promo table for comparison later 		-- (FY21, 3 - SENIOR MANAGER, SALES & MARKETING)
-- Also, change nulls to 0
-- CREATE TEMPORARY TABLE fy21_sam_sn_mngr_tot_emp_and_promo_by_gender
SELECT 
	CASE WHEN gender = "M" THEN 2021 ELSE 2021 END AS yr,
	(SELECT COUNT(emp_id) FROM dim_emp WHERE fy21_jl_aft_promo = "3 - Senior Manager" AND fy20_last_dept = "Sales & Marketing") AS tot_emp,
    CASE WHEN gender = "M" THEN total_emp ELSE 0 END AS fy21_males,
	CASE WHEN gender = "F" THEN total_emp ELSE 0 END AS fy21_females,
    CASE WHEN gender = "M" THEN total_promo ELSE 0 END AS fy21_m_promo,
	CASE WHEN gender = "F" AND total_promo IS NULL THEN 0 
		 WHEN gender = "F" THEN total_promo 
         ELSE 0 
	END AS fy21_f_promo
FROM fy21_sam_sn_mngr_tot_emp_promo_gender

-- STEP 4: Join STEP 3a & 3b's table together to compare
-- Also, combine two rows into 1 single row through SUM( ) by getting rid of 0's
-- CREATE TEMPORARY TABLE merged_fy20_fy21_sam_sn_mngr_gender_tot_emp_and_promo
SELECT 
	yr, tot_emp,
	SUM(fy20_males) AS males,
    SUM(fy20_females) AS females,
    SUM(fy20_m_promo + fy20_f_promo) AS tot_promo,
    SUM(fy20_m_promo) AS m_promo,
    SUM(fy20_f_promo) AS f_promo
FROM fy20_sam_sn_mngr_tot_emp_and_promo_by_gender
UNION
SELECT
	yr, tot_emp,
    SUM(fy21_males) AS males,
    SUM(fy21_females) AS females,
    SUM(fy21_m_promo + fy21_f_promo) AS tot_promo,
    SUM(fy21_m_promo) AS m_promo,
    SUM(fy21_f_promo) AS f_promo
FROM fy21_sam_sn_mngr_tot_emp_and_promo_by_gender 									

-- Find promotional trend by yr, dept & gender (4 - MANAGER, SALES & MARKETING)
-- STEP 1a: Get total employees by gender (FY20, 4 - MANAGER, SALES & MARKETING)
-- CREATE TEMPORARY TABLE fy20_sam_mngr_tot_emp_gender
SELECT
	gender,
	COUNT(emp_id) AS total_emp
FROM dim_emp
WHERE fy20_jl_aft_promo = "4 - Manager"
AND fy20_last_dept = "Sales & Marketing"
GROUP BY 1
ORDER BY 1 DESC

-- STEP 1b: Get total employees by gender  	(FY21, 4 - MANAGER, SALES & MARKETING)
-- CREATE TEMPORARY TABLE fy21_sam_mngr_tot_emp_gender
SELECT
	gender,
	COUNT(emp_id) AS total_emp
FROM dim_emp
WHERE fy21_jl_aft_promo = "4 - Manager"
AND fy20_last_dept = "Sales & Marketing"
GROUP BY 1
ORDER BY 1 DESC

-- STEP 2a: Create a CTE table to get total emp promoted & join to STEP 1's table 			-- (FY20, 4 - MANAGER, SALES & MARKETING)
-- CREATE TEMPORARY TABLE fy20_sam_mngr_tot_emp_promo_gender
WITH t2 AS (
  SELECT
    gender,
    COUNT(emp_id) AS total_promo
  FROM dim_emp
  WHERE fy20_jl_aft_promo = "4 - Manager"
  AND fy20_last_dept = "Sales & Marketing"
  AND fy20_promo = "Yes"
  GROUP BY 1
  ORDER BY 1 DESC
)

SELECT 
	t1.gender,  
    t1.total_emp, t2.total_promo
FROM fy20_sam_mngr_tot_emp_gender t1
LEFT JOIN t2
	ON t2.gender = t1.gender

-- STEP 2b: Create a CTE table to get total emp promoted & join to STEP 1's table 			-- (FY21, 4 - MANAGER, SALES & MARKETING)
-- CREATE TEMPORARY TABLE fy21_sam_mngr_tot_emp_promo_gender
WITH t2 AS (
  SELECT
    gender,
    COUNT(emp_id) AS total_promo
  FROM dim_emp
  WHERE fy21_jl_aft_promo = "4 - Manager"
  AND fy20_last_dept = "Sales & Marketing"
  AND fy21_promo = "Yes"
  GROUP BY 1
  ORDER BY 1 DESC
)

SELECT 
	t1.gender,  
    t1.total_emp, t2.total_promo
FROM fy21_sam_mngr_tot_emp_gender t1
LEFT JOIN t2
	ON t2.gender = t1.gender

-- STEP 3a: Add a year column at the start to join back to 2021 promo table for comparison later 		-- (FY20, 4 - MANAGER, SALES & MARKETING)
-- Also, change nulls to 0
-- CREATE TEMPORARY TABLE fy20_sam_mngr_tot_emp_and_promo_by_gender
SELECT 
	CASE WHEN gender = "M" THEN 2020 ELSE 2020 END AS yr,
	(SELECT COUNT(emp_id) FROM dim_emp WHERE fy20_jl_aft_promo = "4 - Manager" AND fy20_last_dept = "Sales & Marketing") AS tot_emp,
    CASE WHEN gender = "M" THEN total_emp ELSE 0 END AS fy20_males,
	CASE WHEN gender = "F" THEN total_emp ELSE 0 END AS fy20_females,
    CASE WHEN gender = "M" THEN total_promo ELSE 0 END AS fy20_m_promo,
	CASE WHEN gender = "F" AND total_promo IS NULL THEN 0 
		 WHEN gender = "F" THEN total_promo 
         ELSE 0 
	END AS fy20_f_promo
FROM fy20_sam_mngr_tot_emp_promo_gender

-- STEP 3b: Add a year column at the start to join back to 2020 promo table for comparison later 		-- (FY21, 4 - MANAGER, SALES & MARKETING)
-- Also, change nulls to 0
-- CREATE TEMPORARY TABLE fy21_sam_mngr_tot_emp_and_promo_by_gender
SELECT 
	CASE WHEN gender = "M" THEN 2021 ELSE 2021 END AS yr,
	(SELECT COUNT(emp_id) FROM dim_emp WHERE fy21_jl_aft_promo = "4 - Manager" AND fy20_last_dept = "Sales & Marketing") AS tot_emp,
    CASE WHEN gender = "M" THEN total_emp ELSE 0 END AS fy21_males,
	CASE WHEN gender = "F" THEN total_emp ELSE 0 END AS fy21_females,
    CASE WHEN gender = "M" THEN total_promo ELSE 0 END AS fy21_m_promo,
	CASE WHEN gender = "F" AND total_promo IS NULL THEN 0 
		 WHEN gender = "F" THEN total_promo 
         ELSE 0 
	END AS fy21_f_promo
FROM fy21_sam_mngr_tot_emp_promo_gender

-- STEP 4: Join STEP 3a & 3b's table together to compare
-- Also, combine two rows into 1 single row through SUM( ) by getting rid of 0's
-- CREATE TEMPORARY TABLE merged_fy20_fy21_sam_mngr_gender_tot_emp_and_promo
SELECT 
	yr, tot_emp,
	SUM(fy20_males) AS males,
    SUM(fy20_females) AS females,
    SUM(fy20_m_promo + fy20_f_promo) AS tot_promo,
    SUM(fy20_m_promo) AS m_promo,
    SUM(fy20_f_promo) AS f_promo
FROM fy20_sam_mngr_tot_emp_and_promo_by_gender
UNION
SELECT
	yr, tot_emp,
    SUM(fy21_males) AS males,
    SUM(fy21_females) AS females,
    SUM(fy21_m_promo + fy21_f_promo) AS tot_promo,
    SUM(fy21_m_promo) AS m_promo,
    SUM(fy21_f_promo) AS f_promo
FROM fy21_sam_mngr_tot_emp_and_promo_by_gender 										

-- Get total results of the 3 departments
-- STEP 1: Create column to indicate which segment is which
-- CREATE TEMPORARY TABLE merged_fy20_fy21_promo_by_yr_gender_3sgmts
SELECT
	CASE WHEN yr IS NOT NULL THEN "3- Sn. Mngr, Int. Services" END AS jl_dept,
	is_sn_mngr.* FROM merged_fy20_fy21_is_sn_mngr_gender_tot_emp_and_promo	is_sn_mngr	-- (3 - SENIOR MANAGER, INTERNAL SERVICES)
UNION
SELECT 
	CASE WHEN yr IS NOT NULL THEN "3 - Sn. Mngr, Sales & Mrkting" END AS jl_dept,
    sam_sn_mngr.* FROM merged_fy20_fy21_sam_sn_mngr_gender_tot_emp_and_promo sam_sn_mngr 		-- (3 - SENIOR MANAGER, SALES & MARKETING)
UNION
SELECT 
	CASE WHEN yr IS NOT NULL THEN "4 - Mngr, Sales & Mrkting" END AS jl_dept,
	sam_mngr.* FROM merged_fy20_fy21_sam_mngr_gender_tot_emp_and_promo sam_mngr		-- (4 - MANAGER, SALES & MARKETING)

-- STEP 2: Add up the results
SELECT
	yr, 
    SUM(tot_emp) AS tot_emp, SUM(males) AS males, SUM(females) AS females,
    SUM(tot_promo) AS tot_promo, SUM(m_promo) AS m_promo, SUM(f_promo) AS f_promo
FROM merged_fy20_fy21_promo_by_yr_gender_3sgmts
GROUP BY 1
									

-- Find why S&M peeps were promoted so much

-- Let's look at how promotions usually occur by looking for a pattern
-- STEP 1a: Get performance data & job level of all employees promoted at the start of FY20
-- CREATE TEMPORARY TABLE fy20_all_promoted_emp_perf_data
SELECT
	emp_id, gender, 
    fy20_jl_bf_promo AS fy19_jl,
    fy19_perf_rating, fy20_jl_aft_promo AS fy20_jl,
    fy20_perf_rating, fy21_jl_aft_promo AS fy21_jl
FROM dim_emp
WHERE fy20_promo = "Yes"

-- STEP 1b: Get performance data & job level of all employees promoted at the end of FY20
-- CREATE TEMPORARY TABLE fy21_all_promoted_emp_perf_data
SELECT
	emp_id, gender, 
    fy20_jl_bf_promo AS fy19_jl,
    fy19_perf_rating, fy20_jl_aft_promo AS fy20_jl,
    fy20_perf_rating, fy21_jl_aft_promo AS fy21_jl
FROM dim_emp
WHERE fy21_promo = "Yes"

-- STEP 2a: Find the total count of each performance rating for FY20
SELECT
	fy19_perf_rating,
    COUNT(fy19_perf_rating) AS total_count
FROM fy20_all_promoted_emp_perf_data
GROUP BY 1

-- STEP 2b: Find the total count of each performance rating for FY21
SELECT
	fy20_perf_rating,
    COUNT(fy20_perf_rating) AS total_count
FROM fy21_all_promoted_emp_perf_data
GROUP BY 1
ORDER BY 1

-- STEP 3a: Check if promotion = higher job level increase? (FY20 Only)
-- CREATE TEMPORARY TABLE fy20_promo_jl_increase_or_maintain
SELECT 
	emp_id, gender, fy19_jl, fy19_perf_rating, fy20_jl,
    CASE 
		WHEN fy19_jl > fy20_jl THEN "Increase"
        WHEN fy19_jl = fy20_jl THEN "Maintain"
	ELSE "Decrease"
    END AS fy20_jl_increase,
    fy20_perf_rating, fy21_jl,
    CASE 
		WHEN fy20_jl > fy21_jl THEN "Increase"
        WHEN fy20_jl = fy21_jl THEN "Maintain"
	ELSE "Decrease"
    END AS fy21_jl_increase
FROM fy20_all_promoted_emp_perf_data

-- STEP 3b: Check if promotion = higher job level increase? (FY21 promoted Only)
-- CREATE TEMPORARY TABLE fy21_promo_jl_increase_or_maintain
SELECT 
	emp_id, gender, fy19_jl, fy19_perf_rating, fy20_jl,
    CASE 
		WHEN fy19_jl > fy20_jl THEN "Increase"
        WHEN fy19_jl = fy20_jl THEN "Maintain"
	ELSE "Decrease"
    END AS fy20_jl_increase,
    fy20_perf_rating, fy21_jl,
    CASE 
		WHEN fy20_jl > fy21_jl THEN "Increase"
        WHEN fy20_jl = fy21_jl THEN "Maintain"
	ELSE "Decrease"
    END AS fy21_jl_increase
FROM fy21_all_promoted_emp_perf_data

-- STEP 4a: Count total number of jl increase or maintain (FY20 Only)
SELECT 
	fy20_jl_increase AS fy20_jl_level,
	COUNT(fy20_jl_increase) AS total_count
FROM fy20_promo_jl_increase_or_maintain
GROUP BY 1

-- STEP 4b: Count total number of jl increase or maintain (FY20 Only)
SELECT 
	fy21_jl_increase AS fy21_jl_level,
	COUNT(fy21_jl_increase) AS total_count
FROM fy21_promo_jl_increase_or_maintain
GROUP BY 1

-- STEP 5a: Find how many employees with perf_rating of '1', '2' & '3' were promoted or not in FY20
SELECT 
	fy19_perf_rating,
    COUNT(CASE WHEN fy20_promo = "Yes" THEN emp_id END) AS promoted,
    COUNT(CASE WHEN fy20_promo = "No" THEN emp_id END) AS not_promoted
FROM dim_emp
WHERE fy19_perf_rating != 0
GROUP BY 1
ORDER BY 1

-- STEP 5b: Find how many employees with perf_rating of '1', '2' & '3' were promoted or not in FY21
SELECT 
	fy20_perf_rating,
    COUNT(CASE WHEN fy21_promo = "Yes" THEN emp_id END) AS promoted,
    COUNT(CASE WHEN fy21_promo = "No" THEN emp_id END) AS not_promoted
FROM dim_emp
WHERE fy20_perf_rating != 0
GROUP BY 1
ORDER BY 1 							

-- Find how employees are evaluated to be in fy21_promo_base_group
-- STEP 1: Limit data to only employees who had "Yes" in the fy21_promo_base_group category
SELECT *
FROM dim_emp
WHERE fy21_promo_base_group = "Yes"
	AND fy19_perf_rating != "0"

-- STEP 2: Dive into fy20_base_turnover group to check if there are any employees who had "No"
SELECT DISTINCT
	fy20_base_group_turnover,
    COUNT(fy20_base_group_turnover) AS tot_count
FROM dim_emp
WHERE fy21_promo_base_group = "Yes"
	-- fy20_base_group_turnover = "Yes"
	-- AND fy19_perf_rating != "0"
GROUP BY 1

-- STEP 3: Find out why 66 emp were not in fy20_base_group_turnover
-- 1st glimpse reveals that 66 users are new hires
SELECT *
FROM dim_emp
WHERE fy20_base_group_turnover = "No"

-- Confirm if that's the case
SELECT DISTINCT
	fy20_new_hire,
    COUNT(fy20_new_hire) AS tot_count
FROM dim_emp
WHERE fy20_base_group_turnover = "No"
GROUP BY 1

-- Double confirm by removing (WHERE fy20_base_group_turnover = "No")
SELECT DISTINCT
	fy20_new_hire,
    COUNT(fy20_new_hire) AS tot_count
FROM dim_emp
GROUP BY 1

-- STEP 4: Check to see if all emp who had "Yes" in the fy21_promo_base_group also had "Yes" in fy20_base_group_turnover
SELECT 
	fy20_base_group_turnover,
    COUNT(fy20_base_group_turnover) AS tot_count
FROM dim_emp
WHERE fy21_promo_base_group = "Yes"
GROUP BY 1

-- Check for difference after changing the restriction to WHERE fy21_promo_base_group != "Yes"
SELECT 
	fy20_base_group_turnover,
    COUNT(fy20_base_group_turnover) AS tot_count
FROM dim_emp
WHERE fy21_promo_base_group != "Yes"
GROUP BY 1

-- Check for difference again using the same constraint & also removing new hires 
SELECT 
	fy20_base_group_turnover,
    COUNT(fy20_base_group_turnover) AS tot_count
FROM dim_emp
WHERE fy21_promo_base_group != "Yes"
	AND fy20_new_hire = "No"
GROUP BY 1

-- STEP 5: Confirm analysis to show that the 58 emp are at high risk of leaving, with 47 emp who actually left
SELECT 
	leaver_fy, 
    COUNT(leaver_fy) AS tot_count
FROM dim_emp
WHERE fy21_promo_base_group != "Yes"
	AND fy20_new_hire = "No"
GROUP BY 1

					

-- Find why those in fy21_promo_base_group were not promoted

-- Let's look into the performance of those not promoted
-- STEP 1: Get data for all emp in this segment by showing their FY19 & FY20 performance rating + job level. Then, create a column to see whether they've improved
		# Note: For new hires, "Not applicable" is included to indicate that its their 1st year within the company.
-- CREATE TEMPORARY TABLE fy21_non_promo_fy19_fy20_perf_rating_and_jl
SELECT
	emp_id,
    gender, 
    fy20_jl_bf_promo AS fy19_jl, fy19_perf_rating, 
    fy20_jl_aft_promo AS fy20_jl, fy20_perf_rating, 
    fy21_jl_aft_promo AS fy21_jl,
    CASE 
		WHEN fy19_perf_rating = 0 THEN "Not Applicable"
		WHEN fy19_perf_rating < fy20_perf_rating THEN "No"
        WHEN fy19_perf_rating = fy20_perf_rating THEN "Maintain"
        ELSE "Yes"
	END AS perf_improve
FROM dim_emp
WHERE fy21_promo_base_group = "Yes"
	AND fy21_promo = "No"
    
-- STEP 2: Look into the "Yes" category for perf_improve to find out why. 
		-- Check their performance by seeing how much they've jumped in terms of the rating numbers.
-- CREATE TEMPORARY TABLE fy21_non_promo_emp_w_perf_improv
SELECT
	*, 
	CASE 
		WHEN fy19_perf_rating = 4 AND fy20_perf_rating = 3 THEN "4 -> 3"
        WHEN fy19_perf_rating = 4 AND fy20_perf_rating = 2 THEN "4 -> 2"
        WHEN fy19_perf_rating = 4 AND fy20_perf_rating = 1 THEN "4 -> 1"
        WHEN fy19_perf_rating = 3 AND fy20_perf_rating = 2 THEN "3 -> 2"
		WHEN fy19_perf_rating = 3 AND fy20_perf_rating = 1 THEN "3 -> 1"
        WHEN fy19_perf_rating = 2 AND fy20_perf_rating = 1 THEN "2 -> 1"        
		ELSE "uh oh... check logic"
	END AS rating_jump,
    fy19_perf_rating - fy20_perf_rating AS num_jump
FROM fy21_non_promo_fy19_fy20_perf_rating_and_jl
WHERE perf_improve = "Yes"

-- STEP 3a: Count number of rating jump & group them by rating improvements
SELECT 
	rating_jump,
    COUNT(rating_jump) AS tot_count
FROM fy21_non_promo_emp_w_perf_improv
GROUP BY 1
ORDER BY 1

-- STEP 3b: Re-use STEP 3a's query & break down by gender & pct
  -- Use sub-queries to return results
SELECT 
	rating_jump, gender, emp_count, 
    CONCAT(ROUND((emp_count / rating_jump_group_total)*100, 2), "%") AS pct_of_group_total
FROM (
		SELECT *,
			SUM(emp_count) OVER (PARTITION BY rating_jump) AS rating_jump_group_total
		FROM (
				SELECT 
					rating_jump,
					gender,
					COUNT(rating_jump) AS emp_count
				FROM fy21_non_promo_emp_w_perf_improv
				GROUP BY 1, 2 
				ORDER BY 1, 2
			) subq1
		) subq2


-- Check if num of yrs in the company & employee performance has any significant effect of being promoted for the given dataset?
-- STEP 1a: Get all emp's number of years work & divide the total count by those who are promoted & not promoted
-- CREATE TEMPORARY TABLE tot_work_yrs_all_emp
WITH t1 AS (
	SELECT 
		yrs_since_last_hire AS non_promoted_wrking_yrs,
		COUNT(yrs_since_last_hire) AS non_promoted_tot_count
	FROM dim_emp
	WHERE fy21_promo_base_group = "Yes"
		AND fy21_promo = "No"
		AND fy20_new_hire = "No"
	GROUP BY 1
)
SELECT 
	de.yrs_since_last_hire AS tot_yrs_in_comp,
    COUNT(de.yrs_since_last_hire) AS promoted_tot_count,
    t1.non_promoted_tot_count
FROM dim_emp de
	LEFT JOIN t1
		ON de.yrs_since_last_hire = t1.non_promoted_wrking_yrs
WHERE fy21_promo_base_group = "Yes"
	AND fy21_promo = "Yes"
GROUP BY 1
ORDER BY 1

-- STEP 1b: Re-use STEP 1a's & break it down by gender
-- CREATE TEMPORARY TABLE tot_work_yrs_by_gender_all_emp

SELECT
	*, 
    SUM(promoted_tot_count) OVER (PARTITION BY tot_yrs_in_comp) AS tot_promo,
    SUM(non_promoted_tot_count) OVER (PARTITION BY tot_yrs_in_comp) AS tot_non_promo
FROM (
	WITH t1 AS (
		SELECT 
			yrs_since_last_hire AS tot_wrk_yrs, gender,
			COUNT(yrs_since_last_hire) AS promoted_tot_count
		FROM dim_emp
		WHERE fy21_promo_base_group = "Yes"
			AND fy21_promo = "Yes"
		GROUP BY 1, 2
		ORDER BY 1
	)
    SELECT 
		de.yrs_since_last_hire AS tot_yrs_in_comp, de.gender,
        t1.promoted_tot_count,
		COUNT(de.yrs_since_last_hire) AS non_promoted_tot_count
	FROM dim_emp de
		LEFT JOIN t1
			ON de.yrs_since_last_hire = t1.tot_wrk_yrs
			AND de.gender = t1.gender
	WHERE fy21_promo_base_group = "Yes"
		AND fy21_promo = "No"
		AND fy20_new_hire = "No"
	GROUP BY 1, 2
    ORDER BY 1
) subq1

-- STEP 2a: Bring in avg performance of FY21 promoted employees within each category of working years (Excl. gender)
SELECT 
	*,
    CASE
		WHEN avg_fy19_perf_rating = 0 THEN avg_fy20_perf_rating
        ELSE ((avg_fy20_perf_rating - avg_fy19_perf_rating)*-1) 
	END AS tot_increase
FROM (
	SELECT
		de.yrs_since_last_hire AS tot_yrs_in_comp,
		promoted_tot_count,
		ROUND(AVG(fy19_perf_rating),2) AS avg_fy19_perf_rating,
		ROUND(AVG(fy20_perf_rating),2) AS avg_fy20_perf_rating
	FROM dim_emp de
		JOIN tot_work_yrs_all_emp twyae
			ON twyae.tot_yrs_in_comp = de.yrs_since_last_hire
	WHERE fy21_promo_base_group = "Yes"
		AND fy21_promo = "Yes"
	GROUP BY 1
	ORDER BY 1
) subq1

-- STEP 2b: Bring in avg performance of FY21 non-promoted employees within each category of working years (Excl. gender)
SELECT 
	*,
    CASE
		WHEN avg_fy19_perf_rating = 0 THEN avg_fy20_perf_rating
        ELSE ((avg_fy20_perf_rating - avg_fy19_perf_rating)*-1) 
	END AS tot_increase
FROM (
	SELECT
		de.yrs_since_last_hire AS tot_yrs_in_comp,
		non_promoted_tot_count,
		ROUND(AVG(fy19_perf_rating),2) AS avg_fy19_perf_rating,
		ROUND(AVG(fy20_perf_rating),2) AS avg_fy20_perf_rating
	FROM dim_emp de
		JOIN tot_work_yrs_all_emp twyae
			ON twyae.tot_yrs_in_comp = de.yrs_since_last_hire
	WHERE fy21_promo_base_group = "Yes"
		AND fy21_promo = "No"
	GROUP BY 1
	ORDER BY 1
) subq1

-- STEP 2c: Bring in avg performance of promoted + non-promoted employees within each category of working years (Excl. gender)
SELECT 
	*,
    CASE
		WHEN avg_fy19_perf_rating = 0 THEN avg_fy20_perf_rating
        ELSE ((avg_fy20_perf_rating - avg_fy19_perf_rating)*-1) 
	END AS tot_increase
FROM 
(
	SELECT 
		yrs_since_last_hire,
		ROUND(AVG(fy19_perf_rating),2) AS avg_fy19_perf_rating, 
		ROUND(AVG(fy20_perf_rating),2) AS avg_fy20_perf_rating
	FROM dim_emp
		WHERE fy21_promo_base_group = "Yes"
	GROUP BY 1
	ORDER BY 1
) subq1


-- -------------------------------------------------------------------
# # # # # # # # # # # # PERFORMANCE EDA # # # # # # # # # # # # # # #
-- -------------------------------------------------------------------

-- Find gender breakdown of total employees in Sales & Marketing and Internal Services.

-- Total Sales & Marketing employees by gender
SELECT 
	*,
   CONCAT(ROUND((tot_count / jl_total)*100,2), "%") AS pct_breakdown
FROM (
	SELECT 
		*,
		SUM(tot_count) OVER (PARTITION BY job_level) AS jl_total
	FROM (
		SELECT 
			fy20_jl_aft_promo AS job_level,
			gender,
			COUNT(fy20_jl_aft_promo) AS tot_count-- COUNT(emp_id)
		FROM dim_emp
		WHERE fy20_last_dept = "Sales & Marketing"
		GROUP BY 1, 2
		ORDER BY 1, 2
	) subq1
) subq2

-- Total Internal Services employees by gender
SELECT 
	*,
   CONCAT(ROUND((tot_count / jl_total)*100,2), "%") AS pct_breakdown
FROM (
	SELECT 
		*,
		SUM(tot_count) OVER (PARTITION BY job_level) AS jl_total
	FROM (
		SELECT 
			fy20_jl_aft_promo AS job_level,
			gender,
			COUNT(fy20_jl_aft_promo) AS tot_count-- COUNT(emp_id)
		FROM dim_emp
		WHERE fy20_last_dept = "Internal Services"
		GROUP BY 1, 2
		ORDER BY 1, 2
	) subq1
) subq2


-- Find the total gender breakdown by dept
SELECT 
	gender, 
    COUNT(CASE WHEN fy20_last_dept = "Finance" THEN emp_id END) AS fi_total,
    COUNT(CASE WHEN fy20_last_dept = "HR" THEN emp_id END) AS hr_total,
    COUNT(CASE WHEN fy20_last_dept = "Internal Services" THEN emp_id END) AS hr_total,
    COUNT(CASE WHEN fy20_last_dept = "Operations" THEN emp_id END) AS ops_total,
    COUNT(CASE WHEN fy20_last_dept = "Sales & Marketing" THEN emp_id END) AS sam_total,
    COUNT(CASE WHEN fy20_last_dept = "Strategy" THEN emp_id END) AS strat_total
FROM dim_emp
GROUP BY 1

-- Check performance numbers for S&M employees by gender & jl
	-- Pull FY19 -> FY20 perf improvements by gender & jl

-- STEP 1: Get avg FY19 & FY20 performance for all levels in S&M
-- CREATE TEMPORARY TABLE fy19_fy20_sam_perf_by_gender
SELECT
	*, 
	(avg_fy20_perf_rating - avg_fy19_perf_rating)*-1 AS num_increase,
	CONCAT(ROUND((((avg_fy20_perf_rating - avg_fy19_perf_rating)*-1) / avg_fy19_perf_rating)*100,2), "%") AS pct_increase
FROM 
	(
	SELECT
		fy20_jl_aft_promo, gender,
		COUNT(emp_id) AS tot_emp,
		ROUND(AVG(fy19_perf_rating),2) AS avg_fy19_perf_rating, 
		ROUND(AVG(fy20_perf_rating),2) AS avg_fy20_perf_rating 
	FROM dim_emp
	WHERE fy20_last_dept = "Sales & Marketing"
		AND fy20_new_hire = "No"
		AND fy20_perf_rating != 0
	GROUP BY 1, 2
	ORDER BY 1, 2
) subq1


-- STEP 2: Include total number of performance improvements, maintained & decreased for each jl & gender
-- CREATE TEMPORARY TABLE fy19_fy20_sam_all_perf_count_by_gender
SELECT
	fy20_jl_aft_promo, gender, 
    COUNT(CASE WHEN perf_improve = "Increase" THEN gender END) AS perf_improve,
    COUNT(CASE WHEN perf_improve = "Maintain" THEN gender END) AS perf_maintain,
    COUNT(CASE WHEN perf_improve = "Decrease" THEN gender END) AS perf_decrease,
    COUNT(CASE WHEN perf_improve = "Not Applicable" THEN gender END) AS new_hires_na
FROM
(
SELECT
	fy20_jl_aft_promo, gender,
    fy19_perf_rating, fy20_perf_rating,
    CASE
		WHEN fy19_perf_rating = 0 THEN "Not Applicable"
		WHEN fy20_perf_rating < fy19_perf_rating THEN "Increase" 		-- The lower the number, the better the performance
        WHEN fy20_perf_rating = fy19_perf_rating THEN "Maintain"
        ELSE "Decrease"
	END AS perf_improve
FROM dim_emp
WHERE fy20_last_dept = "Sales & Marketing"
		AND fy20_new_hire = "No"
		AND fy20_perf_rating != 0
) subq1
GROUP BY 1, 2
ORDER BY 1, 2 

-- STEP 3: Join STEP 1 & STEP 2 table together to find out the performance of all emp by job level & gender
SELECT
	t1.fy20_jl_aft_promo AS job_level, t1.gender, t1.tot_emp,
    t2.perf_improve, t2.perf_maintain, t2.perf_decrease, t2.new_hires_na,
    t1.avg_fy19_perf_rating, t1.avg_fy20_perf_rating,
    t1.num_increase, t1.pct_increase
FROM fy19_fy20_sam_perf_by_gender t1
	LEFT JOIN fy19_fy20_sam_all_perf_count_by_gender t2
		ON t2.fy20_jl_aft_promo = t1.fy20_jl_aft_promo 
        AND t2.gender = t1.gender

																	

-- Check promotion numbers for Int.Services employees by gender & jl
	-- Pull FY19 -> FY20 perf improvements by gender & jl

-- STEP 1: Get avg FY19 & FY20 performance for all levels in S&M
-- CREATE TEMPORARY TABLE fy19_fy20_is_perf_by_gender
SELECT
	*, 
	(avg_fy20_perf_rating - avg_fy19_perf_rating)*-1 AS num_increase,
	CONCAT(ROUND((((avg_fy20_perf_rating - avg_fy19_perf_rating)*-1) / avg_fy19_perf_rating)*100,2), "%") AS pct_increase
FROM 
	(
	SELECT
		fy20_jl_aft_promo, gender,
		COUNT(emp_id) AS tot_emp,
		ROUND(AVG(fy19_perf_rating),2) AS avg_fy19_perf_rating, 
		ROUND(AVG(fy20_perf_rating),2) AS avg_fy20_perf_rating 
	FROM dim_emp
	WHERE fy20_last_dept = "Internal Services"
		AND fy20_new_hire = "No"
		AND fy20_perf_rating != 0
	GROUP BY 1, 2
	ORDER BY 1, 2
) subq1


-- STEP 2: Include total number of performance improvements, maintained & decreased for each jl & gender
-- CREATE TEMPORARY TABLE fy19_fy20_is_all_perf_count_by_gender
SELECT
	fy20_jl_aft_promo, gender, 
    COUNT(CASE WHEN perf_improve = "Increase" THEN gender END) AS perf_improve,
    COUNT(CASE WHEN perf_improve = "Maintain" THEN gender END) AS perf_maintain,
    COUNT(CASE WHEN perf_improve = "Decrease" THEN gender END) AS perf_decrease,
    COUNT(CASE WHEN perf_improve = "Not Applicable" THEN gender END) AS new_hires_na
FROM
(
SELECT
	fy20_jl_aft_promo, gender,
    fy19_perf_rating, fy20_perf_rating,
    CASE
		WHEN fy19_perf_rating = 0 THEN "Not Applicable"
		WHEN fy20_perf_rating < fy19_perf_rating THEN "Increase" 		-- The lower the number, the better the performance
        WHEN fy20_perf_rating = fy19_perf_rating THEN "Maintain"
        ELSE "Decrease"
	END AS perf_improve
FROM dim_emp
WHERE fy20_last_dept = "Internal Services"
		AND fy20_new_hire = "No"
		AND fy20_perf_rating != 0
) subq1
GROUP BY 1, 2
ORDER BY 1, 2 

-- STEP 3: Join STEP 1 & STEP 2 table together to find out the performance of all emp by job level & gender
SELECT
	t1.fy20_jl_aft_promo AS job_level, t1.gender, t1.tot_emp,
    t2.perf_improve, t2.perf_maintain, t2.perf_decrease, t2.new_hires_na,
    t1.avg_fy19_perf_rating, t1.avg_fy20_perf_rating,
    t1.num_increase, t1.pct_increase
FROM fy19_fy20_is_perf_by_gender t1
	LEFT JOIN fy19_fy20_is_all_perf_count_by_gender t2
		ON t2.fy20_jl_aft_promo = t1.fy20_jl_aft_promo 
        AND t2.gender = t1.gender

																
