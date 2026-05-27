-- ~100 stores (Americas, Europe, Asia) + full product × store inventory for analytics demos.
-- Replaces the 3-store US seed. Safe to re-run: clears inventory + stores first.
--
-- Supabase may warn about DESTRUCTIVE ops (DELETE below) — that is intentional.
-- Use "Run query" / confirm destructive; do NOT enable RLS on a seed CTE (no table is created).

alter table public.store_locations
  add column if not exists region text,
  add column if not exists country text;

create index if not exists idx_stores_region on public.store_locations (region);
create index if not exists idx_stores_country on public.store_locations (country);

delete from public.inventory;
delete from public.store_locations;

-- --- 100 cities (35 Americas, 40 Europe, 25 Asia) — CTE only, no extra tables --------

insert into public.store_locations (code, city, name, region, country)
with seed_cities (region, country, city) as (
  values
  -- Americas (35)
  ('americas', 'USA', 'San Francisco'),
  ('americas', 'USA', 'New York'),
  ('americas', 'USA', 'Chicago'),
  ('americas', 'USA', 'Los Angeles'),
  ('americas', 'USA', 'Seattle'),
  ('americas', 'USA', 'Austin'),
  ('americas', 'USA', 'Miami'),
  ('americas', 'USA', 'Boston'),
  ('americas', 'USA', 'Denver'),
  ('americas', 'USA', 'Portland'),
  ('americas', 'USA', 'Atlanta'),
  ('americas', 'USA', 'Dallas'),
  ('americas', 'USA', 'Phoenix'),
  ('americas', 'USA', 'Philadelphia'),
  ('americas', 'USA', 'San Diego'),
  ('americas', 'Canada', 'Toronto'),
  ('americas', 'Canada', 'Vancouver'),
  ('americas', 'Canada', 'Montreal'),
  ('americas', 'Canada', 'Calgary'),
  ('americas', 'Mexico', 'Mexico City'),
  ('americas', 'Mexico', 'Guadalajara'),
  ('americas', 'Brazil', 'São Paulo'),
  ('americas', 'Brazil', 'Rio de Janeiro'),
  ('americas', 'Argentina', 'Buenos Aires'),
  ('americas', 'Chile', 'Santiago'),
  ('americas', 'Colombia', 'Bogotá'),
  ('americas', 'Peru', 'Lima'),
  ('americas', 'USA', 'Minneapolis'),
  ('americas', 'USA', 'Detroit'),
  ('americas', 'USA', 'Nashville'),
  ('americas', 'USA', 'Charlotte'),
  ('americas', 'USA', 'Salt Lake City'),
  ('americas', 'USA', 'Honolulu'),
  ('americas', 'Canada', 'Ottawa'),
  ('americas', 'USA', 'Las Vegas'),
  -- Europe (40)
  ('europe', 'UK', 'London'),
  ('europe', 'UK', 'Manchester'),
  ('europe', 'France', 'Paris'),
  ('europe', 'France', 'Lyon'),
  ('europe', 'Germany', 'Berlin'),
  ('europe', 'Germany', 'Munich'),
  ('europe', 'Germany', 'Hamburg'),
  ('europe', 'Netherlands', 'Amsterdam'),
  ('europe', 'Spain', 'Madrid'),
  ('europe', 'Spain', 'Barcelona'),
  ('europe', 'Italy', 'Milan'),
  ('europe', 'Italy', 'Rome'),
  ('europe', 'Poland', 'Warsaw'),
  ('europe', 'Poland', 'Kraków'),
  ('europe', 'Czech Republic', 'Prague'),
  ('europe', 'Austria', 'Vienna'),
  ('europe', 'Ireland', 'Dublin'),
  ('europe', 'Sweden', 'Stockholm'),
  ('europe', 'Denmark', 'Copenhagen'),
  ('europe', 'Belgium', 'Brussels'),
  ('europe', 'Portugal', 'Lisbon'),
  ('europe', 'Switzerland', 'Zurich'),
  ('europe', 'Norway', 'Oslo'),
  ('europe', 'Finland', 'Helsinki'),
  ('europe', 'Greece', 'Athens'),
  ('europe', 'Romania', 'Bucharest'),
  ('europe', 'Hungary', 'Budapest'),
  ('europe', 'Croatia', 'Zagreb'),
  ('europe', 'Serbia', 'Belgrade'),
  ('europe', 'Turkey', 'Istanbul'),
  ('europe', 'France', 'Marseille'),
  ('europe', 'Germany', 'Frankfurt'),
  ('europe', 'UK', 'Edinburgh'),
  ('europe', 'Spain', 'Valencia'),
  ('europe', 'Italy', 'Florence'),
  ('europe', 'Poland', 'Gdańsk'),
  ('europe', 'Netherlands', 'Rotterdam'),
  ('europe', 'Sweden', 'Gothenburg'),
  ('europe', 'Switzerland', 'Geneva'),
  ('europe', 'Belgium', 'Antwerp'),
  ('europe', 'Portugal', 'Porto'),
  -- Asia (25)
  ('asia', 'Japan', 'Tokyo'),
  ('asia', 'Japan', 'Osaka'),
  ('asia', 'Singapore', 'Singapore'),
  ('asia', 'South Korea', 'Seoul'),
  ('asia', 'Hong Kong', 'Hong Kong'),
  ('asia', 'China', 'Shanghai'),
  ('asia', 'China', 'Beijing'),
  ('asia', 'China', 'Shenzhen'),
  ('asia', 'Taiwan', 'Taipei'),
  ('asia', 'Thailand', 'Bangkok'),
  ('asia', 'India', 'Mumbai'),
  ('asia', 'India', 'Bengaluru'),
  ('asia', 'India', 'Delhi'),
  ('asia', 'Indonesia', 'Jakarta'),
  ('asia', 'Malaysia', 'Kuala Lumpur'),
  ('asia', 'Philippines', 'Manila'),
  ('asia', 'UAE', 'Dubai'),
  ('asia', 'Israel', 'Tel Aviv'),
  ('asia', 'Australia', 'Sydney'),
  ('asia', 'Australia', 'Melbourne'),
  ('asia', 'New Zealand', 'Auckland'),
  ('asia', 'Vietnam', 'Ho Chi Minh City'),
  ('asia', 'Japan', 'Kyoto'),
  ('asia', 'South Korea', 'Busan'),
  ('asia', 'China', 'Chengdu')
)
select
  case c.region
    when 'americas' then 'AM'
    when 'europe' then 'EU'
    when 'asia' then 'AS'
  end || '-' || lpad(row_number() over (partition by c.region order by c.country, c.city)::text, 3, '0'),
  c.city,
  'Fréscopa ' || c.city,
  c.region,
  c.country
