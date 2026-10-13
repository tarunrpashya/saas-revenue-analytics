select
    id                         as user_id,
    name                       as seller_name,
    title,
    territory_id,
    cast(is_active as boolean) as is_active
from {{ ref('raw_sf_users') }}
