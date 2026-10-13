-- Grain: one row per account per month with active subscription ARR, plus
-- new / expansion / contraction / churn movement vs the prior month.
with months as (
    select cast(month_start as date) as month_start from {{ ref('calendar_months') }}
),
arr as (
    select m.month_start, s.account_id, sum(s.annual_amount) as arr
    from months m
    join {{ ref('stg_billing__subscriptions') }} s
      on s.start_date <= m.month_start and s.end_date >= m.month_start
    group by 1, 2
),
accounts_months as (
    select m.month_start, a.account_id
    from months m
    cross join (select distinct account_id from arr) a
),
filled as (
    select am.month_start, am.account_id, coalesce(arr.arr, 0) as arr
    from accounts_months am
    left join arr on arr.account_id = am.account_id and arr.month_start = am.month_start
),
with_prior as (
    select *, lag(arr, 1, 0) over (partition by account_id order by month_start) as prior_arr
    from filled
)
select
    {{ dbt.concat(["account_id", "'-'", "cast(month_start as varchar)"]) }} as account_month_id,
    month_start,
    account_id,
    arr,
    prior_arr,
    case
        when prior_arr = 0 and arr > 0     then 'new'
        when prior_arr > 0 and arr = 0     then 'churn'
        when arr > prior_arr               then 'expansion'
        when arr < prior_arr               then 'contraction'
        else 'flat'
    end as arr_movement,
    arr - prior_arr as arr_change
from with_prior
where arr > 0 or prior_arr > 0
