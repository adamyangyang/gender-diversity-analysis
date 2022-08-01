-- SQL Query for implementing Type 2 SCD
-- ----------------------------------------------------------------
-- STEP 1: Get all employee data for fy19 (exclude FY20 hires)
-- ----------------------------------------------------------------
-- CREATE TEMPORARY TABLE dim_emp_fy19
SELECT
	emp_id, gender, fy20_jul_age - 1 AS age, 						-- Have to subtract age by 1 because we're getting emp data from 1 year ago 
    CASE 															-- Have to manually redo age group because we're subtracting fy20 age by 1 year 
		WHEN fy20_jul_age - 1 BETWEEN 16 AND 19 THEN "16 to 19" 	
        WHEN fy20_jul_age - 1 BETWEEN 20 AND 29 THEN "20 to 29"
        WHEN fy20_jul_age - 1 BETWEEN 30 AND 39 THEN "30 to 39"
        WHEN fy20_jul_age - 1 BETWEEN 40 AND 49 THEN "40 to 49"
        WHEN fy20_jul_age - 1 BETWEEN 50 AND 59 THEN "50 to 59"
        WHEN fy20_jul_age - 1 BETWEEN 60 AND 69 THEN "60 to 69"
	END AS age_group,
    last_hire_date AS hire_date,  									-- Use hire date to be more specific with naming convention
    CASE 															-- Use 'from date' to indicate the date this employee starts a new position (if any)
		WHEN last_hire_date < "2019-01-01" THEN "2019-01-01"
        ELSE last_hire_date
	END AS from_date,
    CASE 															-- Use 'end date' to indicate when this record will expire
		WHEN YEAR(last_hire_date) < 2020 THEN "2019-12-31"
        ELSE "uh oh... re-check logic"
	END AS end_date, 
    yrs_since_last_hire - 1 AS yrs_since_last_hire,  contract_id, region_country_id,
    fy20_last_dept AS dept,
    fy20_jl_bf_promo AS job_level, 
    fy19_perf_rating AS perf_rating, fy20_promo AS jl_promo,
    -- fy20_jl_aft_promo AS next_yr_job_level,
    CASE 															-- Use 'current_flag' as an indicator of whether this record is active or not
		WHEN YEAR(last_hire_date) < 2020 THEN "N"
        ELSE "Y"
	END AS current_flag,
    CASE 															-- Used to tell whether this employee was employed in the company within the specified year 
		WHEN leaver_fy IS NOT NULL THEN "Y"
        ELSE "N"
	END AS employed_flag,
    CASE 															-- Used to indicate whether someone left the company within a specified year
		WHEN leaver_fy IS NOT NULL THEN "N"
	END AS leaver_flag,
    CASE 															-- Used to indicate whether someone was recently hired within a specified year
		WHEN fy20_new_hire IS NOT NULL THEN "N"
	END AS new_hire_flag,
    CASE 															-- All values here are dummy values because there's no new hires in fy19_turnover_base_group
		WHEN fy20_base_group_turnover IS NOT NULL THEN "N"
	END AS turnover_base_group,
    CASE 															-- Used as an indicator for FY20 & FY21 table
		WHEN fy20_promo = "Yes" THEN "Yes"
        ELSE "No"
	END AS promo_base_group
FROM dim_emp
WHERE fy20_new_hire = "No" 											-- Get only employees in FY19


-- ----------------------------------------------------------------
-- STEP 2: Get all employee data for fy20 
-- ----------------------------------------------------------------
-- CREATE TEMPORARY TABLE dim_emp_fy20
SELECT
	emp_id, gender, fy20_jul_age AS age, age_group,
    last_hire_date AS hire_date,
    CASE 															-- Use 'from date' to indicate the date this employee starts a new position (if any) 
		WHEN last_hire_date < "2020-01-01" THEN "2020-01-01"
        ELSE last_hire_date
	END AS from_date,
    CASE 															-- Use 'end date' to indicate when this record will expire
		WHEN leaver_fy IS NOT NULL THEN "2020-12-31"
	END AS end_date,
    yrs_since_last_hire, contract_id, region_country_id,
    fy20_last_dept AS dept,
    fy20_jl_aft_promo AS job_level, 
    fy20_perf_rating AS perf_rating, fy21_promo AS jl_promo,
    CASE 															-- Use 'current_flag' as an indicator of whether this record is active or not
		WHEN last_hire_date IS NOT NULL THEN "N"
	END AS current_flag,
    CASE 															-- Used to tell whether this employee was employed in the company within the specified year  
		WHEN leaver_fy = "Not Applicable" THEN "Y"
        ELSE "N"
	END AS employed_flag,
    CASE 															-- Used to indicate whether someone left the company within a specified year
		WHEN leaver_fy != "Not Applicable" THEN "Y"
        ELSE "N"
	END AS leaver_flag,
    CASE 															-- Used to indicate whether someone was recently hired within a specified year
		WHEN fy20_new_hire = "No" THEN "N"
        ELSE "Y"
	END AS new_hire_flag,
    fy20_base_group_turnover AS turnover_base_group,
    fy21_promo_base_group AS promo_base_group
