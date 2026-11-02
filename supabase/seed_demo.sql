-- ============================================================
-- FoodGo demo katalog (mijoz sayti uchun)
-- Supabase Dashboard -> SQL Editor -> New query -> shu faylni
-- to'liq joylashtiring va "Run" bosing.
-- Skript idempotent: qayta ishga tushirsangiz dublikat yaratmaydi.
-- ============================================================

insert into public.categories (id, name, icon, sort_order) values
  ('c0000000-0000-4000-8000-000000000001', 'Milliy',     '🍲', 1),
  ('c0000000-0000-4000-8000-000000000002', 'Burger',     '🍔', 2),
  ('c0000000-0000-4000-8000-000000000003', 'Pitsa',      '🍕', 3),
  ('c0000000-0000-4000-8000-000000000004', 'Sushi',      '🍣', 4),
  ('c0000000-0000-4000-8000-000000000005', 'Fastfood',   '🍗', 5),
  ('c0000000-0000-4000-8000-000000000006', 'Qahva',      '☕', 6),
  ('c0000000-0000-4000-8000-000000000007', 'Shirinlik',  '🍰', 7),
  ('c0000000-0000-4000-8000-000000000008', 'Salat',      '🥗', 8)
on conflict (id) do nothing;

insert into public.restaurants
  (id, name, description, address, image_url, rating, open_time, close_time) values
  ('b0000000-0000-4000-8000-000000000001', 'Osh Markazi',
   'Toshkent oshi va milliy taomlar',
   'Chilonzor, Bunyodkor ko''chasi 12',
   'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=900&q=75',
   4.9, '09:00:00', '22:00:00'),

  ('b0000000-0000-4000-8000-000000000002', 'Burger House',
   'Amerika uslubidagi mazali burgerlar',
   'Yunusobod, Amir Temur shoh ko''chasi 108',
   'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=75',
   4.7, '10:00:00', '23:00:00'),

  ('b0000000-0000-4000-8000-000000000003', 'Pizza Roma',
   'Italyan pitsasi, o''tin pechda pishirilgan',
   'Mirzo Ulug''bek, Buyuk Ipak yo''li 45',
   'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=75',
   4.6, '11:00:00', '23:30:00'),

  ('b0000000-0000-4000-8000-000000000004', 'Sushi Master',
   'Yapon oshxonasi, har kuni yangi sushi',
   'Shayxontohur, Navoiy ko''chasi 30',
   'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=900&q=75',
   4.8, '11:00:00', '22:30:00'),

  ('b0000000-0000-4000-8000-000000000005', 'Lavash City',
   'Tez va mazali lavash hamda fastfood',
   'Sergeli, Yangi Sergeli 4-kvartal',
   'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?auto=format&fit=crop&w=900&q=75',
   4.5, '09:00:00', '23:00:00'),

  ('b0000000-0000-4000-8000-000000000006', 'Coffee Point',
   'Qahva, desert va ertalabki nonushta',
   'Yakkasaroy, Shota Rustaveli 22',
   'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=75',
   4.4, '08:00:00', '21:00:00')
on conflict (id) do nothing;

