-- Active promotions + which products they apply to (category-wide and SKU-specific).
-- Aligns with Fréscopa cart codes: TEA820, COFFEE7, Promo10/20, 5-OFF, etc.

create unique index if not exists idx_promotions_promo_code
  on public.promotions (promo_code)
  where promo_code is not null;

-- Replace promo seed (catalog + stores unchanged)
delete from public.promotions;

insert into public.promotions (title, discount_percent, valid_from, valid_to, category, product_id, promo_code)
values
  -- Category (all products in category on promo today)
  ('Herbaciane popołudnie', 15,
   date_trunc('month', current_date)::date,
   (date_trunc('month', current_date) + interval '1 year')::date,
   'tea', null, 'TEA820'),
  ('Coffee lovers week', 15,
   date_trunc('month', current_date)::date,
   (date_trunc('month', current_date) + interval '1 year')::date,
   'coffee', null, 'COFFEE7'),
  ('Accessories flash', 10,
   current_date - interval '14 days',
   current_date + interval '90 days',
   'accessories', null, 'ACCESS10'),
  ('Machine event', 5,
   current_date,
   current_date + interval '45 days',
   'machines', null, 'MACHINES5'),
  -- Cart-style generic codes mapped to category promos for demo
  ('Promo 10% (tea & accessories)', 10,
   current_date,
   current_date + interval '120 days',
   'tea', null, 'Promo10'),
  ('Promo 20% (selected coffee)', 20,
   current_date,
   current_date + interval '60 days',
   'coffee', null, 'Promo20'),
  ('Checkout 5% (tea)', 5,
   current_date,
   current_date + interval '180 days',
   'tea', null, '5-OFF'),
  ('Promo 30% (machines)', 30,
   current_date,
   current_date + interval '30 days',
   'machines', null, 'Promo30');

-- Product-specific spotlight deals (stack in view with category promos if both match)
insert into public.promotions (title, discount_percent, valid_from, valid_to, product_id, promo_code)
select v.title, v.discount_percent, v.valid_from, v.valid_to, p.id, v.promo_code
from (
  values
    ('IA69R9QG8', 'Morning Muse spotlight', 20, 'MUSE20', current_date - 7, current_date + 90),
    ('_fIgob5sZR', 'Exotic Vibes feature', 15, 'EXOTIC15', current_date, current_date + 30),
    ('$7aVvm87R', 'Smart Machine launch', 10, 'SMART10', current_date, current_date + 60),
    ('vNk3tQP1b', 'Travel gear sale', 25, 'THERMOS25', current_date, current_date + 21),
    ('Yu1IWBlxG', 'Golden Monkey feature', 20, 'MONKEY20', current_date, current_date + 45),
    ('5Y2KJ4eG8', 'Hibiscus summer', 15, 'HIBISCUS15', current_date, current_date + 30),
    ('KXRbXGU85c', 'Afternoon Delight bundle', 10, 'AFTERNOON10', current_date, current_date + 14),
    ('iYpfvVAEa6', 'Filters multipack', 15, 'FILTERS15', current_date, current_date + 60)
) as v(demo_product_id, title, discount_percent, promo_code, valid_from, valid_to)
join public.products p on p.demo_product_id = v.demo_product_id;

-- Products currently on promotion (active today)
create or replace view public.v_products_on_promotion as
select
  p.demo_product_id,
  p.sku,
  p.name as product_name,
  p.category,
  p.base_price_cents,
  p.currency,
  p.image_url,
  pr.id as promotion_id,
  pr.title as promotion_title,
  pr.discount_percent,
  pr.promo_code,
  pr.valid_from,
  pr.valid_to,
  case when pr.product_id is not null then 'product' else 'category' end as promotion_scope,
  (p.base_price_cents * (100 - pr.discount_percent) / 100)::int as promotional_price_cents
from public.products p
inner join public.promotions pr
  on pr.product_id = p.id
  or (pr.product_id is null and pr.category = p.category)
where p.is_active = true
  and current_date >= pr.valid_from
  and current_date <= pr.valid_to;

grant select on public.v_products_on_promotion to anon, authenticated;

-- Summary: how many SKUs per promo code
create or replace view public.v_promotion_summary as
select
  pr.promo_code,
  pr.title,
  pr.discount_percent,
  pr.valid_from,
  pr.valid_to,
  case when pr.product_id is not null then 'product' else 'category' end as scope,
  pr.category,
  count(distinct p.demo_product_id) as products_on_promotion
from public.promotions pr
left join public.products p on p.is_active = true
  and (
    pr.product_id = p.id
    or (pr.product_id is null and pr.category = p.category)
  )
where current_date >= pr.valid_from
  and current_date <= pr.valid_to
group by pr.id, pr.promo_code, pr.title, pr.discount_percent, pr.valid_from, pr.valid_to, pr.product_id, pr.category;

grant select on public.v_promotion_summary to anon, authenticated;