from seed_cities c;

-- --- Inventory: every active product × every store (~2500 rows) ----------------
-- Deterministic pseudo-random qty: ~10% stores at 0, else 1–85 units.

insert into public.inventory (store_id, product_id, qty_on_hand)
select
  s.id,
  p.id,
  case
    when abs(hashtext(s.id::text || p.id::text)) % 100 < 10 then 0
    else (abs(hashtext(p.id::text || s.id::text || 'qty')) % 85) + 1
  end
from public.store_locations s
cross join public.products p
where p.is_active = true
on conflict (store_id, product_id) do update set
  qty_on_hand = excluded.qty_on_hand,
  updated_at = now();

-- Optional: view for regional analytics
create or replace view public.v_inventory_by_region as
select
  p.demo_product_id,
  p.name as product_name,
  p.category,
  s.region,
  s.country,
  count(*) filter (where i.qty_on_hand > 0) as stores_in_stock,
  count(*) as stores_total,
  sum(i.qty_on_hand) as total_qty,
  round(100.0 * count(*) filter (where i.qty_on_hand > 0) / nullif(count(*), 0), 1) as availability_pct
from public.inventory i
join public.products p on p.id = i.product_id
join public.store_locations s on s.id = i.store_id
where p.is_active = true
group by p.demo_product_id, p.name, p.category, s.region, s.country;

grant select on public.v_inventory_by_region to anon, authenticated;
