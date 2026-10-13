select
    id                              as product_id,
    name                            as product_name,
    family                          as product_family,
    {{ money('list_price_annual') }} as list_price_annual
from {{ ref('raw_sf_products') }}
