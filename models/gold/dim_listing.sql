select
    listing_id,
    host_id,
    listing_neighbourhood,
    property_type,
    room_type,
    accommodates,

    dbt_scd_id as listing_scd_id,
    dbt_valid_from,
    dbt_valid_to

from {{ ref('snap_listings') }}