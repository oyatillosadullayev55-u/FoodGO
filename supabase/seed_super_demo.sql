-- ============================================================
-- OsonGo super-app demo ma'lumotlari (ixtiyoriy).
-- super_app.sql dan KEYIN ishga tushiring. Idempotent.
-- Rasm yo'llari "assets/..." ilova ichidagi namunaviy rasmlardir.
-- ============================================================

insert into public.regions (id, name, kind, parent_id, sort_order) values
  ('d1000000-0000-4000-8000-000000000001', 'Farg''ona viloyati', 'viloyat', null, 1),
  ('d1000000-0000-4000-8000-000000000002', 'Toshkent shahri',    'viloyat', null, 2),
  ('d1000000-0000-4000-8000-000000000003', 'Farg''ona',  'shahar', 'd1000000-0000-4000-8000-000000000001', 1),
  ('d1000000-0000-4000-8000-000000000004', 'Marg''ilon', 'shahar', 'd1000000-0000-4000-8000-000000000001', 2),
  ('d1000000-0000-4000-8000-000000000005', 'Qo''qon',    'shahar', 'd1000000-0000-4000-8000-000000000001', 3),
  ('d1000000-0000-4000-8000-000000000006', 'Chilonzor',  'tuman',  'd1000000-0000-4000-8000-000000000002', 1),
  ('d1000000-0000-4000-8000-000000000007', 'Yunusobod',  'tuman',  'd1000000-0000-4000-8000-000000000002', 2)
on conflict (id) do nothing;

insert into public.categories (id, name, icon, sort_order, kind) values
  ('c1000000-0000-4000-8000-000000000001', 'Elektronika', '🎧', 1, 'shop'),
  ('c1000000-0000-4000-8000-000000000002', 'Kiyim',       '👕', 2, 'shop'),
  ('c1000000-0000-4000-8000-000000000003', 'Maishiy',     '🧺', 3, 'shop'),
  ('c1000000-0000-4000-8000-000000000004', 'Meva',        '🍎', 4, 'shop'),
  ('c1000000-0000-4000-8000-000000000005', 'Sabzavot',    '🍅', 5, 'shop'),
  ('c2000000-0000-4000-8000-000000000001', 'Santexnik',   '🔧', 1, 'master'),
  ('c2000000-0000-4000-8000-000000000002', 'Elektrik',    '💡', 2, 'master'),
  ('c2000000-0000-4000-8000-000000000003', 'Ta''mir',     '🛠️', 3, 'master')
on conflict (id) do nothing;

update public.restaurants set delivery_time = '30–40 daqiqa'
where kind = 'restaurant' and delivery_time is null;

insert into public.restaurants
  (id, name, description, address, lat, lng, image_url, rating, open_time, close_time,
   kind, delivery_time, verification_status, is_active) values
  ('b1000000-0000-4000-8000-000000000001', 'TechnoMart', 'Elektronika va gadjetlar',
   'Farg''ona, Al-Farg''oniy ko''chasi 14', 40.3864, 71.7864,
   'assets/images/headphones.webp', 4.8, '09:00:00', '21:00:00',
   'shop', '40–60 daqiqa', 'approved', true),
  ('b1000000-0000-4000-8000-000000000002', 'Dehqon Bozori', 'Yangi meva va sabzavotlar',
   'Farg''ona, Mustaqillik ko''chasi 7', 40.3842, 71.7893,
   'assets/images/apple.webp', 4.7, '07:00:00', '20:00:00',
   'shop', '25–35 daqiqa', 'approved', true)
on conflict (id) do nothing;

insert into public.products
  (id, restaurant_id, category_id, name, price, description, image_url, is_available, stock, unit) values
  ('a1000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001',
   'AirPods Pro', 1990000, 'Simsiz quloqchin', 'assets/images/airpods.webp', true, 15, 'dona'),
  ('a1000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001',
   'Smart Watch', 1499000, 'Aqlli soat', 'assets/images/watch.webp', true, 9, 'dona'),
  ('a1000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001',
   'Telefon', 5999000, '128 GB smartfon', 'assets/images/phone.webp', true, 6, 'dona'),
  ('a1000000-0000-4000-8000-000000000004', 'b1000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001',
   'Noutbuk', 7999000, '15.6 dyuymli noutbuk', 'assets/images/laptop.webp', true, 4, 'dona'),
  ('a1000000-0000-4000-8000-000000000005', 'b1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000004',
   'Olma', 12000, 'Yangi uzilgan olma', 'assets/images/apple.webp', true, 120, 'kg'),
  ('a1000000-0000-4000-8000-000000000006', 'b1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000005',
   'Pomidor', 14000, 'Issiqxona pomidori', 'assets/images/tomato.webp', true, 80, 'kg'),
  ('a1000000-0000-4000-8000-000000000007', 'b1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000004',
   'Banan', 18000, 'Pishgan banan', 'assets/images/banana.webp', true, 60, 'kg'),
  ('a1000000-0000-4000-8000-000000000008', 'b1000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000004',
   'Uzum', 22000, 'Shirin uzum', 'assets/images/grape.webp', true, 45, 'kg')
on conflict (id) do nothing;

insert into public.masters
  (id, full_name, category_id, phone, photo_url, about, price_from, eta,
   rating, rating_count, region_id, verification_status) values
  ('e1000000-0000-4000-8000-000000000001', 'Ali Usta', 'c2000000-0000-4000-8000-000000000001',
   '+998901234501', 'assets/images/master_1.webp', 'Santexnika o''rnatish va ta''mirlash, 8 yillik tajriba.',
   80000, '20–30 daqiqa', 4.9, 2100, 'd1000000-0000-4000-8000-000000000003', 'approved'),
  ('e1000000-0000-4000-8000-000000000002', 'Rustam Usta', 'c2000000-0000-4000-8000-000000000003',
   '+998901234502', 'assets/images/master_2.webp', 'Uy ta''miri va duradgorlik ishlari.',
   100000, '30–40 daqiqa', 4.8, 856, 'd1000000-0000-4000-8000-000000000003', 'approved'),
  ('e1000000-0000-4000-8000-000000000003', 'Bekzod Usta', 'c2000000-0000-4000-8000-000000000002',
   '+998901234503', 'assets/images/master_3.webp', 'Elektr tarmoqlari, rozetka va yoritish.',
   70000, '20–35 daqiqa', 4.9, 730, 'd1000000-0000-4000-8000-000000000003', 'approved')
on conflict (id) do nothing;

insert into public.promotions (id, title, subtitle, service_code, image_url, sort_order) values
  ('f1000000-0000-4000-8000-000000000001', 'Eng mazali taomlar faqat OsonGo''da!', null,
   'food', 'assets/images/promo_pizza.webp', 1),
  ('f1000000-0000-4000-8000-000000000002', 'Ustalar xizmatlari tez va ishonchli', null,
   'master', 'assets/images/promo_master.webp', 2)
on conflict (id) do nothing;

insert into public.subscription_plans (id, title, audience, price, period_days, features) values
  ('f2000000-0000-4000-8000-000000000001', 'Restoran Start', 'restaurant', 199000, 30, 'Menyu va buyurtmalar'),
  ('f2000000-0000-4000-8000-000000000002', 'Magazin Pro', 'shop', 299000, 30, 'Ombor va savdo statistikasi'),
  ('f2000000-0000-4000-8000-000000000003', 'Usta Premium', 'master', 99000, 30, 'Qidiruvda yuqorida chiqish')
on conflict (id) do nothing;
