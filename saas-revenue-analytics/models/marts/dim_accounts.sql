select
    a.account_id,
    a.account_name,
    a.industry,
    a.route_to_market,
    a.created_date,
    a.current_owner_id,
    h.seller_name     as current_owner_name,
    h.territory_id    as current_territory_id,
    h.region_name     as current_region_name
from {{ ref('stg_salesforce__accounts') }} a
left join {{ ref('dim_sales_hierarchy') }} h on h.seller_id = a.current_owner_id
