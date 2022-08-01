# After importing table into MySQL, we separate the tables into its relevant dimensions and fact tables.

# Main table
SELECT * FROM fact_diversity            -- This includes all columns except 'rand' and the three geographic columns (broad_region, region_group, country).

# Regions dimensions table
SELECT * FROM dim_emp_regions_country   -- This table was previously created in excel and imported in MySQL.

# Create employee dimension table
-- Columns were manually selected from main table to order them so looking at the data becomes easier whenever we query the table
SELECT 
	emp_id, gender, age_group, fy20_jul_age,
    last_hire_date, yrs_since_last_hire, contract_id, region_country_id, leaver_fy,
    fy19_perf_rating, fy20_new_hire, fy20_07_01_dept, fy20_last_dept, fy20_base_group_turnover, fy20_leaver,
    fy20_jul_jl_time, fy20_perf_rating, fy20_jl_bf_promo, fy20_promo, fy20_jl_aft_promo, fy21_promo_base_group,
    fy21_promo, fy21_jl_aft_promo
FROM fact_diversity

# Create fact table
SELECT 
	emp_id, 
	fy20_jl_group_pra, fy20_jl_group_pra_status,
    fy20_jl_dept_group_pra, fy20_jl_dept_group_pra_status,
    target_hire_balance
FROM fact_diversity
