with source as (

    select *
    from {{ source('bronze', 'raw_census_g02') }}

)

select
    replace(upper(trim(lga_code_2016)), 'LGA', '') as lga_code_2016,
    median_age_persons,
    median_mortgage_repay_monthly,
    median_tot_prsnl_inc_weekly,
    median_rent_weekly,
    median_tot_fam_inc_weekly,
    average_num_psns_per_bedroom,
    median_tot_hhd_inc_weekly,
    average_household_size
from source
where lga_code_2016 is not null