-- -------------------------------------------------------------------
# # # # # # # # # # # # # TREND ANALYSIS # # # # # # # # # # # # # # #
-- -------------------------------------------------------------------

# Trend analysis of the company's hiring activites

-- Find the first instance hiring data was recorded
SELECT MIN(last_hire_date) AS first_record
FROM dim_emp  		

-- Find all records within FY 2011
SELECT *
FROM dim_emp
WHERE YEAR(last_hire_date) = 2011 	

-- Find how many employees were hired each year + show running total up to recent year
-- Use common table expressions (CTE) & WINDOW( ) function to do it
WITH t1 AS (
	SELECT 
		YEAR(last_hire_date) AS yr,
		COUNT(emp_id) AS total_emp
	FROM dim_emp
	GROUP BY 1
	ORDER BY 1
)

SELECT 
	yr, total_emp, 
	SUM(total_emp) OVER (ORDER BY yr) AS running_tot
FROM t1 			

-- Find the average number of employees hired over the entire dataset
-- Use common table expressions (CTE) & WINDOW( ) function to do it
WITH t1 AS (
	SELECT 
		YEAR(last_hire_date) AS yr,
		COUNT(emp_id) AS total_emp
	FROM dim_emp
	GROUP BY 1
	ORDER BY 1
)

SELECT 
	COUNT(yr) AS total_yrs,
	ROUND((SUM(total_emp) / COUNT(yr)),2) AS avg_hire_num
FROM t1 			


-- Find the hiring trend for both gender throughout the entire dataset
-- STEP 1: Create temp table to get male & female hires by year
-- CREATE TEMPORARY TABLE hiring_trend_by_yr_gender
SELECT 
	YEAR(last_hire_date) AS yr,
    COUNT(CASE WHEN gender = "M" THEN emp_id END) AS male_hires,
    COUNT(CASE WHEN gender = "F" THEN emp_id END) AS female_hires
FROM dim_emp
GROUP BY 1
ORDER BY 1

-- STEP 2: Get running total & pct of male & female hires
-- CREATE TEMPORARY TABLE hiring_trend_pct_and_running_tot_by_yr_gender
SELECT 
	yr, male_hires, 
    SUM(male_hires) OVER (ORDER BY yr) AS m_running_tot,
    female_hires,
    SUM(female_hires) OVER (ORDER BY yr) AS f_running_tot,
    SUM(male_hires + female_hires) AS total,
    CONCAT(ROUND((male_hires / SUM(male_hires + female_hires))*100,2), "%") AS pct_of_m_hires,
    CONCAT(ROUND((female_hires / SUM(male_hires + female_hires))*100,2), "%") AS pct_of_f_hires
FROM hiring_trend_by_yr_gender
GROUP BY 1

-- STEP 3: Get average number of male & female hires
SELECT 
	COUNT(yr) AS total_yrs,
    ROUND((SUM(male_hires) / COUNT(yr)),2) AS avg_m_hires,
    ROUND((SUM(female_hires) / COUNT(yr)),2) AS avg_f_hires
FROM hiring_trend_pct_and_running_tot_by_yr_gender 			


-- -------------------------------------------------------------------
# # # # # # # # # # # # DIVERSITY ANALYSIS # # # # # # # # # # # # # #
-- -------------------------------------------------------------------

-- Create a table to analyze the company's diversity program situation in FY21 by excluding fy20 leavers
-- CREATE TEMPORARY TABLE dim_emp_active
SELECT *
FROM dim_emp
WHERE leaver_fy != "FY20" 		


-- -------------------------------------------------------------------
# # # # # # # # # # # # # # # JOB LEVEL # # # # # # # # # # # # # # #
-- -------------------------------------------------------------------

-- Find which job level is uneven
SELECT DISTINCT 
	fy20_jl_group_pra
FROM fact_main
WHERE fy20_jl_group_pra_status = "Uneven - Men benefit"			

