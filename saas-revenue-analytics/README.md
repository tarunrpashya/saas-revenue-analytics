# SaaS Revenue Analytics (dbt + Snowflake)

A dbt project that models Salesforce-style CRM data and subscription billing into
tested, documented revenue models: bookings, ARR, renewals, account ownership over
time, and the dataset behind a weekly forecast pack. All data is synthetic.

Runs on **Snowflake** (target warehouse) or **DuckDB** (local and CI) with no code changes.

## What it shows

| Problem | How it is solved |
|---|---|
| Who owned an account when a deal closed? | `int_account_owner_history` turns Salesforce AccountHistory into effective-dated ownership periods; `fct_opportunities` joins on the close date, so historical bookings never move when accounts are reassigned. |
| Reproduce a number as it stood on the day it was published | dbt snapshots `snap_sf_accounts` and `snap_sales_hierarchy` capture owner, route-to-market and territory changes on every run. |
| Do Salesforce bookings match what Finance billed? | Singular test `assert_won_subscription_bookings_reconcile_to_billing` fails the build on any mismatch. |
| ARR and its movement | `fct_arr_monthly`: one row per account per month with new / expansion / contraction / churn. |
| Renewals | `fct_renewals`: each expiring term matched to its renewal opportunity (renewed, churned, open, upcoming). |
| Weekly forecast pack | `rpt_weekly_forecast_pack`: pipeline, stage-weighted forecast and closed-won by quarter, region, route to market (direct / partner) and stage. |

## Model layers

```
seeds (Salesforce + billing replicas; in production these are Fivetran-loaded sources with freshness checks)
  -> staging      stg_salesforce__*, stg_billing__subscriptions   (rename, cast, one row per source record)
  -> intermediate int_account_owner_history                        (effective-dated ownership)
  -> marts        dim_accounts, dim_sales_hierarchy, fct_opportunities,
                  fct_arr_monthly, fct_renewals, rpt_weekly_forecast_pack
snapshots         snap_sf_accounts, snap_sales_hierarchy
```

Every model has a stated grain and a unique key test. 44 data tests cover keys,
relationships, accepted values, ownership-period overlap, header-to-line totals,
and CRM-to-billing reconciliation.

## Run it

```bash
pip install dbt-duckdb            # or dbt-snowflake
cp profiles.example.yml ~/.dbt/profiles.yml
python scripts/generate_seeds.py  # optional: regenerate synthetic data
dbt build                         # seeds, models, snapshots and tests
dbt docs generate && dbt docs serve
```

For Snowflake: set `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, then `dbt build --target snowflake`.

CI (GitHub Actions) runs `dbt build` on every pull request.
