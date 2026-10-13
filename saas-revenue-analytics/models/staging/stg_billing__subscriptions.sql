select
    subscription_id,
    account_id,
    opportunity_id,
    product_id,
    quantity,
    {{ money('annual_amount') }} as annual_amount,
    cast(start_date as date)     as start_date,
    cast(end_date as date)       as end_date
from {{ ref('raw_billing_subscriptions') }}
