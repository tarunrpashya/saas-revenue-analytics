select
    id                           as opportunity_id,
    account_id,
    owner_id,
    type                         as opportunity_type,
    stage_name,
    stage_name = 'Closed Won'    as is_won,
    stage_name like 'Closed%'    as is_closed,
    {{ money('amount') }}        as amount,
    cast(close_date as date)     as close_date,
    route_to_market
from {{ ref('raw_sf_opportunities') }}
