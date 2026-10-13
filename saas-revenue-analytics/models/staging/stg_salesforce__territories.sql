select territory_id, territory_name, region_id, region_name, segment
from {{ ref('raw_territories') }}
