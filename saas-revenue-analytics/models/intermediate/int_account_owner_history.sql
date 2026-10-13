-- Effective-dated account ownership: one row per account per ownership period.
-- Built from Salesforce AccountHistory so any number can be attributed to the
-- owner as of the date it happened, not today's owner.
with changes as (
    select account_id, old_value as owner_id, new_value, changed_date
    from {{ ref('stg_salesforce__account_history') }}
),
accounts as (
    select account_id, current_owner_id, created_date
    from {{ ref('stg_salesforce__accounts') }}
),
periods as (
    -- original owner: from account creation until first change (or forever)
    select a.account_id,
           coalesce(first_change.owner_id, a.current_owner_id) as owner_id,
           a.created_date                                     as valid_from,
           first_change.changed_date                          as valid_to
    from accounts a
    left join (
        select account_id, owner_id, changed_date,
               row_number() over (partition by account_id order by changed_date) as rn
        from changes
    ) first_change on first_change.account_id = a.account_id and first_change.rn = 1

    union all

    -- each subsequent owner: from their change date until the next change
    select account_id,
           new_value                                                             as owner_id,
           changed_date                                                          as valid_from,
           lead(changed_date) over (partition by account_id order by changed_date) as valid_to
    from changes
)
select
    {{ dbt.concat(["account_id", "'-'", "cast(valid_from as varchar)"]) }} as account_owner_period_id,
    account_id,
    owner_id,
    valid_from,
    valid_to,
    valid_to is null as is_current
from periods
