-- ============================================================
-- FoodGo: rollar, xavfsizlik (RLS) va kuryer logikasi
-- Supabase Dashboard -> SQL Editor -> New query -> shu faylni
-- to'liq joylashtiring va "Run" bosing.
--
-- Skript idempotent: bir necha marta ishga tushirish xavfsiz.
-- Diqqat: public jadvallaridagi eski RLS siyosatlari o'chirilib,
-- ularning o'rniga quyidagi aniq rollar uchun qayta yoziladi.
-- ============================================================

-- ---------- 1. Ustunlar ----------
alter table public.profiles
  add column if not exists email text;

alter table public.restaurants
  add column if not exists owner_id uuid references auth.users (id) on delete set null,
  add column if not exists owner_email text,
  add column if not exists is_active boolean not null default true,
  add column if not exists lat double precision,
  add column if not exists lng double precision;

alter table public.orders
  add column if not exists courier_id uuid references auth.users (id) on delete set null;

create index if not exists restaurants_owner_email_idx
  on public.restaurants (lower(owner_email));
create index if not exists orders_courier_idx
  on public.orders (courier_id);
create index if not exists orders_restaurant_idx
  on public.orders (restaurant_id);

-- ---------- 2. Mavjud foydalanuvchilar emailini to'ldirish ----------
update public.profiles p
set email = u.email
from auth.users u
where u.id = p.id
  and (p.email is null or p.email <> u.email);

insert into public.profiles (id, role, full_name, email)
select
  u.id,
  case
    when lower(u.email) in ('oyatillosadullayev55@gmail.com', 'admin@foodgo.uz') then 'admin'
    when lower(u.email) in ('owner.foodgo@example.com') then 'restaurant'
    when lower(u.email) in ('courier.foodgo@example.com') then 'courier'
    else 'customer'
  end,
  coalesce(u.raw_user_meta_data ->> 'full_name', 'Foydalanuvchi'),
  u.email
from auth.users u
on conflict (id) do update
  set email = excluded.email;

-- ---------- 3. Yangi ro'yxatdan o'tganda profil yaratish ----------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
begin
  v_role := case
    when lower(new.email) in ('oyatillosadullayev55@gmail.com', 'admin@foodgo.uz') then 'admin'
    when lower(new.email) in ('owner.foodgo@example.com') then 'restaurant'
    when lower(new.email) in ('courier.foodgo@example.com') then 'courier'
    else 'customer'
  end;

  insert into public.profiles (id, role, full_name, phone, email)
  values (
    new.id,
    v_role,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Foydalanuvchi'),
    new.raw_user_meta_data ->> 'phone',
    new.email
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = coalesce(public.profiles.full_name, excluded.full_name),
        phone = coalesce(public.profiles.phone, excluded.phone);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- 4. Yordamchi funksiyalar ----------
create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.role from public.profiles p where p.id = auth.uid()),
    'customer'
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_user_role() = 'admin';
$$;

create or replace function public.is_courier()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_user_role() = 'courier';
$$;

