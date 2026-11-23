with listings as (

    select *
    from {{ ref('stg_listings') }}

),

latest_listings as (

    select
        listing_id,
        host_id,
        listing_neighbourhood,
        property_type,
        room_type,
        accommodates,
        scraped_date,

        row_number() over (
            partition by listing_id
            order by scraped_date desc
        ) as row_num

    from listings
    where listing_id is not null

)

select
    listing_id,
    host_id,
    listing_neighbourhood,
    property_type,
    room_type,
    accommodates,
    scraped_date
from latest_listings
where row_num = 1