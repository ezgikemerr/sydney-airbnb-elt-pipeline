with listings as (

    select *
    from {{ ref('stg_listings') }}

),

properties as (

    select distinct
        property_type,
        room_type,
        accommodates

    from listings

    where property_type is not null
      and room_type is not null
      and accommodates is not null

)

select
    row_number() over (
        order by property_type, room_type, accommodates
    ) as property_id,
    property_type,
    room_type,
    accommodates

from properties