-- Dataset behind a weekly forecast pack: open pipeline by region and stage with
-- stage-weighted forecast, alongside closed-won bookings for the same quarter.
with opps as (select * from {{ ref('fct_opportunities') }}),
weights as (
    select 'Prospecting' as stage_name, 0.10 as probability union all
    select 'Proposal',  0.40 union all
    select 'Commit',    0.80 union all
    select 'Closed Won', 1.00 union all
    select 'Closed Lost', 0.00
)
select
    {{ dbt.date_trunc('quarter', 'o.close_date') }} as fiscal_quarter,
    o.region_at_close                               as region,
    o.route_to_market,
    o.stage_name,
    count(*)                                        as opportunity_count,
    sum(o.amount)                                   as pipeline_amount,
    sum(o.amount * w.probability)                   as weighted_forecast,
    sum(case when o.is_won then o.amount else 0 end) as closed_won_amount
from opps o
join weights w on w.stage_name = o.stage_name
group by 1, 2, 3, 4
