select
    id                         as account_id,
    name                       as account_name,
    industry,
    owner_id                   as current_owner_id,
    route_to_market,
    cast(created_date as date) as created_date
from {{ ref('raw_sf_accounts') }}