insert into public.products
  (id, restaurant_id, category_id, name, price, description, image_url, is_available) values
  -- Osh Markazi
  ('a0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001',
   'Osh', 35000, 'Toshkent oshi, qo''y go''shti va sarimsoq bilan',
   'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001',
   'Norin', 28000, 'Qazi va chuchvara bilan an''anaviy norin',
   'https://images.unsplash.com/photo-1552611052-33e04de081de?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000003', 'b0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001',
   'Manti', 30000, 'Bug''da pishirilgan qo''l mantisi (5 dona)',
   'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000004', 'b0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001',
   'Lag''mon', 32000, 'Qo''lda tortilgan lag''mon, sabzavotli',
   'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000005', 'b0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001',
   'Somsa', 10000, 'Tandirda pishirilgan somsa',
   'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=600&q=70', true),

  -- Burger House
  ('a0000000-0000-4000-8000-000000000006', 'b0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000002',
   'Klassik Burger', 38000, 'Mol go''shtli kotlet, pishloq va sous',
   'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000007', 'b0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000002',
   'Chizburger', 42000, 'Ikki qatlam pishloqli chizburger',
   'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000008', 'b0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000002',
   'Double Beef', 55000, 'Ikki kotletli katta burger',
   'https://images.unsplash.com/photo-1606755962773-d324e0a13086?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000009', 'b0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000002',
   'Tovuqli Burger', 35000, 'Xamirli tovuq filesi va yangi sabzavotlar',
   'https://images.unsplash.com/photo-1615297928064-24977384d0da?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000010', 'b0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000005',
   'Fri kartoshka', 18000, 'Tuzli, qarsildoq fri kartoshka',
   'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=600&q=70', true),

  -- Pizza Roma
  ('a0000000-0000-4000-8000-000000000011', 'b0000000-0000-4000-8000-000000000003', 'c0000000-0000-4000-8000-000000000003',
   'Margarita', 55000, 'Mozzarella, pomidor sousi va rayhon',
   'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000012', 'b0000000-0000-4000-8000-000000000003', 'c0000000-0000-4000-8000-000000000003',
   'Pepperoni', 62000, 'Pepperoni kolbasa va mozzarella',
   'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000013', 'b0000000-0000-4000-8000-000000000003', 'c0000000-0000-4000-8000-000000000003',
   '4 Pishloq', 68000, 'Mozzarella, gorgonzola, parmezan va chedder',
   'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000014', 'b0000000-0000-4000-8000-000000000003', 'c0000000-0000-4000-8000-000000000003',
   'Tovuqli pitsa', 60000, 'Tovuq, qo''ziqorin va pishloq',
   'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000015', 'b0000000-0000-4000-8000-000000000003', 'c0000000-0000-4000-8000-000000000008',
   'Sezar salat', 32000, 'Tovuqli sezar, parmezan bilan',
   'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=600&q=70', true),

  -- Sushi Master
  ('a0000000-0000-4000-8000-000000000016', 'b0000000-0000-4000-8000-000000000004', 'c0000000-0000-4000-8000-000000000004',
   'Filadelfiya', 75000, 'Losos, krem-pishloq va bodring (8 dona)',
   'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000017', 'b0000000-0000-4000-8000-000000000004', 'c0000000-0000-4000-8000-000000000004',
   'Kaliforniya', 68000, 'Qisqichbaqa go''shti, avokado va tobiko',
   'https://images.unsplash.com/photo-1553621042-f6e147245754?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000018', 'b0000000-0000-4000-8000-000000000004', 'c0000000-0000-4000-8000-000000000004',
   'Sake maki', 45000, 'Lososli klassik maki (6 dona)',
   'https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000019', 'b0000000-0000-4000-8000-000000000004', 'c0000000-0000-4000-8000-000000000004',
   'Tovuqli uramaki', 52000, 'Tovuq va pishloqli uramaki',
   'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000020', 'b0000000-0000-4000-8000-000000000004', 'c0000000-0000-4000-8000-000000000004',
   'Edamame', 22000, 'Bug''langan yashil soya loviyasi',
   'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&w=600&q=70', false),

  -- Lavash City
  ('a0000000-0000-4000-8000-000000000021', 'b0000000-0000-4000-8000-000000000005', 'c0000000-0000-4000-8000-000000000005',
   'Standart lavash', 25000, 'Tovuq, sabzavot va maxsus sous',
   'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000022', 'b0000000-0000-4000-8000-000000000005', 'c0000000-0000-4000-8000-000000000005',
   'Pishloqli lavash', 32000, 'Ikki xil pishloq bilan',
   'https://images.unsplash.com/photo-1594007654729-407eedc4be65?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000023', 'b0000000-0000-4000-8000-000000000005', 'c0000000-0000-4000-8000-000000000005',
   'Tovuqli lavash', 28000, 'Grilda pishirilgan tovuq bilan',
   'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000024', 'b0000000-0000-4000-8000-000000000005', 'c0000000-0000-4000-8000-000000000005',
   'Hot-dog', 18000, 'Sosiska, ketchup va xantal',
   'https://images.unsplash.com/photo-1619740455993-9e612b1af08a?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000025', 'b0000000-0000-4000-8000-000000000005', 'c0000000-0000-4000-8000-000000000005',
   'Ayran', 8000, 'Salqin milliy ichimlik',
   'https://images.unsplash.com/photo-1571091718767-18b5b1457add?auto=format&fit=crop&w=600&q=70', true),

  -- Coffee Point
  ('a0000000-0000-4000-8000-000000000026', 'b0000000-0000-4000-8000-000000000006', 'c0000000-0000-4000-8000-000000000006',
   'Latte', 22000, 'Mayin sutli espresso',
   'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000027', 'b0000000-0000-4000-8000-000000000006', 'c0000000-0000-4000-8000-000000000006',
   'Kapuchino', 20000, 'Ko''pikli klassik kapuchino',
   'https://images.unsplash.com/photo-1572442388796-11668a67e53d?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000028', 'b0000000-0000-4000-8000-000000000006', 'c0000000-0000-4000-8000-000000000006',
   'Amerika', 18000, 'Kuchli qora qahva',
   'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000029', 'b0000000-0000-4000-8000-000000000006', 'c0000000-0000-4000-8000-000000000007',
   'Chizkeyk', 28000, 'New York uslubidagi chizkeyk',
   'https://images.unsplash.com/photo-1551024506-0bccd828d307?auto=format&fit=crop&w=600&q=70', true),
  ('a0000000-0000-4000-8000-000000000030', 'b0000000-0000-4000-8000-000000000006', 'c0000000-0000-4000-8000-000000000007',
   'Kruassan', 15000, 'Yangi pishirilgan fransuz kruassani',
   'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=70', true)
on conflict (id) do nothing;

-- Tekshirish
select 'categories' as table_name, count(*) as rows from public.categories
union all
select 'restaurants', count(*) from public.restaurants
union all
select 'products', count(*) from public.products;
