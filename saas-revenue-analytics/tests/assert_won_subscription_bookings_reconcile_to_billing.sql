-- Reconciliation: every closed-won subscription booking in Salesforce must match
-- what billing invoiced for that opportunity (to the cent). Returns mismatches.
with crm as (
    select opportunity_id, subscription_amount
    from {{ ref('fct_opportunities') }}
    where is_won and subscription_amount > 0
),
billing as (
    select opportunity_id, sum(annual_amount) as billed_amount
    from {{ ref('stg_billing__subscriptions') }}
    group by 1
)
select crm.opportunity_id, crm.subscription_amount, billing.billed_amount
from crm
left join billing on billing.opportunity_id = crm.opportunity_id
where abs(crm.subscription_amount - coalesce(billing.billed_amount, 0)) > 0.01
