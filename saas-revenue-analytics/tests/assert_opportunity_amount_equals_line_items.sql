-- Opportunity header amount must equal the sum of its line items.
select opportunity_id, amount, subscription_amount + services_amount as line_total
from {{ ref('fct_opportunities') }}
where abs(amount - (subscription_amount + services_amount)) > 0.01
