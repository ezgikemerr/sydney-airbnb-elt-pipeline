{{ config(materialized='view') }}

with fact_with_host as (

    select
        f.scraped_date,
        date_trunc('month', f.scraped_date)::date as month_year,

        f.host_id,
        f.is_active,
        f.estimated_revenue,

        dh.host_neighbourhood

    from {{ ref('fact_listings') }} f

    -- SCD2: exact host version already identified in the fact table
    left join {{ ref('dim_host') }} dh
        on f.host_scd_id = dh.host_scd_id

),

with_lga as (

    select
        f.month_year,
        f.host_id,
        f.is_active,
        f.estimated_revenue,

        l.lga_name as host_neighbourhood_lga

    from fact_with_host f

    left join {{ ref('dim_location') }} l
        on lower(trim(f.host_neighbourhood))
         = lower(trim(l.suburb_name))

),

monthly_metrics as (

    select
        host_neighbourhood_lga,
        month_year,

        count(distinct host_id) as distinct_hosts,

        avg(estimated_revenue) filter (
            where is_active = 1
        ) as avg_estimated_revenue_per_active_listing,

        sum(estimated_revenue) filter (
            where is_active = 1
        )
        / nullif(count(distinct host_id), 0)
        as estimated_revenue_per_host

    from with_lga

    where host_neighbourhood_lga is not null

    group by
        host_neighbourhood_lga,
        month_year

)

select
    host_neighbourhood_lga,
    month_year,
    distinct_hosts,
    avg_estimated_revenue_per_active_listing,
    estimated_revenue_per_host

from monthly_metrics

order by
    host_neighbourhood_lga,
    month_year