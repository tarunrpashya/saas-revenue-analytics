{% snapshot snap_sf_accounts %}
{{ config(
    target_schema='snapshots',
    unique_key='account_id',
    strategy='check',
    check_cols=['current_owner_id', 'route_to_market'],
    invalidate_hard_deletes=True
) }}
-- Captures owner and route-to-market changes each run so any report can be
-- rebuilt as of the day it was published.
select account_id, account_name, current_owner_id, route_to_market
from {{ ref('stg_salesforce__accounts') }}
{% endsnapshot %}
