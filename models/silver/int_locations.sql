with suburb_mapping as (

    select
        lga_name,
        suburb_name
    from {{ ref('stg_lga_suburb') }}

),

lga_codes as (

    select
        lga_code,
        lga_name
    from {{ ref('stg_lga_code') }}

)

select distinct
    l.lga_code,
    s.lga_name,
    s.suburb_name

from suburb_mapping s

left join lga_codes l
    on lower(trim(s.lga_name)) = lower(trim(l.lga_name))