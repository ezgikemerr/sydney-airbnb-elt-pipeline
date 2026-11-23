/*
Part 1 - Initial Raw Data Load

This script creates the Bronze schema and raw PostgreSQL tables required
for the initial Airflow data load.

The initial load includes:
- Sydney Airbnb listings for May 2020
- 2016 Census G01 data
- 2016 Census G02 data
- NSW LGA code mapping
- NSW LGA to suburb mapping

The source files are loaded from the Cloud Composer storage bucket into
the Bronze schema using an Airflow DAG with no scheduled interval.
*/


CREATE SCHEMA IF NOT EXISTS bronze;

CREATE TABLE IF NOT EXISTS bronze.raw_listings (
    listing_id BIGINT,
    scrape_id BIGINT,
    scraped_date TEXT,
    host_id BIGINT,
    host_name TEXT,
    host_since TEXT,
    host_is_superhost TEXT,
    host_neighbourhood TEXT,
    listing_neighbourhood TEXT,
    property_type TEXT,
    room_type TEXT,
    accommodates INTEGER,
    price NUMERIC,
    has_availability TEXT,
    availability_30 INTEGER,
    number_of_reviews INTEGER,
    review_scores_rating NUMERIC,
    review_scores_accuracy NUMERIC,
    review_scores_cleanliness NUMERIC,
    review_scores_checkin NUMERIC,
    review_scores_communication NUMERIC,
    review_scores_value NUMERIC
);



CREATE TABLE IF NOT EXISTS bronze.raw_census_g01 (
    lga_code_2016 TEXT,
    tot_p_m INTEGER,
    tot_p_f INTEGER,
    tot_p_p INTEGER,
    age_0_4_yr_m INTEGER,
    age_0_4_yr_f INTEGER,
    age_0_4_yr_p INTEGER,
    age_5_14_yr_m INTEGER,
    age_5_14_yr_f INTEGER,
    age_5_14_yr_p INTEGER,
    age_15_19_yr_m INTEGER,
    age_15_19_yr_f INTEGER,
    age_15_19_yr_p INTEGER,
    age_20_24_yr_m INTEGER,
    age_20_24_yr_f INTEGER,
    age_20_24_yr_p INTEGER,
    age_25_34_yr_m INTEGER,
    age_25_34_yr_f INTEGER,
    age_25_34_yr_p INTEGER,
    age_35_44_yr_m INTEGER,
    age_35_44_yr_f INTEGER,
    age_35_44_yr_p INTEGER,
    age_45_54_yr_m INTEGER,
    age_45_54_yr_f INTEGER,
    age_45_54_yr_p INTEGER,
    age_55_64_yr_m INTEGER,
    age_55_64_yr_f INTEGER,
    age_55_64_yr_p INTEGER,
    age_65_74_yr_m INTEGER,
    age_65_74_yr_f INTEGER,
    age_65_74_yr_p INTEGER,
    age_75_84_yr_m INTEGER,
    age_75_84_yr_f INTEGER,
    age_75_84_yr_p INTEGER,
    age_85ov_m INTEGER,
    age_85ov_f INTEGER,
    age_85ov_p INTEGER,
    counted_census_night_home_m INTEGER,
    counted_census_night_home_f INTEGER,
    counted_census_night_home_p INTEGER,
    count_census_nt_ewhere_aust_m INTEGER,
    count_census_nt_ewhere_aust_f INTEGER,
    count_census_nt_ewhere_aust_p INTEGER,
    indigenous_psns_aboriginal_m INTEGER,
    indigenous_psns_aboriginal_f INTEGER,
    indigenous_psns_aboriginal_p INTEGER,
    indig_psns_torres_strait_is_m INTEGER,
    indig_psns_torres_strait_is_f INTEGER,
    indig_psns_torres_strait_is_p INTEGER,
    indig_bth_abor_torres_st_is_m INTEGER,
    indig_bth_abor_torres_st_is_f INTEGER,
    indig_bth_abor_torres_st_is_p INTEGER,
    indigenous_p_tot_m INTEGER,
    indigenous_p_tot_f INTEGER,
    indigenous_p_tot_p INTEGER,
    birthplace_australia_m INTEGER,
    birthplace_australia_f INTEGER,
    birthplace_australia_p INTEGER,
    birthplace_elsewhere_m INTEGER,
    birthplace_elsewhere_f INTEGER,
    birthplace_elsewhere_p INTEGER,
    lang_spoken_home_eng_only_m INTEGER,
    lang_spoken_home_eng_only_f INTEGER,
    lang_spoken_home_eng_only_p INTEGER,
    lang_spoken_home_oth_lang_m INTEGER,
    lang_spoken_home_oth_lang_f INTEGER,
    lang_spoken_home_oth_lang_p INTEGER,
    australian_citizen_m INTEGER,
    australian_citizen_f INTEGER,
    australian_citizen_p INTEGER,
    age_psns_att_educ_inst_0_4_m INTEGER,
    age_psns_att_educ_inst_0_4_f INTEGER,
    age_psns_att_educ_inst_0_4_p INTEGER,
    age_psns_att_educ_inst_5_14_m INTEGER,
    age_psns_att_educ_inst_5_14_f INTEGER,
    age_psns_att_educ_inst_5_14_p INTEGER,
    age_psns_att_edu_inst_15_19_m INTEGER,
    age_psns_att_edu_inst_15_19_f INTEGER,
    age_psns_att_edu_inst_15_19_p INTEGER,
    age_psns_att_edu_inst_20_24_m INTEGER,
    age_psns_att_edu_inst_20_24_f INTEGER,
    age_psns_att_edu_inst_20_24_p INTEGER,
    age_psns_att_edu_inst_25_ov_m INTEGER,
    age_psns_att_edu_inst_25_ov_f INTEGER,
    age_psns_att_edu_inst_25_ov_p INTEGER,
    high_yr_schl_comp_yr_12_eq_m INTEGER,
    high_yr_schl_comp_yr_12_eq_f INTEGER,
    high_yr_schl_comp_yr_12_eq_p INTEGER,
    high_yr_schl_comp_yr_11_eq_m INTEGER,
    high_yr_schl_comp_yr_11_eq_f INTEGER,
    high_yr_schl_comp_yr_11_eq_p INTEGER,
    high_yr_schl_comp_yr_10_eq_m INTEGER,
    high_yr_schl_comp_yr_10_eq_f INTEGER,
    high_yr_schl_comp_yr_10_eq_p INTEGER,
    high_yr_schl_comp_yr_9_eq_m INTEGER,
    high_yr_schl_comp_yr_9_eq_f INTEGER,
    high_yr_schl_comp_yr_9_eq_p INTEGER,
    high_yr_schl_comp_yr_8_belw_m INTEGER,
    high_yr_schl_comp_yr_8_belw_f INTEGER,
    high_yr_schl_comp_yr_8_belw_p INTEGER,
    high_yr_schl_comp_d_n_g_sch_m INTEGER,
    high_yr_schl_comp_d_n_g_sch_f INTEGER,
    high_yr_schl_comp_d_n_g_sch_p INTEGER,
    count_psns_occ_priv_dwgs_m INTEGER,
    count_psns_occ_priv_dwgs_f INTEGER,
    count_psns_occ_priv_dwgs_p INTEGER,
    count_persons_other_dwgs_m INTEGER,
    count_persons_other_dwgs_f INTEGER,
    count_persons_other_dwgs_p INTEGER
);


