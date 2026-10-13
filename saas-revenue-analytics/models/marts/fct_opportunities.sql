-- Grain: one row per opportunity. Owner and territory are resolved as of the
-- close date (point-in-time), so historical bookings never move when accounts
-- are reassigned.
with opps as (
    select * from {{ ref('stg_salesforce__opportunities') }}
),
owner_at_close as (
    select o.opportunity_id, oh.owner_id
    from opps o
    join {{ ref('int_account_owner_history') }} oh
      on oh.account_id = o.account_id
     and o.close_date >= oh.valid_from
     and (oh.valid_to is null or o.close_date < oh.valid_to)
),
lines as (
    select opportunity_id,
           sum(case when p.product_family = 'Subscription' then li.total_price else 0 end) as subscription_amount,
           sum(case when p.product_family = 'Services'     then li.total_price else 0 end) as services_amount
    from {{ ref('stg_salesforce__opportunity_line_items') }} li
    join {{ ref('stg_salesforce__products') }} p on p.product_id = li.product_id
    group by 1
)
select
    o.opportunity_id,
    o.account_id,
    o.opportunity_type,
    o.stage_name,
    o.is_won,
    o.is_closed,
    o.close_date,
    o.route_to_market,
    o.amount,
    coalesce(l.subscription_amount, 0) as subscription_amount,
    coalesce(l.services_amount, 0)     as services_amount,
    coalesce(oac.owner_id, o.owner_id) as owner_id_at_close,
    h.territory_id                     as territory_id_at_close,
    h.region_name                      as region_at_close,
    h.segment                          as segment_at_close
from opps o
left join owner_at_close oac on oac.opportunity_id = o.opportunity_id
left join lines l            on l.opportunity_id = o.opportunity_id
left join {{ ref('dim_sales_hierarchy') }} h on h.seller_id = coalesce(oac.owner_id, o.owner_id)
