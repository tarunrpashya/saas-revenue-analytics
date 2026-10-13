-- Point-in-time integrity: an account can only have one owner on any date.
select a.account_id, a.valid_from, b.valid_from as overlapping_from
from {{ ref('int_account_owner_history') }} a
join {{ ref('int_account_owner_history') }} b
  on a.account_id = b.account_id
 and a.account_owner_period_id <> b.account_owner_period_id
 and a.valid_from < coalesce(b.valid_to, cast('9999-12-31' as date))
 and b.valid_from < coalesce(a.valid_to, cast('9999-12-31' as date))