CREATE TABLE IF NOT EXISTS bronze.raw_census_g02 (
    lga_code_2016 TEXT,
    median_age_persons INTEGER,
    median_mortgage_repay_monthly INTEGER,
    median_tot_prsnl_inc_weekly INTEGER,
    median_rent_weekly INTEGER,
    median_tot_fam_inc_weekly INTEGER,
    average_num_psns_per_bedroom NUMERIC,
    median_tot_hhd_inc_weekly INTEGER,
    average_household_size NUMERIC
);


CREATE TABLE IF NOT EXISTS bronze.raw_lga_code (
    lga_code INTEGER,
    lga_name TEXT
);



CREATE TABLE IF NOT EXISTS bronze.raw_lga_suburb (
    lga_name TEXT,
    suburb_name TEXT,
    "unnamed: 2" TEXT,
    "unnamed: 3" TEXT,
    "unnamed: 4" TEXT,
    "unnamed: 5" TEXT,
    "unnamed: 6" TEXT,
    "unnamed: 7" TEXT,
    "unnamed: 8" TEXT,
    "unnamed: 9" TEXT,
    "unnamed: 10" TEXT,
    "unnamed: 11" TEXT,
    "unnamed: 12" TEXT,
    "unnamed: 13" TEXT,
    "unnamed: 14" TEXT,
    "unnamed: 15" TEXT,
    "unnamed: 16" TEXT,
    "unnamed: 17" TEXT,
    "unnamed: 18" TEXT,
    "unnamed: 19" TEXT,
    "unnamed: 20" TEXT,
    "unnamed: 21" TEXT,
    "unnamed: 22" TEXT,
    "unnamed: 23" TEXT,
    "unnamed: 24" TEXT,
    "unnamed: 25" TEXT,
    "unnamed: 26" TEXT
);


SELECT COUNT(*) FROM bronze.raw_listings;
SELECT COUNT(*) FROM bronze.raw_census_g01;
SELECT COUNT(*) FROM bronze.raw_census_g02;
SELECT COUNT(*) FROM bronze.raw_lga_code;
SELECT COUNT(*) FROM bronze.raw_lga_suburb;


SELECT
    table_name,
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'bronze'
  AND table_name IN (
      'raw_listings',
      'raw_census_g01',
      'raw_census_g02',
      'raw_lga_code',
      'raw_lga_suburb'
  )
GROUP BY table_name
ORDER BY table_name;
