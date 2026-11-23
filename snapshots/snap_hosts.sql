{% snapshot snap_hosts %}

{{
    config(
        target_schema='silver',
        unique_key='host_id',
        strategy='timestamp',
        updated_at='scraped_date'
    )
}}

select
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    host_neighbourhood,
    scraped_date
from {{ ref('int_hosts') }}

{% endsnapshot %}