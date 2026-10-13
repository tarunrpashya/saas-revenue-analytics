"""Generate synthetic Salesforce-style CRM + billing data for the dbt project.
Deterministic (seeded) so tests are reproducible. All data is fictional."""
import csv, random, datetime as dt, os, sys

random.seed(42)
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '..', 'seeds')
os.makedirs(OUT, exist_ok=True)

def w(name, header, rows):
    with open(os.path.join(OUT, name + '.csv'), 'w', newline='') as f:
        cw = csv.writer(f); cw.writerow(header); cw.writerows(rows)

# Sales hierarchy: region -> territory, sellers own territories
regions = [('R1', 'Americas'), ('R2', 'EMEA'), ('R3', 'APAC')]
territories = []
tid = 0
for rid, rname in regions:
    for seg in ['Enterprise', 'Commercial']:
        tid += 1
        territories.append((f'T{tid:02d}', f'{rname} {seg}', rid, rname, seg))
w('raw_territories', ['territory_id', 'territory_name', 'region_id', 'region_name', 'segment'], territories)

users = []
for i in range(1, 13):
    t = territories[(i - 1) % len(territories)]
    users.append((f'U{i:03d}', f'Seller {i:02d}', 'Account Executive', t[0], 'true'))
w('raw_sf_users', ['id', 'name', 'title', 'territory_id', 'is_active'], users)

products = [('P01', 'Design Suite', 'Subscription', 1200), ('P02', 'Build Cloud', 'Subscription', 2400),
            ('P03', 'Analytics Add-on', 'Subscription', 600), ('P04', 'Onboarding Services', 'Services', 5000)]
w('raw_sf_products', ['id', 'name', 'family', 'list_price_annual'], products)

accounts, acct_history = [], []
start = dt.date(2024, 1, 1)
for i in range(1, 61):
    owner = random.choice(users)
    created = start + dt.timedelta(days=random.randint(0, 200))
    channel = random.choice(['Direct', 'Direct', 'Partner'])
    accounts.append((f'A{i:04d}', f'Customer {i:03d}', random.choice(['Manufacturing', 'AEC', 'Media']), owner[0], channel, created.isoformat()))
    # some accounts change owner over time (reassignment / territory realignment)
    if random.random() < 0.35:
        new_owner = random.choice([u for u in users if u[0] != owner[0]])
        changed = created + dt.timedelta(days=random.randint(120, 500))
        acct_history.append((f'H{len(acct_history)+1:04d}', f'A{i:04d}', 'Owner', owner[0], new_owner[0], changed.isoformat()))
w('raw_sf_accounts', ['id', 'name', 'industry', 'owner_id', 'route_to_market', 'created_date'],
  [(a[0], a[1], a[2], next((h[4] for h in acct_history if h[1] == a[0]), a[3]), a[4], a[5]) for a in accounts])
w('raw_sf_account_history', ['id', 'account_id', 'field', 'old_value', 'new_value', 'created_date'], acct_history)

opps, lines, subs = [], [], []
oid = lid = sid = 0
for a in accounts:
    d = dt.date.fromisoformat(a[5]) + dt.timedelta(days=random.randint(5, 60))
    term_start = d
    for cycle in range(random.randint(1, 3)):
        oid += 1
        otype = 'New Business' if cycle == 0 else 'Renewal'
        close = term_start - dt.timedelta(days=random.randint(0, 20))
        won = random.random() < (0.7 if cycle == 0 else 0.85)
        stage = 'Closed Won' if won else 'Closed Lost'
        if close > dt.date(2026, 9, 1):
            stage = random.choice(['Prospecting', 'Proposal', 'Commit'])
        amount = 0
        chosen = random.sample(products[:3], random.randint(1, 2)) + ([products[3]] if cycle == 0 and random.random() < 0.4 else [])
        for p in chosen:
            lid += 1
            qty = random.randint(5, 50) if p[2] == 'Subscription' else 1
            price = round(p[3] * random.uniform(0.8, 1.0), 2)
            total = round(qty * price, 2); amount += total
            lines.append((f'L{lid:05d}', f'O{oid:05d}', p[0], qty, price, total))
            if stage == 'Closed Won' and p[2] == 'Subscription':
                sid += 1
                end = term_start + dt.timedelta(days=364)
                subs.append((f'S{sid:05d}', a[0], f'O{oid:05d}', p[0], qty, total, term_start.isoformat(), end.isoformat()))
        opps.append((f'O{oid:05d}', a[0], a[3], otype, stage, round(amount, 2), close.isoformat(), a[4]))
        if stage != 'Closed Won':
            break
        term_start = term_start + dt.timedelta(days=365)
w('raw_sf_opportunities', ['id', 'account_id', 'owner_id', 'type', 'stage_name', 'amount', 'close_date', 'route_to_market'], opps)
w('raw_sf_opportunity_line_items', ['id', 'opportunity_id', 'product_id', 'quantity', 'unit_price', 'total_price'], lines)
w('raw_billing_subscriptions', ['subscription_id', 'account_id', 'opportunity_id', 'product_id', 'quantity', 'annual_amount', 'start_date', 'end_date'], subs)
print(f'accounts={len(accounts)} opps={len(opps)} lines={len(lines)} subs={len(subs)} owner_changes={len(acct_history)}')

# Month calendar used for ARR snapshots (avoids warehouse-specific date spines)
months, m = [], dt.date(2024, 1, 1)
while m <= dt.date(2027, 12, 1):
    months.append((m.isoformat(),))
    m = dt.date(m.year + (m.month // 12), m.month % 12 + 1, 1)
w('calendar_months', ['month_start'], months)
