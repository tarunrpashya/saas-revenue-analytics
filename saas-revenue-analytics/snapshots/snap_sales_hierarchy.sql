{% snapshot snap_sales_hierarchy %}
{{ config(
    target_schema='snapshots',
    unique_key='seller_id',
    strategy='check',
    check_cols=['territory_id', 'region_id', 'is_active']
) }}
-- Tracks seller-to-territory realignments as the sales organization changes.
select seller_id, seller_name, territory_id, region_id, is_active
from {{ ref('dim_sales_hierarchy') }}
{% endsnapshot %}
