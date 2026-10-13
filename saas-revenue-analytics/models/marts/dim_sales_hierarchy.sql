-- Seller -> territory -> region -> segment
select
    u.user_id         as seller_id,
    u.seller_name,
    u.is_active,
    t.territory_id,
    t.territory_name,
    t.region_id,
    t.region_name,
    t.segment
from {{ ref('stg_salesforce__users') }} u
left join {{ ref('stg_salesforce__territories') }} t on t.territory_id = u.territory_id
