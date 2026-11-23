with source as (

    select *
    from {{ source('bronze', 'raw_lga_suburb') }}

)

select
    trim(lga_name) as lga_name,
    trim(suburb_name) as suburb_name
from source
where lga_name is not null
  and suburb_name is not null