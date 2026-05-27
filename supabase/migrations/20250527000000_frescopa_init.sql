-- Frescopa × Adobe Demo System — catalog mirrors project.products (names + USD prices) + store availability
-- Locale-aligned stores (en-us). Run in Supabase SQL Editor or via CLI.

create extension if not exists "pgcrypto";

-- --- Tables -----------------------------------------------------------------

create table if not exists public.store_locations (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  city text not null,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  demo_product_id text not null unique,
  sku text not null unique,
  name text not null,
  category text not null check (category in ('coffee', 'tea', 'machines', 'accessories')),
  origin text,
  roast_or_type text,
  unit text not null default 'each',
  base_price_cents int not null check (base_price_cents >= 0),
  currency text not null default 'USD',
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.inventory (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.store_locations (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  qty_on_hand int not null default 0 check (qty_on_hand >= 0),
  updated_at timestamptz not null default now(),
  unique (store_id, product_id)
);

create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  discount_percent int not null check (discount_percent between 1 and 100),
  valid_from date not null,
  valid_to date not null,
  promo_code text,
  product_id uuid references public.products (id) on delete set null,
  category text check (
    category is null
    or category in ('coffee', 'tea', 'machines', 'accessories')
  ),
  created_at timestamptz not null default now(),
  check (valid_to >= valid_from),
  check (product_id is not null or category is not null)
);

create index if not exists idx_inventory_store on public.inventory (store_id);
create index if not exists idx_inventory_product on public.inventory (product_id);
create index if not exists idx_products_category on public.products (category) where is_active;
create index if not exists idx_products_demo_id on public.products (demo_product_id);

-- --- RLS --------------------------------------------------------------------

alter table public.store_locations enable row level security;
alter table public.products enable row level security;
alter table public.inventory enable row level security;
alter table public.promotions enable row level security;

drop policy if exists "frescopa_anon_select_stores" on public.store_locations;
create policy "frescopa_anon_select_stores"
  on public.store_locations for select to anon using (true);

drop policy if exists "frescopa_anon_select_products" on public.products;
create policy "frescopa_anon_select_products"
  on public.products for select to anon using (true);

drop policy if exists "frescopa_anon_select_inventory" on public.inventory;
create policy "frescopa_anon_select_inventory"
  on public.inventory for select to anon using (true);

drop policy if exists "frescopa_anon_select_promotions" on public.promotions;
create policy "frescopa_anon_select_promotions"
  on public.promotions for select to anon using (true);

drop policy if exists "frescopa_auth_select_stores" on public.store_locations;
create policy "frescopa_auth_select_stores"
  on public.store_locations for select to authenticated using (true);

drop policy if exists "frescopa_auth_select_products" on public.products;
create policy "frescopa_auth_select_products"
  on public.products for select to authenticated using (true);

drop policy if exists "frescopa_auth_select_inventory" on public.inventory;
create policy "frescopa_auth_select_inventory"
  on public.inventory for select to authenticated using (true);

drop policy if exists "frescopa_auth_select_promotions" on public.promotions;
create policy "frescopa_auth_select_promotions"
  on public.promotions for select to authenticated using (true);

-- --- Stores (US, matches en-us project) -------------------------------------

insert into public.store_locations (code, city, name) values
  ('SF-01', 'San Francisco', 'Fréscopa SOMA'),
  ('NYC-01', 'New York', 'Fréscopa Williamsburg'),
  ('CHI-01', 'Chicago', 'Fréscopa West Loop')
on conflict (code) do nothing;

-- --- Products: names + prices from Adobe Demo project.products (USD → cents)

insert into public.products (demo_product_id, sku, name, category, unit, base_price_cents) values
  ('IA69R9QG8', 'fp-IA69R9QG8', 'Morning Muse', 'coffee', 'each', 1400),
  ('zD6y8UDee', 'fp-zD6y8UDee', 'Coffee Set 1', 'coffee', 'each', 2500),
  ('DydkRCy0MT', 'fp-DydkRCy0MT', 'Energetic Start', 'coffee', 'each', 2500),
  ('bf2Z_LFKx', 'fp-bf2Z_LFKx', 'Vanilla Morning', 'coffee', 'each', 2500),
  ('_fIgob5sZR', 'fp-_fIgob5sZR', 'Exotic Vibes', 'coffee', 'each', 2500),
  ('_1O_TdrHT', 'fp-_1O_TdrHT', 'Midnight Oil', 'coffee', 'each', 1400),
  ('KXRbXGU85c', 'fp-KXRbXGU85c', 'Afternoon Delight', 'coffee', 'each', 1400),
  ('8DIMcSHB_', 'fp-8DIMcSHB_', 'Coffee Set 2', 'coffee', 'each', 2500),
  ('VFrLOcqXL', 'fp-VFrLOcqXL', 'Oolong', 'tea', 'each', 999),
  ('5Y2KJ4eG8', 'fp-5Y2KJ4eG8', 'Hibiscus', 'tea', 'each', 999),
  ('kNddhyQvac', 'fp-kNddhyQvac', 'Rooibos', 'tea', 'each', 999),
  ('rkX5zwiC$', 'fp-rkX5zwiC', 'Mist Green Tea', 'tea', 'each', 999),
  ('Yu1IWBlxG', 'fp-Yu1IWBlxG', 'Golden Monkey Tea', 'tea', 'each', 999),
  ('00Rl3YaSkS', 'fp-00Rl3YaSkS', 'Happy Flower Tea', 'tea', 'each', 999),
  ('u4iHbuc$u', 'fp-u4iHbucu', 'Frésco Original', 'machines', 'each', 149900),
  ('4GHj5e0Qi', 'fp-4GHj5e0Qi', 'Frésco Expresso', 'machines', 'each', 149900),
  ('qxJny48yW', 'fp-qxJny48yW', 'Frésco Deluxe', 'machines', 'each', 149900),
  ('vNk3tQP1b', 'fp-vNk3tQP1b', 'Travel Thermos', 'accessories', 'each', 3900),
  ('Ss6iuITqn', 'fp-Ss6iuITqn', 'Descale Kit', 'accessories', 'each', 2800),
  ('Z06yXKDPMM', 'fp-Z06yXKDPMM', 'Coffee Pot', 'accessories', 'each', 14900),
  ('vy7SxmdmT', 'fp-vy7SxmdmT', 'White Milk Jug', 'accessories', 'each', 6500),
  ('zc1Y6cU99', 'fp-zc1Y6cU99', '12 oz. Blue Mug', 'accessories', 'each', 3000),
  ('iYpfvVAEa6', 'fp-iYpfvVAEa6', '20 Coffee Filters', 'accessories', 'each', 499),
  ('$7aVvm87R', 'fp-7aVvm87R', 'Frescopa Smart Machine', 'machines', 'each', 69900),
  ('yupdXtpIB', 'fp-yupdXtpIB', 'Wooden coffee spoon', 'accessories', 'each', 1099)
on conflict (demo_product_id) do update set
  name = excluded.name,
  category = excluded.category,
  base_price_cents = excluded.base_price_cents,
  sku = excluded.sku,
  unit = excluded.unit;

-- --- Inventory (mock availability; SF fullest, some NYC/CHI gaps for demo) ---

insert into public.inventory (store_id, product_id, qty_on_hand)
select s.id, p.id, v.qty::int
from (
  values
    -- SF-01
    ('SF-01', 'IA69R9QG8', 48),
    ('SF-01', 'zD6y8UDee', 22),
    ('SF-01', 'DydkRCy0MT', 18),
    ('SF-01', 'bf2Z_LFKx', 30),
    ('SF-01', '_fIgob5sZR', 0),
    ('SF-01', '_1O_TdrHT', 55),
    ('SF-01', 'KXRbXGU85c', 40),
    ('SF-01', '8DIMcSHB_', 12),
    ('SF-01', 'VFrLOcqXL', 60),
    ('SF-01', '5Y2KJ4eG8', 35),
    ('SF-01', 'kNddhyQvac', 28),
    ('SF-01', 'rkX5zwiC$', 15),
    ('SF-01', 'Yu1IWBlxG', 20),
    ('SF-01', '00Rl3YaSkS', 8),
    ('SF-01', 'u4iHbuc$u', 3),
    ('SF-01', '4GHj5e0Qi', 2),
    ('SF-01', 'qxJny48yW', 2),
    ('SF-01', 'vNk3tQP1b', 45),
    ('SF-01', 'Ss6iuITqn', 70),
    ('SF-01', 'Z06yXKDPMM', 10),
    ('SF-01', 'vy7SxmdmT', 14),
    ('SF-01', 'zc1Y6cU99', 25),
    ('SF-01', 'iYpfvVAEa6', 120),
    ('SF-01', '$7aVvm87R', 6),
    ('SF-01', 'yupdXtpIB', 100),
    -- NYC-01
    ('NYC-01', 'IA69R9QG8', 12),
    ('NYC-01', 'zD6y8UDee', 0),
    ('NYC-01', 'DydkRCy0MT', 9),
    ('NYC-01', 'bf2Z_LFKx', 4),
    ('NYC-01', '_fIgob5sZR', 16),
    ('NYC-01', '_1O_TdrHT', 22),
    ('NYC-01', 'KXRbXGU85c', 0),
    ('NYC-01', '8DIMcSHB_', 7),
    ('NYC-01', 'VFrLOcqXL', 44),
    ('NYC-01', '5Y2KJ4eG8', 18),
    ('NYC-01', 'kNddhyQvac', 20),
    ('NYC-01', 'rkX5zwiC$', 0),
    ('NYC-01', 'Yu1IWBlxG', 11),
    ('NYC-01', '00Rl3YaSkS', 30),
    ('NYC-01', 'u4iHbuc$u', 1),
    ('NYC-01', '4GHj5e0Qi', 1),
    ('NYC-01', 'qxJny48yW', 0),
    ('NYC-01', 'vNk3tQP1b', 12),
    ('NYC-01', 'Ss6iuITqn', 40),
    ('NYC-01', 'Z06yXKDPMM', 3),
    ('NYC-01', 'vy7SxmdmT', 6),
    ('NYC-01', 'zc1Y6cU99', 9),
    ('NYC-01', 'iYpfvVAEa6', 200),
    ('NYC-01', '$7aVvm87R', 2),
    ('NYC-01', 'yupdXtpIB', 40),
    -- CHI-01
    ('CHI-01', 'IA69R9QG8', 20),
    ('CHI-01', 'zD6y8UDee', 10),
    ('CHI-01', 'DydkRCy0MT', 0),
    ('CHI-01', 'bf2Z_LFKx', 14),
    ('CHI-01', '_fIgob5sZR', 8),
    ('CHI-01', '_1O_TdrHT', 18),
    ('CHI-01', 'KXRbXGU85c', 25),
    ('CHI-01', '8DIMcSHB_', 5),
    ('CHI-01', 'VFrLOcqXL', 15),
    ('CHI-01', '5Y2KJ4eG8', 0),
    ('CHI-01', 'kNddhyQvac', 12),
    ('CHI-01', 'rkX5zwiC$', 22),
    ('CHI-01', 'Yu1IWBlxG', 0),
    ('CHI-01', '00Rl3YaSkS', 14),
    ('CHI-01', 'u4iHbuc$u', 0),
    ('CHI-01', '4GHj5e0Qi', 1),
    ('CHI-01', 'qxJny48yW', 1),
    ('CHI-01', 'vNk3tQP1b', 8),
    ('CHI-01', 'Ss6iuITqn', 15),
    ('CHI-01', 'Z06yXKDPMM', 4),
    ('CHI-01', 'vy7SxmdmT', 0),
    ('CHI-01', 'zc1Y6cU99', 18),
    ('CHI-01', 'iYpfvVAEa6', 80),
    ('CHI-01', '$7aVvm87R', 1),
    ('CHI-01', 'yupdXtpIB', 55)
) as v(store_code, demo_product_id, qty)
join public.store_locations s on s.code = v.store_code
join public.products p on p.demo_product_id = v.demo_product_id
on conflict (store_id, product_id) do update set
  qty_on_hand = excluded.qty_on_hand,
  updated_at = now();

-- --- Promotions (aligns with cart discount codes on frescopa site) ---------

insert into public.promotions (title, discount_percent, valid_from, valid_to, category, promo_code)
select 'Tea week (TEA820)', 15,
       date_trunc('month', now())::date,
       (date_trunc('month', now()) + interval '1 year')::date,
       'tea',
       'TEA820'
where not exists (select 1 from public.promotions where promo_code = 'TEA820');

insert into public.promotions (title, discount_percent, valid_from, valid_to, category, promo_code)
select 'Coffee promo (COFFEE7)', 15,
       date_trunc('month', now())::date,
       (date_trunc('month', now()) + interval '1 year')::date,
       'coffee',
       'COFFEE7'
where not exists (select 1 from public.promotions where promo_code = 'COFFEE7');
