with listings as (

    select *
    from {{ ref('stg_listings') }}
    where host_id is not null

),

host_attributes as (

    select
        host_id,
        host_name,
        host_since,
        host_is_superhost,
        host_neighbourhood,
        scraped_date,

        row_number() over (
            partition by host_id
            order by scraped_date desc
        ) as row_num

    from listings

)

select
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    host_neighbourhood,
    scraped_date

from host_attributes

where row_num = 1