-- Get total count as well (incl FY20 leavers)
SELECT 
	DISTINCT fy20_jl_group_pra, 
    COUNT(emp_id) AS total_emp_count
FROM fact_main
WHERE fy20_jl_group_pra_status = "Uneven - Men benefit"
GROUP BY 1 			

-- Get the same results but excluding FY20 leavers
SELECT 
	DISTINCT f.fy20_jl_group_pra, 
    COUNT(f.emp_id) AS total_emp_count
FROM dim_emp_active dea
	LEFT JOIN fact_main f
		ON f.emp_id = dea.emp_id
WHERE f.fy20_jl_group_pra_status = "Uneven - Men benefit"
GROUP BY 1 				

-- Get the same results for job level & dept but excluding FY20 leavers
SELECT 
	DISTINCT f.fy20_jl_dept_group_pra, 
    COUNT(f.emp_id) AS total_emp_count
FROM dim_emp_active dea
	LEFT JOIN fact_main f
		ON f.emp_id = dea.emp_id
WHERE f.fy20_jl_dept_group_pra_status = "Uneven - Men benefit"
GROUP BY 1 	 			

-- Find why senior manager is uneven (men benefit)
-- Gender & age group breakdown of the job level (3 - Senior manager)
SELECT 
	de.gender, de.age_group,
    COUNT(CASE 
		WHEN de.gender = "M" THEN de.emp_id 
        ELSE de.emp_id 
	END) AS tot_emp
FROM dim_emp de
	LEFT JOIN fact_main f
		ON f.emp_id = de.emp_id
WHERE f.fy20_jl_group_pra_status = "Uneven - Men benefit"
GROUP BY 1, 2 			

-- Find total count of employees by region as well 
SELECT
	drc.broad_region_group_nationality AS region, de.gender, de.age_group,
    COUNT(CASE 
		WHEN de.gender = "M" THEN de.emp_id 
        ELSE de.emp_id 
	END) AS tot_emp
FROM dim_emp de
	LEFT JOIN fact_main f
		ON f.emp_id = de.emp_id 
	LEFT JOIN dim_region_country drc
		ON drc.country_id = de.region_country_id 
WHERE f.fy20_jl_group_pra_status = "Uneven - Men benefit"
GROUP BY 1, 2, 3
ORDER BY 4 DESC  			


-- Let's compare how each job level category stack up to each other in terms of total employees, grand total and percentage breakdown.

-- Get total employees by other job level, gender & age group
-- STEP 1: Get emp number breakdown by job level, gender & age
-- CREATE TEMPORARY TABLE jl_by_gender_age
SELECT
	de.fy20_jl_aft_promo AS job_level, de.gender, de.age_group,
    COUNT(CASE 
		WHEN de.gender = "M" THEN de.emp_id 
        ELSE de.emp_id 
	END) AS tot_emp
FROM dim_emp de
	LEFT JOIN fact_main f
		ON f.emp_id = de.emp_id 
WHERE fy20_jl_group_pra_status = "Even"
GROUP BY 1, 2, 3
ORDER BY 1 DESC, 4 DESC

-- STEP 2: Display grand total column next to tot_emp
-- CREATE TEMPORARY TABLE jl_multi_tot_by_gender_age
SELECT 
	job_level, gender, age_group, tot_emp,
    SUM(tot_emp) OVER (PARTITION BY job_level) AS grand_total,
    SUM(tot_emp) OVER (PARTITION BY job_level, age_group) AS sub_grand_total
FROM jl_by_gender_age
GROUP BY 1, 2, 3
ORDER BY 5 DESC, 3 

-- STEP 3: Divide tot_emp by sub_grand_total to get pct breakdown
SELECT 
	job_level, gender, age_group, tot_emp, sub_grand_total AS sub_grand,
    CONCAT(ROUND((tot_emp / sub_grand_total)*100,2), "%") As pct_of_subtotal, grand_total