FROM dim_emp

-- ----------------------------------------------------------------
-- STEP 3a: Get all employee data for fy19 to combine cur_job_level & next_yr_job_level into 1 column
-- ----------------------------------------------------------------
-- CREATE TEMPORARY TABLE dim_emp_fy21
SELECT
	emp_id, gender, fy20_jul_age + 1 AS age, 						-- Have to subtract age by 1 because we're getting emp data from 1 year ago 
    CASE 															-- Have to manually redo age group because we're adding fy20 age by 1 year  
		WHEN fy20_jul_age + 1 BETWEEN 16 AND 19 THEN "16 to 19"
        WHEN fy20_jul_age + 1 BETWEEN 20 AND 29 THEN "20 to 29"
        WHEN fy20_jul_age + 1 BETWEEN 30 AND 39 THEN "30 to 39"
        WHEN fy20_jul_age + 1 BETWEEN 40 AND 49 THEN "40 to 49"
        WHEN fy20_jul_age + 1 BETWEEN 50 AND 59 THEN "50 to 59"
        WHEN fy20_jul_age + 1 BETWEEN 60 AND 69 THEN "60 to 69"
	END AS age_group,
    last_hire_date AS hire_date, 
    CASE 															-- Use 'from date' to indicate the date this employee starts a new position (if any)
		WHEN last_hire_date < "2021-01-01" THEN "2021-01-01"
        ELSE last_hire_date
	END AS from_date,
    CASE 															-- Use 'end date' to indicate when this record will expire
		WHEN leaver_fy IS NOT NULL THEN "9999-12-31"
	END AS end_date, 
    yrs_since_last_hire + 1 AS yrs_since_last_hire,  contract_id, region_country_id,
    fy20_last_dept AS dept,
    fy21_jl_aft_promo AS job_level,
    CASE 															-- All values here are dummy values because there's no fy21_perf_rating
		WHEN fy20_perf_rating IS NOT NULL THEN 0
        ELSE 0
	END AS perf_rating, 
    CASE 															-- All values here are dummy values because there's no fy22_jl_promo 
		WHEN fy21_promo IS NOT NULL THEN "No"
        ELSE "No"
	END AS jl_promo,
    CASE 															-- Use 'current_flag' as an indicator of whether this record is active or not
		WHEN YEAR(last_hire_date) < 2021 THEN "Y"
        ELSE "N"
	END AS current_flag,
    CASE 															-- Used to tell whether this employee was employed in the company within the specified year 
		WHEN leaver_fy = "Not Applicable" THEN "Y"
        ELSE "N"
	END AS employed_flag,
    CASE 															-- All values here are dummy values because there's no fy21_leaver
		WHEN leaver_fy != "Not Applicable" THEN "Y"
        ELSE "N"
	END AS leaver_flag,
    CASE 															-- All values here are dummy values because there's no new hires in fy21
		WHEN fy20_new_hire IS NOT NULL THEN "N"
	END AS new_hire_flag,
    CASE 															-- All values here are dummy values because there's no fy21_turnover_base_group 
		WHEN fy20_base_group_turnover IS NOT NULL THEN "No"
	END AS turnover_base_group,
    CASE 															-- All values here are dummy values because there's no fy21_promo_base_group
		WHEN fy20_promo IS NOT NULL THEN "No" 
	END AS promo_base_group
FROM dim_emp
WHERE leaver_fy != "FY20" 											-- Get only employees in FY21 (Total FY20 Employees - Total FY20 Leavers)


-- Data validation of total employee count for FY19, FY20 & FY21
SELECT COUNT(emp_id) AS total_fy19_employees FROM dim_emp WHERE fy20_new_hire != "Yes" -- FY19 has 434 employees
SELECT COUNT(emp_id) AS total_fy20_employees FROM dim_emp -- FY20 has 500 employees
SELECT (SELECT COUNT(emp_id) FROM dim_emp) - COUNT(emp_id) AS starting_fy21_employees FROM dim_emp WHERE fy20_leaver = "Yes" -- FY21 has 453 employees

-- ----------------------------------------------------------------------------------------------------------------------
-- STEP 3b: Create remaining temporary tables on the gender diversity status in both job-level and job-level + dept group
-- -----------------------------------------------------------------------------------------------------------------------
-- Get the gender diversity status of each job-level group in fy20
-- CREATE TEMPORARY TABLE dim_emp_jl_group_pra_no_zero
SELECT *
FROM dim_emp_jl_group_pra
WHERE jl_group_pra_id != 0;

