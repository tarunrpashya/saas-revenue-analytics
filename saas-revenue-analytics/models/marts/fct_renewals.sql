-- Grain: one row per expiring subscription term, with its renewal outcome.
with expiring as (
    select account_id,
           max(end_date)      as term_end_date,
           sum(annual_amount) as expiring_arr
    from {{ ref('stg_billing__subscriptions') }}
    group by account_id, opportunity_id
),
renewal_opps as (
    select account_id, close_date, is_won, is_closed, subscription_amount
    from {{ ref('fct_opportunities') }}
    where opportunity_type = 'Renewal'
)
select
    {{ dbt.concat(["e.account_id", "'-'", "cast(e.term_end_date as varchar)"]) }} as renewal_id,
    e.account_id,
    e.term_end_date,
    e.expiring_arr,
    r.close_date                                  as renewal_close_date,
    coalesce(r.subscription_amount, 0)            as renewed_arr,
    case
        when r.is_won                       then 'renewed'
        when r.is_closed                    then 'churned'
        when r.close_date is not null       then 'open'
        when e.term_end_date < current_date then 'churned'
        else 'upcoming'
    end as renewal_status
from expiring e
left join renewal_opps r
  on r.account_id = e.account_id
 and r.close_date between {{ dbt.dateadd('day', -60, 'e.term_end_date') }} and {{ dbt.dateadd('day', 30, 'e.term_end_date') }}