FROM jl_multi_tot_by_gender_age
-- WHERE job_level IN ('2 - Director', '4 - Manager')
ORDER BY sub_grand DESC			


-- Based on the results above, let's check the hiring trend for employees across various categories 
-- Hiring trend by working years & job_level
SELECT 
	yrs_since_last_hire AS wrking_yrs,
    COUNT(CASE WHEN fy20_jl_aft_promo = '6 - Junior Officer' THEN emp_id END) AS six_junior_hires,
    COUNT(CASE WHEN fy20_jl_aft_promo = '5 - Senior Officer' THEN emp_id END) AS five_senior_hires,
    COUNT(CASE WHEN fy20_jl_aft_promo = '4 - Manager' THEN emp_id END) AS four_manager_hires,
    COUNT(CASE WHEN fy20_jl_aft_promo = '3 - Senior Manager' THEN emp_id END) AS three_sen_manager_hires,
    COUNT(CASE WHEN fy20_jl_aft_promo = '2 - Director' THEN emp_id END) AS two_director_hires,
    COUNT(CASE WHEN fy20_jl_aft_promo = '1 - Executive' THEN emp_id END) AS one_exec_hires
FROM dim_emp
GROUP BY 1
ORDER BY 1 	DESC			

-- Find hiring trend for uneven categories

-- Start with hiring trend by year & gender for 3 - senior manager
-- STEP 1: Get hiring trend by year & gender for senior manager
-- CREATE TEMPORARY TABLE sm_hiring_trend_by_yr_gender
SELECT 
	YEAR(last_hire_date) AS yr,
    COUNT(CASE WHEN gender = "M" AND fy20_jl_aft_promo = '3 - Senior Manager' THEN emp_id END) AS m_sm_hires,
    COUNT(CASE WHEN gender = "F" AND fy20_jl_aft_promo = '3 - Senior Manager' THEN emp_id END) AS f_sm_hires,
    (SELECT COUNT(emp_id) FROM dim_emp WHERE fy20_jl_aft_promo = '3 - Senior Manager') AS grand_total_hire
FROM dim_emp
GROUP BY 1
ORDER BY 1

-- STEP 2: Get subtotal for both male & female senior manager hires
-- CREATE TEMPORARY TABLE sm_hiring_trend_by_yr_gender_subt
SELECT 
	yr, m_sm_hires, f_sm_hires,
    SUM(m_sm_hires + f_sm_hires) OVER (PARTITION BY yr) AS sub_total,
    grand_total_hire
FROM sm_hiring_trend_by_yr_gender


-- STEP 3: Get percentage breakdown of those hire by gender
SELECT 
	yr, m_sm_hires, f_sm_hires, sub_total, 
    CONCAT(ROUND((m_sm_hires / sub_total)*100,2), "%") AS m_pct_of_subt_hires,
    CONCAT(ROUND((f_sm_hires / sub_total)*100,2), "%") AS f_pct_of_subt_hires
FROM sm_hiring_trend_by_yr_gender_subt		
											

-- How many active employees are left in 3 - Senior Manager?
SELECT 
	COUNT(emp_id) AS tot_active_senior_managers
FROM dim_emp
WHERE fy20_jl_aft_promo = "3 - Senior Manager"
	AND fy20_leaver != "Yes" 			
	
-- How many of the 3 - Senior managers were new hire?
SELECT 
	COUNT(emp_id) AS total_emp,
    COUNT(CASE WHEN fy20_new_hire = "No" THEN emp_id END) AS old_emp,
    COUNT(CASE WHEN fy20_new_hire = "Yes" THEN emp_id END) AS fy20_new_hire
FROM dim_emp
WHERE fy20_jl_aft_promo = "3 - Senior Manager"
	AND fy20_leaver != "Yes" 				

