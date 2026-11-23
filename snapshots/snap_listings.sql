{% snapshot snap_listings %}

{{
    config(
        target_schema='silver',
        unique_key='listing_id',
        strategy='timestamp',
        updated_at='scraped_date'
    )
}}

select
    listing_id,
    host_id,
    listing_neighbourhood,
    property_type,
    room_type,
    accommodates,
    scraped_date
from {{ ref('int_listings') }}

{% endsnapshot %}