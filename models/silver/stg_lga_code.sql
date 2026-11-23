with source as (

    select *
    from {{ source('bronze', 'raw_lga_code') }}

)

select
    lga_code,
    trim(lga_name) as lga_name
from source