select
    property_id,
    property_type,
    room_type,
    accommodates

from {{ ref('int_properties') }}