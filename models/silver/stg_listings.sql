with source as (

    select *
    from {{ source('bronze', 'raw_listings') }}

),

cleaned as (

    select
        listing_id,
        scrape_id,
        scraped_date::date as scraped_date,
        host_id,
        host_name,
        to_date(host_since, 'DD/MM/YYYY') as host_since,
        host_is_superhost,
        host_neighbourhood,
        listing_neighbourhood,
        property_type,
        room_type,
        accommodates,
        price,
        has_availability,
        availability_30,
        number_of_reviews,
        review_scores_rating,
        review_scores_accuracy,
        review_scores_cleanliness,
        review_scores_checkin,
        review_scores_communication,
        review_scores_value

    from source

)

select *
from cleaned