-- Add product images (Adobe Demo System assets). Safe to re-run: column + idempotent updates.

alter table public.products
  add column if not exists image_url text;

comment on column public.products.image_url is
  'Product image URL from Fréscopa demo project (project.products.image)';

update public.products as p
set image_url = v.image_url
from (
  values
    ('IA69R9QG8', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/morningmuse.jpg'),
    ('zD6y8UDee', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/coffeeset1.jpg'),
    ('DydkRCy0MT', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/energeticset.jpg'),
    ('bf2Z_LFKx', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/vanillamorning.jpg'),
    ('_fIgob5sZR', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/exoticvibes.jpg'),
    ('_1O_TdrHT', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/midnightoil.jpg'),
    ('KXRbXGU85c', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/afternoondelight.jpg'),
    ('8DIMcSHB_', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/coffeeset2.jpg'),
    ('VFrLOcqXL', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/oolong.jpg'),
    ('5Y2KJ4eG8', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/hibiscus.jpg'),
    ('kNddhyQvac', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/rooibos.jpg'),
    ('rkX5zwiC$', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/mistgreentea.jpg'),
    ('Yu1IWBlxG', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/goldenmonkeytea.jpg'),
    ('00Rl3YaSkS', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/happyflowertea.jpg'),
    ('u4iHbuc$u', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/frescooriginal.jpg'),
    ('4GHj5e0Qi', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/frescoespresso.jpg'),
    ('qxJny48yW', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/frescodeluxe.jpg'),
    ('vNk3tQP1b', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/travelthermos.jpg'),
    ('Ss6iuITqn', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/descalekit.jpg'),
    ('Z06yXKDPMM', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/coffeepot.jpg'),
    ('vy7SxmdmT', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/whitemilkjug.jpg'),
    ('zc1Y6cU99', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/bluemug.jpg'),
    ('iYpfvVAEa6', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/coffeefilter.jpg'),
    ('$7aVvm87R', 'https://demo-system-next.s3.amazonaws.com/assets/frescopa/coffee-machine.jpeg'),
    ('yupdXtpIB', 'https://t3.ftcdn.net/jpg/02/80/96/08/240_F_280960847_d9fH1MqjD8ka2XtTnIhLoNMqGYIN3CrX.jpg')
) as v(demo_product_id, image_url)
where p.demo_product_id = v.demo_product_id;
