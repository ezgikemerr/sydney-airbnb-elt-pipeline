select
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    host_neighbourhood,

    dbt_scd_id as host_scd_id,
    dbt_valid_from,
    dbt_valid_to

from {{ ref('snap_hosts') }}