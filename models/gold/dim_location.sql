select
    lga_code,
    lga_name,
    suburb_name

from {{ ref('int_locations') }}