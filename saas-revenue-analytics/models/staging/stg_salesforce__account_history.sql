-- Salesforce AccountHistory: one row per tracked field change
select
    id                         as account_history_id,
    account_id,
    field,
    old_value,
    new_value,
    cast(created_date as date) as changed_date
from {{ ref('raw_sf_account_history') }}
where field = 'Owner'