-- What's the gender % of the 3 - Senior Manager hire?
SELECT 
	gender,
    COUNT(CASE WHEN fy20_new_hire = "Yes" THEN emp_id END) AS fy20_total_hires,
    CONCAT(ROUND((COUNT(CASE WHEN fy20_new_hire = "Yes" THEN emp_id END) / 
		(SELECT COUNT(emp_id) FROM dim_emp WHERE fy20_jl_aft_promo = "3 - Senior Manager" AND fy20_new_hire = "Yes"))*100,0), "%") AS pct_of_total_hires
FROM dim_emp
WHERE fy20_jl_aft_promo = "3 - Senior Manager"
	AND fy20_leaver != "Yes" 	
GROUP BY 1 					

-- Were there any promotions from 4 - Manager → 3 Senior Manager for 2021?
SELECT 
	(SELECT COUNT(emp_id) FROM dim_emp WHERE fy20_jl_aft_promo = "3 - Senior Manager" AND fy20_leaver != "Yes") AS fy20_tot_sen_manager,
    COUNT(emp_id) AS fy21_tot_sen_manager,
    COUNT(emp_id) - (SELECT COUNT(emp_id) FROM dim_emp WHERE fy20_jl_aft_promo = "3 - Senior Manager" AND fy20_leaver != "Yes") AS num_promoted,
    CONCAT(ROUND(((COUNT(emp_id) - (SELECT COUNT(emp_id) FROM dim_emp WHERE fy20_jl_aft_promo = "3 - Senior Manager" AND fy20_leaver != "Yes")) / 
		(SELECT COUNT(emp_id) FROM dim_emp WHERE fy20_jl_aft_promo = "3 - Senior Manager" AND fy20_leaver != "Yes"))*100,2), "%") AS emp_pct_increase
FROM dim_emp
WHERE fy21_jl_aft_promo = "3 - Senior Manager"
	AND fy20_leaver != "Yes" 			

-- Based on the results above, let's find what the gender % is for those hires.

-- STEP 1: Get total emp by gender in fy20
-- CREATE TEMPORARY TABLE fy20_tot_sen_manager
SELECT 
	gender,
	COUNT(emp_id) AS total_count
FROM dim_emp
WHERE fy20_jl_aft_promo = "3 - Senior Manager"
	AND fy20_leaver != "Yes" 
GROUP BY 1

-- STEP 2: Get emp difference in fy21
-- CREATE TEMPORARY TABLE fy21_sm_starting_count
SELECT 
	de.gender,
    fytsm.total_count AS fy20_tot_sm,
    COUNT(de.emp_id) AS fy21_tot_sm,
    COUNT(emp_id) - fytsm.total_count AS num_promoted
FROM dim_emp de
	LEFT JOIN fy20_tot_sen_manager fytsm
		ON fytsm.gender = de.gender
WHERE de.fy21_jl_aft_promo = "3 - Senior Manager"
	AND de.fy20_leaver != "Yes" 
GROUP BY 1

-- STEP 3: Get the total num of employees promoted to 3 - Senior Manager
-- CREATE TEMPORARY TABLE fy21_sm_starting_count_w_diff
SELECT 
	de.gender,
    fytsm.total_count AS fy20_tot_sm,
    COUNT(de.emp_id) AS fy21_tot_sm,
    COUNT(emp_id) - fytsm.total_count AS num_promoted,
    (SELECT SUM(num_promoted) AS total_count FROM fy21_sm_starting_count) AS tot_count
FROM dim_emp de
	LEFT JOIN fy20_tot_sen_manager fytsm
		ON fytsm.gender = de.gender
WHERE de.fy21_jl_aft_promo = "3 - Senior Manager"
	AND de.fy20_leaver != "Yes" 
GROUP BY 1

-- STEP 4: Get percent promoted by gender
SELECT 
	gender, fy20_tot_sm, fy21_tot_sm, num_promoted, 
    CONCAT(ROUND((num_promoted / tot_count)*100, 2), "%") AS gender_promo_pct_breakdown
FROM fy21_sm_starting_count_w_diff
		
														