create or replace function public.owns_restaurant(p_restaurant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.restaurants r
    where r.id = p_restaurant_id
      and (
        r.owner_id = auth.uid()
        or (
          r.owner_email is not null
          and lower(r.owner_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
        )
      )
  );
$$;

-- ---------- 5. Eski RLS siyosatlarini tozalash ----------
do $$
declare
  p record;
begin
  for p in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in (
        'profiles', 'restaurants', 'products', 'categories',
        'orders', 'order_items'
      )
  loop
    execute format('drop policy if exists %I on %I.%I', p.policyname, p.schemaname, p.tablename);
  end loop;
end;
$$;

alter table public.profiles    enable row level security;
alter table public.restaurants enable row level security;
alter table public.products    enable row level security;
alter table public.categories  enable row level security;
alter table public.orders      enable row level security;
alter table public.order_items enable row level security;

-- ---------- 6. Siyosatlar: profiles ----------
create policy profiles_select on public.profiles
  for select using (id = auth.uid() or public.is_admin());

create policy profiles_insert_self on public.profiles
  for insert with check (id = auth.uid() and role = 'customer');

create policy profiles_update_admin on public.profiles
  for update using (public.is_admin()) with check (public.is_admin());

-- ---------- 7. Siyosatlar: restaurants ----------
create policy restaurants_read on public.restaurants
  for select using (
    is_active
    or public.is_admin()
    or owner_id = auth.uid()
    or lower(coalesce(owner_email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

create policy restaurants_admin_write on public.restaurants
  for all using (public.is_admin()) with check (public.is_admin());

create policy restaurants_owner_update on public.restaurants
  for update
  using (
    owner_id = auth.uid()
    or lower(coalesce(owner_email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
  )
  with check (
    owner_id = auth.uid()
    or lower(coalesce(owner_email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

-- ---------- 8. Siyosatlar: categories va products ----------
create policy categories_read on public.categories
  for select using (true);

create policy categories_admin_write on public.categories
  for all using (public.is_admin()) with check (public.is_admin());

create policy products_read on public.products
  for select using (
    exists (
      select 1 from public.restaurants r
      where r.id = products.restaurant_id
        and (
          r.is_active
          or public.is_admin()
          or public.owns_restaurant(r.id)
        )
    )
  );

create policy products_write on public.products
  for all
  using (public.is_admin() or public.owns_restaurant(restaurant_id))
  with check (public.is_admin() or public.owns_restaurant(restaurant_id));

-- ---------- 9. Siyosatlar: orders va order_items ----------
-- Mijoz o'z buyurtmasini, restoran o'z buyurtmalarini,
-- kuryer tayyor (yoki o'ziga biriktirilgan) buyurtmalarni ko'radi.
create policy orders_read on public.orders
  for select using (
    customer_id = auth.uid()
    or public.is_admin()
    or public.owns_restaurant(restaurant_id)
    or courier_id = auth.uid()
    or (
      public.is_courier()
      and status = 'ready_for_pickup'
      and courier_id is null
    )
  );

create policy orders_admin_delete on public.orders
  for delete using (public.is_admin());

create policy order_items_read on public.order_items
  for select using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and (
          o.customer_id = auth.uid()
          or public.is_admin()
          or public.owns_restaurant(o.restaurant_id)
          or o.courier_id = auth.uid()
        )
    )
  );

-- ---------- 10. RPC: buyurtma holatini xavfsiz o'zgartirish ----------
drop function if exists public.set_order_status(uuid, text);

create function public.set_order_status(p_order_id uuid, p_new_status text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
  v_owner boolean;
  v_courier boolean;
  v_customer boolean;
begin
  select * into o from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Buyurtma topilmadi';
  end if;

  v_owner := public.owns_restaurant(o.restaurant_id);
  v_courier := o.courier_id = auth.uid();
  v_customer := o.customer_id = auth.uid();

  if public.is_admin() then
    null;
  elsif v_owner then
    if p_new_status not in ('accepted', 'preparing', 'ready_for_pickup', 'rejected', 'cancelled') then
      raise exception 'Restoran bu holatga o''tkaza olmaydi';
    end if;
    if o.status in ('delivered', 'cancelled', 'rejected') then
      raise exception 'Yakunlangan buyurtmani o''zgartirib bo''lmaydi';
    end if;
  elsif v_courier then
    if p_new_status not in ('picked_up', 'on_the_way', 'delivered') then
      raise exception 'Kuryer bu holatga o''tkaza olmaydi';
    end if;
    if o.status not in ('courier_assigned', 'picked_up', 'on_the_way') then
      raise exception 'Bu buyurtma hali kuryerga biriktirilmagan';
    end if;
  elsif v_customer then
    if p_new_status <> 'cancelled' then
      raise exception 'Mijoz faqat bekor qila oladi';
    end if;
    if o.status not in ('pending', 'accepted') then
      raise exception 'Bu bosqichda bekor qilib bo''lmaydi';
    end if;
  else
    raise exception 'Ruxsat yo''q';
  end if;

  update public.orders
  set status = p_new_status
  where id = p_order_id;
end;
$$;

revoke all on function public.set_order_status(uuid, text) from public;
grant execute on function public.set_order_status(uuid, text) to authenticated;

-- ---------- 11. RPC: kuryer buyurtmani qabul qilishi ----------
create or replace function public.claim_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
begin
  if not public.is_courier() then
    raise exception 'Faqat kuryer buyurtma qabul qila oladi';
  end if;

  select * into o from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Buyurtma topilmadi';
  end if;

  if o.status <> 'ready_for_pickup' then
    raise exception 'Buyurtma hali tayyor emas';
  end if;

  if o.courier_id is not null then
    raise exception 'Buyurtma allaqachon boshqa kuryerga biriktirilgan';
  end if;

  update public.orders
  set courier_id = auth.uid(),
      status = 'courier_assigned'
  where id = p_order_id;
end;
$$;

revoke all on function public.claim_order(uuid) from public;
grant execute on function public.claim_order(uuid) to authenticated;

-- ---------- 12. Demo hisoblar va restoran egasi ----------
-- Admin hisobi (o'zingizning email manzilingiz):
update public.profiles
set role = 'admin'
where lower(email) in ('oyatillosadullayev55@gmail.com', 'admin@foodgo.uz');

-- Demo restoran egasi (owner.foodgo@example.com) "Osh Markazi"ni boshqaradi:
update public.profiles
set role = 'restaurant'
where lower(email) = 'owner.foodgo@example.com';

update public.restaurants
set owner_email = 'owner.foodgo@example.com'
where id = 'b0000000-0000-4000-8000-000000000001';

-- Demo kuryer:
update public.profiles
set role = 'courier'
where lower(email) = 'courier.foodgo@example.com';

-- ---------- 13. Tekshiruv ----------
select
  (select count(*) from public.profiles)    as profiles,
  (select count(*) from public.restaurants) as restaurants,
  (select count(*) from public.products)    as products,
  (select count(*) from public.orders)      as orders;
