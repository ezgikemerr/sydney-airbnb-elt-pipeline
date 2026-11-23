with listings as (

    select *
    from {{ ref('stg_listings') }}

),

property_lookup as (

    select
        property_id,
        property_type,
        room_type,
        accommodates
    from {{ ref('dim_property') }}

),

listing_versions as (

    select
        listing_id,
        listing_scd_id,
        dbt_valid_from,
        dbt_valid_to,
        min(dbt_valid_from) over (
            partition by listing_id
        ) as first_valid_from
    from {{ ref('dim_listing') }}

),

host_versions as (

    select
        host_id,
        host_scd_id,
        dbt_valid_from,
        dbt_valid_to,
        min(dbt_valid_from) over (
            partition by host_id
        ) as first_valid_from
    from {{ ref('dim_host') }}

)

select
    -- IDs
    l.listing_id,
    l.host_id,
    p.property_id,
    lv.listing_scd_id,
    hv.host_scd_id,
    l.scrape_id,
    l.scraped_date,

    -- Metrics
    l.price,
    l.availability_30,
    l.number_of_reviews,
    l.review_scores_rating,
    l.review_scores_accuracy,
    l.review_scores_cleanliness,
    l.review_scores_checkin,
    l.review_scores_communication,
    l.review_scores_value,

    case
        when l.has_availability = 't' then 1
        else 0
    end as is_active,

    case
        when l.has_availability = 't'
        then 30 - l.availability_30
        else 0
    end as number_of_stays,

    case
        when l.has_availability = 't'
        then (30 - l.availability_30) * l.price
        else 0
    end as estimated_revenue

from listings l

left join property_lookup p
    on l.property_type = p.property_type
   and l.room_type = p.room_type
   and l.accommodates = p.accommodates

-- SCD2 listing:
-- use the version valid at the fact date;
-- if the fact predates the first known version, use the earliest known version
left join listing_versions lv
    on l.listing_id = lv.listing_id
   and (
        (
            l.scraped_date >= lv.dbt_valid_from
            and (
                l.scraped_date < lv.dbt_valid_to
                or lv.dbt_valid_to is null
            )
        )
        or (
            l.scraped_date < lv.first_valid_from
            and lv.dbt_valid_from = lv.first_valid_from
        )
   )

-- SCD2 host:
-- use the version valid at the fact date;
-- if the fact predates the first known version, use the earliest known version
left join host_versions hv
    on l.host_id = hv.host_id
   and (
        (
            l.scraped_date >= hv.dbt_valid_from
            and (
                l.scraped_date < hv.dbt_valid_to
                or hv.dbt_valid_to is null
            )
        )
        or (
            l.scraped_date < hv.first_valid_from
            and hv.dbt_valid_from = hv.first_valid_from
        )
   )