-- -------------------------------------------------------------------
# # # # # # # # # # # # # # TUNROVER EDA # # # # # # # # # # # # # # # 
-- -------------------------------------------------------------------

-- Does FY20 turnover have any significant impact to gender imbalance?
-- Find turnover numbers by dept & gender
-- STEP 1: Get total employee count by gender & dept
-- CREATE TEMPORARY TABLE fy20_tot_emp_by_gender_dept
SELECT
	fy20_last_dept, gender,
	COUNT(emp_id) AS tot_emp
FROM dim_emp
GROUP BY 1, 2
ORDER BY 1, 2

-- STEP 2: Reuse STEP 1's query for employees who left
-- CREATE TEMPORARY TABLE fy20_tot_leavers_by_gender_dept
SELECT
	fy20_last_dept, gender,
	COUNT(emp_id) AS tot_emp
FROM dim_emp
WHERE leaver_fy = "FY20"
GROUP BY 1, 2
ORDER BY 1, 2

-- STEP 3: Join STEP 1 & STEP 2's table together to find total num of peeps who left
	-- Also, show percentage breakdown of it.
-- CREATE TEMPORARY TABLE fy20_tot_emp_leavers_by_dept_gender
SELECT 
	*, 
    CONCAT(ROUND((tot_leavers / tot_emp)*100,2),"%") AS pct_left_by_gender,
    CONCAT(ROUND((tot_leavers / dept_gender_total)*100,2),"%") AS pct_left_by_dept_gender
FROM 
(
SELECT 	
	t1.fy20_last_dept AS dept_name, t1.gender, 
    t1.tot_emp, 
	CASE 
		WHEN t2.tot_emp IS NULL THEN 0
        ELSE t2.tot_emp
	END AS tot_leavers,
    SUM(t1.tot_emp) OVER (PARTITION BY t1.fy20_last_dept) AS dept_gender_total
FROM fy20_tot_emp_by_gender_dept t1
	LEFT JOIN fy20_tot_leavers_by_gender_dept t2
		ON t2.fy20_last_dept = t1.fy20_last_dept
        AND t2.gender = t1.gender
 ) subq1
 
 -- STEP 4: Get total count of males & female leavers
 SELECT 	
	gender, SUM(tot_emp) AS gender_total,
    SUM(tot_leavers) AS totl_leavers																		

-- Find turnover numbers in the uneven jl + jl & dept categories

-- STEP 1: Get all employees in the 3 - Senior Manager category
-- CREATE TEMPORARY TABLE fy20_tot_sn_mngr
SELECT
	fy20_last_dept, gender, 
    COUNT(emp_id) AS tot_emp
FROM dim_emp
WHERE fy20_jl_aft_promo = "3 - Senior Manager"
GROUP BY 1, 2

-- STEP 2: Get all leavers in the 3 - Senior Manager category
-- CREATE TEMPORARY TABLE fy20_tot_sn_mngr_leavers
SELECT
	fy20_last_dept, gender, 
    COUNT(emp_id) AS tot_emp
FROM dim_emp
WHERE fy20_jl_aft_promo = "3 - Senior Manager"
	AND leaver_fy = "FY20"
GROUP BY 1, 2

-- STEP 3: Combine STEP 1 & STEP 2 tables together
-- CREATE TEMPORAY TABLE fy20_tot_sn_mngr_tot_emp_andleavers
SELECT 
	*
FROM 
(
	SELECT 
		t1.fy20_last_dept AS dept_name, t1.gender, t1.tot_emp, 
		CASE
			WHEN t2.tot_emp IS NULL THEN 0
			ELSE t2.tot_emp
		END AS tot_leavers
	FROM fy20_tot_sn_mngr t1
		LEFT JOIN fy20_tot_sn_mngr_leavers t2
			ON t2.fy20_last_dept = t1.fy20_last_dept
			AND t2.gender = t1.gender 
) subq1


-- Create pivot table to check total employees in fy20_turnover, not in fy20_turnover, total fy20_left
SELECT 
	COUNT(CASE WHEN fy20_base_group_turnover = "Yes" THEN emp_id END) AS fy20_base_turnover,
    COUNT(CASE WHEN fy20_base_group_turnover = "Yes" AND leaver_fy = "Not Applicable" AND fy20_new_hire = "No" THEN emp_id END) AS fy20_base_retained,
    COUNT(CASE WHEN leaver_fy = "FY20" THEN emp_id END) AS fy20_leaver,
    COUNT(CASE WHEN fy20_base_group_turnover = "No" AND fy20_new_hire = "No" THEN emp_id END) AS fy20_base_non_turnover, 	-- Were there any employees were not in FY20 base group but also retained?
    COUNT(CASE WHEN leaver_fy = "Not Applicable" THEN emp_id END) - COUNT(CASE WHEN fy20_base_group_turnover = "Yes" AND leaver_fy = "Not Applicable" AND fy20_new_hire = "No" THEN emp_id END) AS fy20_new_hires,
    COUNT(CASE WHEN leaver_fy = "Not Applicable" THEN emp_id END) AS fy20_leftover
FROM dim_emp
