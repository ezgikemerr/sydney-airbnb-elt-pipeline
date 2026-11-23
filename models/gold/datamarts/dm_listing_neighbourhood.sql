{{ config(materialized='view') }}

with fact_with_dimensions as (

    select
        f.scraped_date,
        date_trunc('month', f.scraped_date)::date as month_year,

        dl.listing_neighbourhood,

        f.listing_id,
        f.host_id,
        f.price,
        f.is_active,
        f.number_of_stays,
        f.estimated_revenue,
        f.review_scores_rating,

        dh.host_is_superhost

    from {{ ref('fact_listings') }} f

    -- SCD2: exact listing version already identified in the fact table
    left join {{ ref('dim_listing') }} dl
        on f.listing_scd_id = dl.listing_scd_id

    -- SCD2: exact host version already identified in the fact table
    left join {{ ref('dim_host') }} dh
        on f.host_scd_id = dh.host_scd_id

),

monthly_metrics as (

    select
        listing_neighbourhood,
        month_year,

        count(*) as total_listings,

        count(*) filter (
            where is_active = 1
        ) as active_listings,

        count(*) filter (
            where is_active = 0
        ) as inactive_listings,

        100.0
        * count(*) filter (where is_active = 1)
        / nullif(count(*), 0)
        as active_listing_rate,

        min(price) filter (
            where is_active = 1
        ) as min_price_active,

        max(price) filter (
            where is_active = 1
        ) as max_price_active,

        percentile_cont(0.5) within group (
            order by price
        ) filter (
            where is_active = 1
        ) as median_price_active,

        avg(price) filter (
            where is_active = 1
        ) as avg_price_active,

        count(distinct host_id) as distinct_hosts,

        100.0
        * count(distinct host_id) filter (
            where host_is_superhost = 't'
        )
        / nullif(count(distinct host_id), 0)
        as superhost_rate,

        avg(review_scores_rating) filter (
            where is_active = 1
        ) as avg_review_scores_rating_active,

        sum(number_of_stays) filter (
            where is_active = 1
        ) as total_stays,

        avg(estimated_revenue) filter (
            where is_active = 1
        ) as avg_estimated_revenue_per_active_listing

    from fact_with_dimensions

    where listing_neighbourhood is not null

    group by
        listing_neighbourhood,
        month_year

),

with_previous_month as (

    select
        *,

        lag(active_listings) over (
            partition by listing_neighbourhood
            order by month_year
        ) as previous_active_listings,

        lag(inactive_listings) over (
            partition by listing_neighbourhood
            order by month_year
        ) as previous_inactive_listings

    from monthly_metrics

)

select
    listing_neighbourhood,
    month_year,

    active_listing_rate,

    min_price_active,
    max_price_active,
    median_price_active,
    avg_price_active,

    distinct_hosts,
    superhost_rate,
    avg_review_scores_rating_active,

    100.0
    * (active_listings - previous_active_listings)
    / nullif(previous_active_listings, 0)
    as active_listings_pct_change,

    100.0
    * (inactive_listings - previous_inactive_listings)
    / nullif(previous_inactive_listings, 0)
    as inactive_listings_pct_change,

    total_stays,
    avg_estimated_revenue_per_active_listing

from with_previous_month

order by
    listing_neighbourhood,
    month_year