-- Get the gender diversity status of each job-level & department group in fy20
-- CREATE TEMPORARY TABLE dim_emp_jl_dept_group_pra_no_zero
SELECT *
FROM dim_emp_jl_dept_group_pra
WHERE fy20_jl_dept_group_pra_id != 0

-- -------------------------------------------------------------------------------------------------------------------------------------------------------
-- STEP 4: After separating all employee data into fy19, 20, 21, we use UNION to combine STEP 1 - 3a tables. Then, join back to tables created in STEP 3b. 
-- -------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE TEMPORARY TABLE dim_emp_scd
SELECT t1.*, t3.* , t4.*
FROM
(
	SELECT * FROM dim_emp_fy19
    UNION
    SELECT * FROM dim_emp_fy20
	UNION
	SELECT * FROM dim_emp_fy21
	) t1
	LEFT JOIN fact_main t2
		ON t2.emp_id = t1.emp_id
	LEFT JOIN dim_emp_jl_group_pra_no_zero t3
		ON t3.fy20_jl_group_pra = t2.fy20_jl_group_pra
	LEFT JOIN dim_emp_jl_dept_group_pra_no_zero t4
		ON t4.fy20_jl_dept_group_pra = t2.fy20_jl_dept_group_pra
ORDER BY t1.from_date

-- -----------------------------------------------------------------------------------------------------------
-- STEP 5: Fill in the null values for each employee in jl_dept_group columns from STEP 4's table.
-- -----------------------------------------------------------------------------------------------------------
-- CREATE TEMPORARY TABLE dim_emp_scd_no_null
SELECT 
	emp_id, gender, age, age_group, hire_date, from_date, end_date, yrs_since_last_hire, 
    contract_id, region_country_id, dept, job_level, perf_rating, jl_promo, 
    current_flag, employed_flag, leaver_flag, new_hire_flag, turnover_base_group, promo_base_group, 
    jl_group_pra_id, fy20_jl_group_pra, fy20_jl_group_pra_status, fy20_jl_dept_group_pra_id, 
	fy20_jl_dept_group_pra, fy20_jl_dept_group_pra_status,
    CASE 
		WHEN fy20_jl_group_pra IS NULL THEN job_level
		ELSE job_level
	END AS jl_group_pra,
    CASE
		WHEN fy20_jl_dept_group_pra IS NULL THEN CONCAT(job_level, " & ",dept)
        ELSE fy20_jl_dept_group_pra
	END AS jl_dept_group_pra
FROM dim_emp_scd


-- ---------------------------------------------------------------------------------------
-- STEP 5b: SELECT all columns, but only rename jl_group_pra and jl_dept_group_pra columns
-- ---------------------------------------------------------------------------------------
-- CREATE TEMPORARY TABLE scd_id_status_null
SELECT 
	emp_id, gender, age, age_group, hire_date, from_date, end_date, yrs_since_last_hire, 
    contract_id, region_country_id, dept, job_level, perf_rating, jl_promo, 
    current_flag, employed_flag, leaver_flag, new_hire_flag, turnover_base_group, promo_base_group, 
    jl_group_pra_id, jl_group_pra AS fy20_jl_group_pra, fy20_jl_group_pra_status, fy20_jl_dept_group_pra_id, 
	jl_dept_group_pra AS fy20_jl_dept_group_pra, fy20_jl_dept_group_pra_status
FROM dim_emp_scd_no_null


-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- STEP 6: Create our final table by using STEP 5's table to fill in remaining null values in fy20_jl_group_pra & fy20_jl_dept_group_pra through joining back to tables created in STEP 4b.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE TABLE dim_emp_main
SELECT 
	emp_id, gender, age, age_group, hire_date, from_date, end_date, yrs_since_last_hire, 
    contract_id, region_country_id, dept, job_level, perf_rating, jl_promo, 
    current_flag, employed_flag, leaver_flag, new_hire_flag, turnover_base_group, promo_base_group, 
    t2.jl_group_pra_id, t1.fy20_jl_group_pra, t2.fy20_jl_group_pra_status, 
    t3.fy20_jl_dept_group_pra_id, t1.fy20_jl_dept_group_pra, t3.fy20_jl_dept_group_pra_status
FROM scd_id_status_null t1
	LEFT JOIN dim_emp_jl_group_pra_no_zero t2
		ON t2.fy20_jl_group_pra = t1.fy20_jl_group_pra
	LEFT JOIN dim_emp_jl_dept_group_pra_no_zero t3
		ON t3.fy20_jl_dept_group_pra = t1.fy20_jl_dept_group_pra
