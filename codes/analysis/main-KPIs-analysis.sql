-- -------------------------------------------------------------------
# # # # # # # # # # # # # # # HIRING # # # # # # # # # # # # # # # # #
-- -------------------------------------------------------------------

-- Total number of Male & Female employees
SELECT 
	gender,
    COUNT(gender) As total_count
FROM dim_emp
GROUP BY 1 			 

-- Temp tables to get total number of FY20 hires by gender
-- STEP 1: Create a temp table that gets total hire by gender & grand total number of hires
-- CREATE TEMPORARY TABLE fy_20_hires_by_gender
SELECT 
	gender,
    COUNT(gender) AS gender_breakdown,
    (SELECT COUNT(gender) AS total_hires FROM dim_emp WHERE fy20_new_hire = "Yes") AS total_hires
FROM dim_emp
WHERE fy20_new_hire = "Yes"
GROUP BY 1

-- STEP 2: Show the % of hires by gender
SELECT 
	gender,
    gender_breakdown AS total_hires, 
    CONCAT(ROUND((gender_breakdown / total_hires)*100,2), "%") AS pct_total_hire
FROM fy_20_hires_by_gender 			

-- Temp tables to get total number of hires before FY20 by gender
-- STEP 1: Create temporary table for hires by gender before 2020
-- CREATE TEMPORARY TABLE pre_fy_20_hires_by_gender
SELECT
	gender,
    COUNT(gender) AS gender_breakdown,
    (SELECT COUNT(gender) FROM dim_emp WHERE fy20_new_hire = "No") AS grand_total
FROM dim_emp
WHERE fy20_new_hire = "No"
GROUP BY 1

-- STEP 2: Return % of hires by gender
SELECT 
	gender,
    gender_breakdown AS total_hires,
    CONCAT(ROUND((gender_breakdown / grand_total)*100,2), "%") AS pct_total_hires
FROM pre_fy_20_hires_by_gender 			


-- -------------------------------------------------------------------
# # # # # # # # # # # # # # PROMOTION # # # # # # # # # # # # # # # #
-- -------------------------------------------------------------------

-- Number of active employees promoted in fy21 (excl. leavers)
SELECT 
	COUNT(emp_id) AS total_emp,
    COUNT(CASE WHEN fy21_promo = "Yes" THEN emp_id END) AS total_promo,
    CONCAT(ROUND((COUNT(CASE WHEN fy21_promo = "Yes" THEN emp_id END) / COUNT(emp_id))*100,2), "%") AS pct_promoted
FROM dim_emp
WHERE leaver_fy != "FY20" 						

-- Number of active employees promoted in fy21 (incl. leavers)
SELECT 
	COUNT(emp_id) AS total_emp,
    COUNT(CASE WHEN fy21_promo = "Yes" THEN emp_id END) AS total_promo,
    CONCAT(ROUND((COUNT(CASE WHEN fy21_promo = "Yes" THEN emp_id END) / COUNT(emp_id))*100,2), "%") AS pct_promoted
FROM dim_emp					

-- Number of active women employees promoted in fy21
SELECT 
	COUNT(emp_id) AS total_emp,
    COUNT(CASE WHEN fy21_promo = "Yes" THEN emp_id END) AS total_promo,
    COUNT(CASE WHEN gender = "F" AND fy21_promo = "Yes" THEN emp_id END) AS total_f_promoted,
    CONCAT(ROUND((COUNT(CASE WHEN gender = "F" AND fy21_promo = "Yes" THEN emp_id END)  / 
		COUNT(CASE WHEN fy21_promo = "Yes" THEN emp_id END))*100,2), "%") AS f_pct_promoted
FROM dim_emp
WHERE leaver_fy != "FY20" 					


-- -------------------------------------------------------------------
# # # # # # # # # # # # # PERFROMANCE # # # # # # # # # # # # # # # #
-- -------------------------------------------------------------------
-- Avg performance rating by gender for FY20 (includes people leaving in fy20)
SELECT 
    ROUND(AVG(CASE WHEN gender = "M" THEN fy20_perf_rating END),2) AS m_avg_perf_rating,
    ROUND(AVG(CASE WHEN gender = "F" THEN fy20_perf_rating END),2) AS f_avg_perf_rating
FROM dim_emp
WHERE fy20_perf_rating != 0 			

-- Avg performance rating by gender for FY20 (excl. people leaving in fy20)
SELECT 
    ROUND(AVG(CASE WHEN gender = "M" THEN fy20_perf_rating END),2) AS m_avg_perf_rating,
    ROUND(AVG(CASE WHEN gender = "F" THEN fy20_perf_rating END),2) AS f_avg_perf_rating
FROM dim_emp
WHERE fy20_perf_rating != 0 
	AND leaver_fy != "FY20" 			



-- -------------------------------------------------------------------
# # # # # # # # # # # # # # TURNOVER # # # # # # # # # # # # # # # # #
-- -------------------------------------------------------------------
-- Number of employees who left in FY20
SELECT 
	COUNT(emp_id) AS total_emp,
    COUNT(CASE WHEN leaver_fy != "Not Applicable" THEN emp_id END) AS total_leavers,
    CONCAT(ROUND((COUNT(CASE WHEN leaver_fy != "Not Applicable" THEN emp_id END) / COUNT(emp_id))*100,2), "%") AS pct_of_leavers
FROM dim_emp 			

-- Temp tables to get annual turnover % rate
-- STEP 1: Get average number of employees by returning total leavers + total starting & ending emp
-- CREATE TEMPORARY TABLE avg_employee_num
SELECT 
	COUNT(emp_id) AS total_starting_emp,
    COUNT(emp_id) - COUNT(CASE WHEN leaver_fy != "Not Applicable" THEN emp_id END) AS total_ending_emp,
    COUNT(CASE WHEN leaver_fy != "Not Applicable" THEN emp_id END) AS total_leavers
FROM dim_emp


-- STEP 2: Get annual turnover rate with the formula: total leavers / (avg employee num / 2) 
SELECT 
    total_starting_emp, total_leavers,  
    ROUND((total_starting_emp + total_ending_emp) / 2, 2) AS avg_employee_num,
    CONCAT(ROUND((total_leavers / ROUND((total_starting_emp + total_ending_emp) / 2, 2))*100, 2), "%") AS annual_turnover_rate
FROM avg_employee_num 				

-- Company's annual retention rate
SELECT 
	COUNT(emp_id) AS total_starting_emp,
    COUNT(emp_id) - COUNT(CASE WHEN leaver_fy != "Not Applicable" THEN emp_id END) AS total_ending_emp,
    CONCAT(ROUND(((COUNT(emp_id) - COUNT(CASE WHEN leaver_fy != "Not Applicable" THEN emp_id END)) / COUNT(emp_id))*100,2), "%") AS annual_retention_rate
FROM dim_emp 	
