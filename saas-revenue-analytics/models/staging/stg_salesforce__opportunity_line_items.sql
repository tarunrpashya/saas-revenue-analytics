select
    id                         as opportunity_line_item_id,
    opportunity_id,
    product_id,
    quantity,
    {{ money('unit_price') }}  as unit_price,
    {{ money('total_price') }} as total_price
from {{ ref('raw_sf_opportunity_line_items') }}
