---
name: osongo-supabase
description: OsonGo'da Supabase bazasi bilan ishlaganda ishlating — yangi jadval yoki ustun, RLS siyosati, SQL funksiya (RPC), Edge Function yoki admin panelga yangi boshqaruv moduli. Use for SQL, RLS, RPC and admin resource changes.
---

# OsonGo: Supabase va admin modullari

## Fayllar

SQL Editor'da shu tartibda ishga tushiriladi:

1. `supabase/seed_demo.sql` (ixtiyoriy)
2. `supabase/roles_setup.sql` — rollar, RLS, buyurtma holati funksiyalari
3. `supabase/super_app.sql` — magazin, usta, servislar, admin modullari
4. `supabase/seed_super_demo.sql` (ixtiyoriy)

- `roles_setup.sql` qayta ishga tushirilsa, **keyin `super_app.sql` ham**
  ishga tushirilishi shart.
- `profiles`, `restaurants`, `categories`, `products`, `orders`,
  `order_items` va `create_order()` ning DDL'i repoda yo'q. Ularning
  tuzilishini taxmin qilmang: `tool/sql_test/stubs.sql` faqat ilova kodidan
  tiklangan nusxa.
- Magazin alohida jadval emas: `restaurants` da `kind = 'shop'`.

## Qoidalar

- Skriptlar **idempotent** bo'lsin: `create table if not exists`,
  `add column if not exists`, `drop policy if exists` + `create policy`,
  `drop trigger if exists`, `create or replace function`.
- Har bir yangi jadvalda RLS yoqilsin.
- `security definer` funksiyada `set search_path = public` bo'lsin, ichida
  chaqiruvchining huquqi tekshirilsin.
- Yangi RPC: `revoke all ... from public, anon;` keyin kerakli rolga
  `grant execute`.
- Admin huquqi `public.is_admin()` bilan tekshiriladi.
- Foydalanuvchiga ko'rinadigan `raise exception` xabari o'zbek tilida
  (ilova `P0001` kodli xabarni o'zini ko'rsatadi).
- Hamkor o'z tasdiq holati, komissiyasi va reytingini o'zgartira olmasin.
- `service_role` kaliti ilovaga, repoga yoki javobga yozilmaydi.

## Yangi jadval

1. `super_app.sql` ga `create table if not exists`.
2. Shu fayldagi "RLS siyosatlari" bo'limida `enable row level security`.
3. Jadval nomini admin siyosati yaratiladigan `do $$` blokidagi massivga
   qo'shing.
4. Boshqa rollar uchun kerakli minimal siyosatlarni yozing.
5. `tool/sql_test/run.mjs` ga ruxsat testi: egasi ko'radi, begona ko'rmaydi
   yoki o'zgartira olmaydi.

## Admin moduli

Oddiy CRUD uchun yangi sahifa yozmang:

1. `lib/features/admin/resources.dart` ga `AdminResource` va `ResourceField`
   lar qo'shing (turlar: `resource/admin_resource.dart` dagi `FieldType`).
2. `lib/features/admin/admin_home_page.dart` da `AdminSection` enumiga qiymat
   qo'shing.
3. `_page()` switch'ida `ResourcePage(resource: ...)` qaytaring.

## Edge Function

`supabase/functions/admin-create-user` — hisob yaratish va o'chirish.

## Ehtiyot bo'ling

Haqiqiy bazada SQL ishga tushirish va `supabase functions deploy` faqat
foydalanuvchi aniq so'raganda. Oldin zaxira nusxa kerakligini eslating.
SQL o'zgargach, `osongo-check` dagi SQL testlarini bajaring.
