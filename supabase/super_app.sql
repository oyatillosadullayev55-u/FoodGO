-- ============================================================
-- OsonGo super-app: magazinlar, ustalar, xizmatlar va Super Admin
--
-- Tartib:  1) seed_demo.sql  2) roles_setup.sql  3) super_app.sql
--          4) seed_super_demo.sql (ixtiyoriy demo ma'lumot)
--
-- Supabase Dashboard -> SQL Editor -> New query -> faylni to'liq
-- joylashtiring va "Run" bosing. Skript idempotent.
--
-- DIQQAT: roles_setup.sql qayta ishga tushirilsa, u eski RLS
-- siyosatlarini tiklaydi. Shundan keyin bu faylni ham qayta ishga
-- tushiring.
-- ============================================================

begin;

-- ---------- 1. Rollar ----------
do $$
declare
  c record;
begin
  for c in
    select con.conname
    from pg_constraint con
    where con.conrelid = 'public.profiles'::regclass
      and con.contype = 'c'
      and pg_get_constraintdef(con.oid) ilike '%role%'
  loop
    execute format('alter table public.profiles drop constraint %I', c.conname);
  end loop;
end;
$$;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('customer', 'courier', 'restaurant', 'shop', 'master', 'admin'));

alter table public.profiles
  add column if not exists is_blocked boolean not null default false;

-- ---------- 2. Hududlar ----------
create table if not exists public.regions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text not null default 'viloyat' check (kind in ('viloyat', 'shahar', 'tuman')),
  parent_id uuid references public.regions (id) on delete cascade,
  is_active boolean not null default true,
  sort_order int not null default 0
);

-- ---------- 3. Servislar (bosh sahifadagi bo'limlar) ----------
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  subtitle text,
  icon text not null default 'apps',
  route text,
  sort_order int not null default 0,
  is_active boolean not null default true
);

insert into public.services (code, title, subtitle, icon, route, sort_order) values
  ('food',     'Restoranlar',     'Ovqat',     'food',     '/customer/home/restaurants', 1),
  ('master',   'Ustalar',         'Xizmatlar', 'master',   '/customer/home/masters',     2),
  ('shop',     'Magazinlar',      'Do''konlar','shop',     '/customer/home/shops',       3),
  ('product',  'Mahsulotlar',     'Buyurtma',  'product',  '/customer/home/products',    4),
  ('delivery', 'Yetkazib berish', 'Kuryer',    'delivery', '/customer/home/delivery',    5),
  ('other',    'Boshqa',          'Xizmatlar', 'apps',     '/customer/home/services',    6)
on conflict (code) do nothing;

-- ---------- 4. Kategoriyalar: tur va subkategoriya ----------
alter table public.categories alter column id set default gen_random_uuid();
alter table public.categories
  add column if not exists kind text not null default 'food',
  add column if not exists parent_id uuid references public.categories (id) on delete set null;

alter table public.categories drop constraint if exists categories_kind_check;
alter table public.categories
  add constraint categories_kind_check check (kind in ('food', 'shop', 'master'));

-- ---------- 5. Hamkor do'konlar: restoran va magazin ----------
-- Magazin ham restaurants jadvalida: savat, buyurtma va kuryer oqimi bitta.
alter table public.restaurants alter column id set default gen_random_uuid();
alter table public.restaurants
  add column if not exists kind text not null default 'restaurant',
  add column if not exists delivery_time text,
  add column if not exists rating_count int not null default 0,
  add column if not exists region_id uuid references public.regions (id) on delete set null,
  add column if not exists commission_percent numeric(5, 2),
  -- Eski yozuvlar tasdiqlangan hisoblanadi, yangilari 'pending' bo'ladi.
  add column if not exists verification_status text not null default 'approved';

alter table public.restaurants
  alter column verification_status set default 'pending';
alter table public.restaurants drop constraint if exists restaurants_kind_check;
alter table public.restaurants
  add constraint restaurants_kind_check check (kind in ('restaurant', 'shop'));
alter table public.restaurants drop constraint if exists restaurants_verification_check;
alter table public.restaurants
  add constraint restaurants_verification_check
  check (verification_status in ('pending', 'approved', 'rejected'));

-- ---------- 6. Mahsulotlar: ombor qoldig'i ----------
alter table public.products alter column id set default gen_random_uuid();
alter table public.products
  add column if not exists stock int,
  add column if not exists unit text;
alter table public.products drop constraint if exists products_stock_check;
alter table public.products
  add constraint products_stock_check check (stock is null or stock >= 0);

-- ---------- 7. Ustalar ----------
create table if not exists public.masters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users (id) on delete set null,
  full_name text not null,
  category_id uuid references public.categories (id) on delete set null,
  phone text,
  photo_url text,
  about text,
  price_from int check (price_from is null or price_from >= 0),
  eta text,
  rating numeric(3, 2) not null default 0,
  rating_count int not null default 0,
  region_id uuid references public.regions (id) on delete set null,
  commission_percent numeric(5, 2),
  is_active boolean not null default true,
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users (id) on delete cascade,
  master_id uuid not null references public.masters (id) on delete cascade,
  customer_name text,
  phone text not null,
  address_text text not null,
  lat double precision,
  lng double precision,
  service_type text not null,
  description text,
  scheduled_at timestamptz,
  status text not null default 'new' check (status in
    ('new', 'accepted', 'on_the_way', 'in_progress', 'completed', 'rejected', 'cancelled')),
  price int check (price is null or price >= 0),
  commission_amount int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists service_requests_master_idx
  on public.service_requests (master_id, created_at desc);
create index if not exists service_requests_customer_idx
  on public.service_requests (customer_id, created_at desc);

-- ---------- 8. Baholar ----------
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users (id) on delete cascade,
  customer_name text,
  master_id uuid references public.masters (id) on delete cascade,
  restaurant_id uuid references public.restaurants (id) on delete cascade,
  order_id uuid unique references public.orders (id) on delete cascade,
  service_request_id uuid unique references public.service_requests (id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  check ((order_id is not null) <> (service_request_id is not null))
);

-- ---------- 9. Hamkor hujjatlari ----------
create table if not exists public.partner_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  doc_type text not null,
  file_path text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  admin_note text,
  created_at timestamptz not null default now()
);

-- ---------- 10. Shikoyatlar (nizolar) ----------
create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  order_id uuid references public.orders (id) on delete set null,
  service_request_id uuid references public.service_requests (id) on delete set null,
  subject text not null check (length(trim(subject)) > 0),
  body text not null check (length(trim(body)) > 0),
  status text not null default 'open' check (status in ('open', 'in_review', 'resolved', 'rejected')),
  resolution text,
  refund_amount int not null default 0 check (refund_amount >= 0),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- ---------- 11. Komissiya, tarif, aksiya ----------
create table if not exists public.commission_rules (
  id uuid primary key default gen_random_uuid(),
  service_code text not null unique references public.services (code) on update cascade on delete cascade,
  percent numeric(5, 2) not null check (percent between 0 and 100)
);

insert into public.commission_rules (service_code, percent) values
  ('food', 10), ('shop', 7), ('master', 12)
on conflict (service_code) do nothing;

create table if not exists public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  audience text not null check (audience in ('restaurant', 'shop', 'master', 'courier')),
  price int not null check (price >= 0),
  period_days int not null default 30 check (period_days > 0),
  features text,
  is_active boolean not null default true
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.subscription_plans (id) on delete restrict,
  user_id uuid not null references auth.users (id) on delete cascade,
  starts_at date not null default current_date,
  ends_at date not null,
  status text not null default 'active' check (status in ('active', 'expired', 'cancelled')),
  check (ends_at >= starts_at)
);

create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  service_code text references public.services (code) on update cascade on delete set null,
  discount_percent int check (discount_percent is null or discount_percent between 0 and 100),
  image_url text,
  starts_at date not null default current_date,
  ends_at date,
  is_active boolean not null default true,
  sort_order int not null default 0
);

-- ---------- 12. Xabarnomalar ----------
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  audience text check (audience in ('all', 'customer', 'courier', 'restaurant', 'shop', 'master')),
  user_id uuid references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  check (audience is not null or user_id is not null)
);
create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);

-- ---------- 13. Moliya ----------
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('commission', 'payout', 'refund', 'subscription')),
  amount int not null check (amount >= 0),
  user_id uuid references auth.users (id) on delete set null,
  order_id uuid references public.orders (id) on delete set null,
  service_request_id uuid references public.service_requests (id) on delete set null,
  note text,
  status text not null default 'pending' check (status in ('pending', 'done', 'cancelled')),
  created_at timestamptz not null default now()
);

alter table public.orders
  add column if not exists commission_amount int not null default 0;

-- ---------- 14. Kuryer joylashuvi ----------
create table if not exists public.courier_locations (
  courier_id uuid primary key references auth.users (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  updated_at timestamptz not null default now()
);

-- ============================================================
-- Yordamchi funksiyalar
-- ============================================================
create or replace function public.is_my_master(p_master_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.masters m
    where m.id = p_master_id and m.user_id = auth.uid()
  );
$$;

-- ============================================================
-- Triggerlar
-- ============================================================

-- Hamkor o'z tasdiq holati, komissiyasi va reytingini o'zgartira olmaydi.
create or replace function public.guard_partner_columns()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  -- Boshqa triggerdan (reyting hisoblash), SQL Editor yoki service-role dan
  -- kelgan o'zgarishlar va admin cheklanmaydi.
  if pg_trigger_depth() > 1 or auth.uid() is null or public.is_admin() then
    return new;
  end if;

  new.verification_status := old.verification_status;
  new.commission_percent := old.commission_percent;
  new.rating := old.rating;
  new.rating_count := old.rating_count;
  if tg_table_name = 'restaurants' then
    new.kind := old.kind;
    new.owner_id := old.owner_id;
    new.owner_email := old.owner_email;
  else
    new.user_id := old.user_id;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_restaurants on public.restaurants;
create trigger guard_restaurants
  before update on public.restaurants
  for each row execute function public.guard_partner_columns();

drop trigger if exists guard_masters on public.masters;
create trigger guard_masters
  before update on public.masters
  for each row execute function public.guard_partner_columns();

-- Bloklangan foydalanuvchi buyurtma bera olmaydi.
create or replace function public.reject_blocked_customer()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if exists (select 1 from public.profiles p where p.id = new.customer_id and p.is_blocked) then
    raise exception 'Hisobingiz bloklangan. Qo''llab-quvvatlash bilan bog''laning.';
  end if;
  return new;
end;
$$;

drop trigger if exists orders_reject_blocked on public.orders;
create trigger orders_reject_blocked
  before insert on public.orders
  for each row execute function public.reject_blocked_customer();

drop trigger if exists requests_reject_blocked on public.service_requests;
create trigger requests_reject_blocked
  before insert on public.service_requests
  for each row execute function public.reject_blocked_customer();

-- Tasdiqlanmagan yoki yopiq do'kondan buyurtma qabul qilinmaydi.
create or replace function public.require_approved_store()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if not exists (
    select 1 from public.restaurants r
    where r.id = new.restaurant_id
      and r.is_active and r.verification_status = 'approved'
  ) then
    raise exception 'Bu do''kon hozircha buyurtma qabul qilmaydi';
  end if;
  return new;
end;
$$;

drop trigger if exists orders_require_approved on public.orders;
create trigger orders_require_approved
  before insert on public.orders
  for each row execute function public.require_approved_store();

-- Ombor: buyurtma qatori qo'shilganda qoldiq kamayadi.
create or replace function public.take_stock()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_stock int;
  v_name text;
begin
  select stock, name into v_stock, v_name
  from public.products where id = new.product_id for update;

  if v_stock is null then
    return new; -- qoldiq yuritilmaydi
  end if;
  if v_stock < new.quantity then
    raise exception 'Omborda yetarli emas: % (qoldiq: %)', v_name, v_stock;
  end if;
  update public.products set stock = stock - new.quantity where id = new.product_id;
  return new;
end;
$$;

drop trigger if exists order_items_take_stock on public.order_items;
create trigger order_items_take_stock
  after insert on public.order_items
  for each row execute function public.take_stock();

-- Buyurtma holati: qoldiqni qaytarish, komissiya va mijozga xabar.
create or replace function public.on_order_status()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_percent numeric;
  v_kind text;
  v_owner uuid;
  v_label text;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  if new.status in ('cancelled', 'rejected') and old.status not in ('cancelled', 'rejected') then
    update public.products p
    set stock = p.stock + i.quantity
    from (
      select product_id, sum(quantity)::int as quantity
      from public.order_items where order_id = new.id group by product_id
    ) i
    where p.id = i.product_id and p.stock is not null;
  end if;

  if new.status = 'delivered' then
    select r.kind, r.commission_percent, r.owner_id
      into v_kind, v_percent, v_owner
    from public.restaurants r where r.id = new.restaurant_id;

    if v_percent is null then
      select percent into v_percent from public.commission_rules
      where service_code = case when v_kind = 'shop' then 'shop' else 'food' end;
    end if;

    new.commission_amount := round(coalesce(new.subtotal, 0) * coalesce(v_percent, 0) / 100);
    if new.commission_amount > 0 then
      insert into public.transactions (kind, amount, user_id, order_id, note)
      values ('commission', new.commission_amount, v_owner, new.id, 'Buyurtma komissiyasi');
    end if;
  end if;

  v_label := case new.status
    when 'accepted' then 'Buyurtmangiz qabul qilindi'
    when 'preparing' then 'Buyurtmangiz tayyorlanmoqda'
    when 'ready_for_pickup' then 'Buyurtmangiz tayyor'
    when 'courier_assigned' then 'Kuryer tayinlandi'
    when 'on_the_way' then 'Buyurtmangiz yo''lda'
    when 'delivered' then 'Buyurtmangiz yetkazildi'
    when 'rejected' then 'Buyurtmangiz rad etildi'
    when 'cancelled' then 'Buyurtmangiz bekor qilindi'
  end;
  if v_label is not null and new.customer_id is not null then
    insert into public.notifications (title, body, user_id)
    values (v_label, 'Buyurtma #' || left(new.id::text, 8), new.customer_id);
  end if;
  return new;
end;
$$;

drop trigger if exists orders_on_status on public.orders;
create trigger orders_on_status
  before update of status on public.orders
  for each row execute function public.on_order_status();

-- Baho qo'shilganda reyting qayta hisoblanadi.
create or replace function public.refresh_rating()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v public.reviews;
begin
  if tg_op = 'DELETE' then v := old; else v := new; end if;

  if v.master_id is not null then
    update public.masters m
    set rating = coalesce(s.avg, 0), rating_count = s.cnt
    from (select round(avg(rating), 2) as avg, count(*)::int as cnt
          from public.reviews where master_id = v.master_id) s
    where m.id = v.master_id;
  end if;

  if v.restaurant_id is not null then
    update public.restaurants r
    set rating = coalesce(s.avg, 0), rating_count = s.cnt
    from (select round(avg(rating), 1) as avg, count(*)::int as cnt
          from public.reviews where restaurant_id = v.restaurant_id) s
    where r.id = v.restaurant_id;
  end if;
  return null;
end;
$$;

drop trigger if exists reviews_refresh_rating on public.reviews;
create trigger reviews_refresh_rating
  after insert or update or delete on public.reviews
  for each row execute function public.refresh_rating();

-- Shikoyat qaroriga ko'ra qaytariladigan summa moliyaga yoziladi.
create or replace function public.on_complaint_resolved()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.status in ('resolved', 'rejected') and old.status not in ('resolved', 'rejected') then
    new.resolved_at := now();
    if new.status = 'resolved' and new.refund_amount > 0 then
      insert into public.transactions (kind, amount, user_id, order_id, service_request_id, note)
      values ('refund', new.refund_amount, new.user_id, new.order_id, new.service_request_id,
              'Shikoyat bo''yicha qaytarish');
    end if;
    insert into public.notifications (title, body, user_id)
    values ('Shikoyatingiz ko''rib chiqildi',
            coalesce(nullif(trim(new.resolution), ''), new.subject), new.user_id);
  end if;
  return new;
end;
$$;

drop trigger if exists complaints_on_resolved on public.complaints;
create trigger complaints_on_resolved
  before update on public.complaints
  for each row execute function public.on_complaint_resolved();

-- ============================================================
-- RPC funksiyalar
-- ============================================================
create or replace function public.create_service_request(
  p_master_id uuid,
  p_service_type text,
  p_address_text text,
  p_phone text,
  p_description text default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_scheduled_at timestamptz default null
)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_id uuid;
  v_name text;
  v_master public.masters;
begin
  if auth.uid() is null then
    raise exception 'Avval tizimga kiring';
  end if;
  if length(trim(coalesce(p_address_text, ''))) < 5 then
    raise exception 'Manzilni to''liq kiriting';
  end if;
  if length(regexp_replace(coalesce(p_phone, ''), '\D', '', 'g')) < 9 then
    raise exception 'Telefon raqami noto''g''ri';
  end if;
  if length(trim(coalesce(p_service_type, ''))) = 0 then
    raise exception 'Xizmat turini kiriting';
  end if;

  select * into v_master from public.masters
  where id = p_master_id and is_active and verification_status = 'approved';
  if not found then
    raise exception 'Usta hozircha buyurtma qabul qilmaydi';
  end if;

  select full_name into v_name from public.profiles where id = auth.uid();

  insert into public.service_requests
    (customer_id, master_id, customer_name, phone, address_text, lat, lng,
     service_type, description, scheduled_at)
  values
    (auth.uid(), p_master_id, v_name, trim(p_phone), trim(p_address_text), p_lat, p_lng,
     trim(p_service_type), nullif(trim(coalesce(p_description, '')), ''), p_scheduled_at)
  returning id into v_id;

  if v_master.user_id is not null then
    insert into public.notifications (title, body, user_id)
    values ('Yangi xizmat buyurtmasi', trim(p_service_type), v_master.user_id);
  end if;
  return v_id;
end;
$$;

create or replace function public.set_service_status(
  p_request_id uuid,
  p_status text,
  p_price int default null
)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  r public.service_requests;
  v_master boolean;
  v_allowed boolean := false;
  v_percent numeric;
  v_user uuid;
  v_commission int := 0;
begin
  select * into r from public.service_requests where id = p_request_id for update;
  if not found then
    raise exception 'Buyurtma topilmadi';
  end if;
  if r.status in ('completed', 'rejected', 'cancelled') then
    raise exception 'Yakunlangan buyurtmani o''zgartirib bo''lmaydi';
  end if;

  v_master := public.is_my_master(r.master_id);

  if public.is_admin() then
    v_allowed := true;
  elsif v_master then
    v_allowed := (r.status = 'new' and p_status in ('accepted', 'rejected'))
      or (r.status = 'accepted' and p_status in ('on_the_way', 'in_progress', 'cancelled'))
      or (r.status = 'on_the_way' and p_status in ('in_progress', 'cancelled'))
      or (r.status = 'in_progress' and p_status = 'completed');
  elsif r.customer_id = auth.uid() then
    v_allowed := p_status = 'cancelled' and r.status in ('new', 'accepted');
  else
    raise exception 'Ruxsat yo''q';
  end if;

  if not v_allowed then
    raise exception 'Bu holatga o''tkazib bo''lmaydi';
  end if;

  if p_status = 'completed' then
    if coalesce(p_price, r.price, 0) <= 0 then
      raise exception 'Ish narxini kiriting';
    end if;
    select m.commission_percent, m.user_id into v_percent, v_user
    from public.masters m where m.id = r.master_id;
    if v_percent is null then
      select percent into v_percent from public.commission_rules where service_code = 'master';
    end if;
    v_commission := round(coalesce(p_price, r.price) * coalesce(v_percent, 0) / 100);
  end if;

  update public.service_requests
  set status = p_status,
      price = coalesce(p_price, price),
      commission_amount = v_commission,
      updated_at = now()
  where id = p_request_id;

  if v_commission > 0 then
    insert into public.transactions (kind, amount, user_id, service_request_id, note)
    values ('commission', v_commission, v_user, p_request_id, 'Xizmat komissiyasi');
  end if;

  if r.customer_id <> auth.uid() then
    insert into public.notifications (title, body, user_id)
    values (
      case p_status
        when 'accepted' then 'Usta buyurtmangizni qabul qildi'
        when 'on_the_way' then 'Usta yo''lga chiqdi'
        when 'in_progress' then 'Ish boshlandi'
        when 'completed' then 'Ish yakunlandi'
        when 'rejected' then 'Usta buyurtmani rad etdi'
        else 'Xizmat buyurtmasi bekor qilindi'
      end,
      r.service_type, r.customer_id);
  end if;
end;
$$;

create or replace function public.submit_review(
  p_rating int,
  p_comment text default null,
  p_order_id uuid default null,
  p_service_request_id uuid default null
)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_name text;
  v_restaurant uuid;
  v_master uuid;
begin
  if p_rating is null or p_rating not between 1 and 5 then
    raise exception 'Baho 1 dan 5 gacha bo''lishi kerak';
  end if;
  if (p_order_id is null) = (p_service_request_id is null) then
    raise exception 'Bitta buyurtma tanlanishi kerak';
  end if;

  if p_order_id is not null then
    select restaurant_id into v_restaurant from public.orders
    where id = p_order_id and customer_id = auth.uid() and status = 'delivered';
    if v_restaurant is null then
      raise exception 'Faqat yetkazilgan buyurtmangizni baholay olasiz';
    end if;
    if exists (select 1 from public.reviews where order_id = p_order_id) then
      raise exception 'Bu buyurtma allaqachon baholangan';
    end if;
  else
    select master_id into v_master from public.service_requests
    where id = p_service_request_id and customer_id = auth.uid() and status = 'completed';
    if v_master is null then
      raise exception 'Faqat yakunlangan xizmatni baholay olasiz';
    end if;
    if exists (select 1 from public.reviews where service_request_id = p_service_request_id) then
      raise exception 'Bu xizmat allaqachon baholangan';
    end if;
  end if;

  select full_name into v_name from public.profiles where id = auth.uid();

  insert into public.reviews
    (customer_id, customer_name, master_id, restaurant_id, order_id, service_request_id, rating, comment)
  values
    (auth.uid(), v_name, v_master, v_restaurant, p_order_id, p_service_request_id,
     p_rating, nullif(trim(coalesce(p_comment, '')), ''));
end;
$$;

-- Buyurtmaga biriktirilgan kuryer (faqat shu buyurtma ishtirokchilari uchun).
create or replace function public.get_order_courier(p_order_id uuid)
returns table (full_name text, phone text, lat double precision, lng double precision, updated_at timestamptz)
language plpgsql stable security definer set search_path = public
as $$
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order_id;
  if not found or not (
    o.customer_id = auth.uid()
    or public.is_admin()
    or public.owns_restaurant(o.restaurant_id)
  ) then
    raise exception 'Ruxsat yo''q';
  end if;

  return query
  select p.full_name::text, p.phone::text,
         -- Joylashuv faqat yetkazish davom etayotganda ko'rinadi.
         case when o.status in ('courier_assigned', 'picked_up', 'on_the_way') then l.lat end,
         case when o.status in ('courier_assigned', 'picked_up', 'on_the_way') then l.lng end,
         l.updated_at
  from public.profiles p
  left join public.courier_locations l on l.courier_id = p.id
  where p.id = o.courier_id
    and o.status in ('courier_assigned', 'picked_up', 'on_the_way', 'delivered');
end;
$$;

-- Admin: shubhali holatlar.
create or replace function public.fraud_signals()
returns table (signal text, severity text, subject_id uuid, subject text, detail text, hits int)
language plpgsql stable security definer set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Faqat admin uchun';
  end if;

  return query
  -- 7 kunda 3+ bekor qilingan buyurtma
  select 'many_cancellations'::text, 'medium'::text, o.customer_id,
         coalesce(max(p.full_name), 'Foydalanuvchi')::text,
         '7 kunda ko''p bekor qilingan buyurtma'::text, count(*)::int
  from public.orders o
  left join public.profiles p on p.id = o.customer_id
  where o.status = 'cancelled' and o.created_at > now() - interval '7 days'
  group by o.customer_id
  having count(*) >= 3

  union all
  -- 1 soatda 5+ buyurtma
  select 'order_burst', 'high', o.customer_id,
         coalesce(max(p.full_name), 'Foydalanuvchi')::text,
         '1 soat ichida ko''p buyurtma', count(*)::int
  from public.orders o
  left join public.profiles p on p.id = o.customer_id
  where o.created_at > now() - interval '1 hour'
  group by o.customer_id
  having count(*) >= 5

  union all
  -- O'rtachadan 5 barobar katta faol buyurtma
  select 'unusual_amount', 'medium', o.id,
         ('Buyurtma #' || left(o.id::text, 8))::text,
         ('Summa o''rtachadan 5 barobardan katta: ' || o.total)::text, 1
  from public.orders o
  where o.created_at > now() - interval '30 days'
    and o.status not in ('cancelled', 'rejected')
    and o.total > 5 * (
      select avg(x.total) from public.orders x
      where x.created_at > now() - interval '90 days' and x.id <> o.id
        and x.status not in ('cancelled', 'rejected'))

  union all
  -- Bitta telefon raqami 3+ hisobda
  select 'shared_phone', 'high', (array_agg(o.customer_id))[1],
         o.phone::text, 'Bitta telefon bir nechta hisobda',
         count(distinct o.customer_id)::int
  from public.orders o
  where o.created_at > now() - interval '30 days'
  group by o.phone
  having count(distinct o.customer_id) >= 3;
end;
$$;

-- Admin: umumiy statistika.
create or replace function public.admin_analytics(p_days int default 14)
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
declare
  v_days int := least(greatest(coalesce(p_days, 14), 1), 365);
  v_from date;
  v_result jsonb;
begin
  if not public.is_admin() then
    raise exception 'Faqat admin uchun';
  end if;
  v_from := (now() at time zone 'Asia/Tashkent')::date - (v_days - 1);

  with o as (
    select *, (created_at at time zone 'Asia/Tashkent')::date as day
    from public.orders
    where (created_at at time zone 'Asia/Tashkent')::date >= v_from
  ),
  s as (
    select *, (created_at at time zone 'Asia/Tashkent')::date as day
    from public.service_requests
    where (created_at at time zone 'Asia/Tashkent')::date >= v_from
  ),
  daily as (
    select d::date as day,
           count(o.id)::int as orders,
           coalesce(sum(o.total) filter (where o.status = 'delivered'), 0)::bigint as revenue
    from generate_series(v_from::timestamp, (v_from + (v_days - 1))::timestamp, interval '1 day') d
    left join o on o.day = d::date
    group by 1 order by 1
  ),
  top as (
    select r.name, count(*)::int as orders,
           coalesce(sum(o.total) filter (where o.status = 'delivered'), 0)::bigint as revenue
    from o join public.restaurants r on r.id = o.restaurant_id
    group by r.id, r.name order by revenue desc, orders desc limit 5
  )
  select jsonb_build_object(
    'users', (select count(*) from public.profiles),
    'stores', (select count(*) from public.restaurants where verification_status = 'approved'),
    'masters', (select count(*) from public.masters where verification_status = 'approved'),
    'pending_partners',
      (select count(*) from public.restaurants where verification_status = 'pending')
      + (select count(*) from public.masters where verification_status = 'pending'),
    'open_complaints', (select count(*) from public.complaints where status in ('open', 'in_review')),
    'orders', (select count(*) from o),
    'delivered', (select count(*) from o where status = 'delivered'),
    'cancelled', (select count(*) from o where status in ('cancelled', 'rejected')),
    'service_requests', (select count(*) from s),
    'revenue',
      (select coalesce(sum(total), 0) from o where status = 'delivered')
      + (select coalesce(sum(price), 0) from s where status = 'completed'),
    'commission',
      (select coalesce(sum(commission_amount), 0) from o where status = 'delivered')
      + (select coalesce(sum(commission_amount), 0) from s where status = 'completed'),
    'daily', (select coalesce(jsonb_agg(to_jsonb(daily)), '[]'::jsonb) from daily),
    'top_stores', (select coalesce(jsonb_agg(to_jsonb(top)), '[]'::jsonb) from top)
  ) into v_result;
  return v_result;
end;
$$;

revoke all on function public.create_service_request(uuid, text, text, text, text, double precision, double precision, timestamptz) from public, anon;
revoke all on function public.set_service_status(uuid, text, int) from public, anon;
revoke all on function public.submit_review(int, text, uuid, uuid) from public, anon;
revoke all on function public.get_order_courier(uuid) from public, anon;
revoke all on function public.fraud_signals() from public, anon;
revoke all on function public.admin_analytics(int) from public, anon;
grant execute on function public.create_service_request(uuid, text, text, text, text, double precision, double precision, timestamptz) to authenticated;
grant execute on function public.set_service_status(uuid, text, int) to authenticated;
grant execute on function public.submit_review(int, text, uuid, uuid) to authenticated;
grant execute on function public.get_order_courier(uuid) to authenticated;
grant execute on function public.fraud_signals() to authenticated;
grant execute on function public.admin_analytics(int) to authenticated;

-- ============================================================
-- RLS siyosatlari
-- ============================================================
alter table public.regions            enable row level security;
alter table public.services           enable row level security;
alter table public.masters            enable row level security;
alter table public.service_requests   enable row level security;
alter table public.reviews            enable row level security;
alter table public.partner_documents  enable row level security;
alter table public.complaints         enable row level security;
alter table public.commission_rules   enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.subscriptions      enable row level security;
alter table public.promotions         enable row level security;
alter table public.notifications      enable row level security;
alter table public.transactions       enable row level security;
alter table public.courier_locations  enable row level security;

-- Admin hamma yangi jadvalni to'liq boshqaradi.
do $$
declare
  t text;
begin
  foreach t in array array[
    'regions', 'services', 'masters', 'service_requests', 'reviews',
    'partner_documents', 'complaints', 'commission_rules', 'subscription_plans',
    'subscriptions', 'promotions', 'notifications', 'transactions', 'courier_locations'
  ]
  loop
    execute format('drop policy if exists %I on public.%I', t || '_admin', t);
    execute format(
      'create policy %I on public.%I for all using (public.is_admin()) with check (public.is_admin())',
      t || '_admin', t);
  end loop;
end;
$$;

drop policy if exists regions_read on public.regions;
create policy regions_read on public.regions for select using (is_active);

drop policy if exists services_read on public.services;
create policy services_read on public.services for select using (is_active);

drop policy if exists masters_read on public.masters;
create policy masters_read on public.masters for select
  using ((is_active and verification_status = 'approved') or user_id = auth.uid());

drop policy if exists masters_owner_update on public.masters;
create policy masters_owner_update on public.masters for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Buyurtma yaratish va holat o'zgarishi faqat RPC orqali.
drop policy if exists service_requests_read on public.service_requests;
create policy service_requests_read on public.service_requests for select
  using (customer_id = auth.uid() or public.is_my_master(master_id));

drop policy if exists reviews_read on public.reviews;
create policy reviews_read on public.reviews for select using (true);

drop policy if exists documents_own_read on public.partner_documents;
create policy documents_own_read on public.partner_documents for select
  using (user_id = auth.uid());
drop policy if exists documents_own_insert on public.partner_documents;
create policy documents_own_insert on public.partner_documents for insert
  with check (user_id = auth.uid() and status = 'pending');

drop policy if exists complaints_own_read on public.complaints;
create policy complaints_own_read on public.complaints for select
  using (user_id = auth.uid());
drop policy if exists complaints_own_insert on public.complaints;
create policy complaints_own_insert on public.complaints for insert
  with check (
    user_id = auth.uid() and status = 'open' and refund_amount = 0 and resolution is null
    and (order_id is null or exists (
      select 1 from public.orders o where o.id = order_id and o.customer_id = auth.uid()))
    and (service_request_id is null or exists (
      select 1 from public.service_requests s
      where s.id = service_request_id and s.customer_id = auth.uid()))
  );

drop policy if exists commission_read on public.commission_rules;
create policy commission_read on public.commission_rules for select
  using (auth.uid() is not null);

drop policy if exists plans_read on public.subscription_plans;
create policy plans_read on public.subscription_plans for select using (is_active);

drop policy if exists subscriptions_own on public.subscriptions;
create policy subscriptions_own on public.subscriptions for select
  using (user_id = auth.uid());

drop policy if exists promotions_read on public.promotions;
create policy promotions_read on public.promotions for select
  using (is_active and starts_at <= current_date and (ends_at is null or ends_at >= current_date));

drop policy if exists notifications_read on public.notifications;
create policy notifications_read on public.notifications for select
  using (
    user_id = auth.uid()
    or (user_id is null and (audience = 'all' or audience = public.current_user_role()))
  );

drop policy if exists transactions_own on public.transactions;
create policy transactions_own on public.transactions for select
  using (user_id = auth.uid());

drop policy if exists courier_location_own on public.courier_locations;
create policy courier_location_own on public.courier_locations for all
  using (courier_id = auth.uid() and public.is_courier())
  with check (courier_id = auth.uid() and public.is_courier());

-- Do'konlar: mijoz faqat tasdiqlangan va faolini ko'radi.
-- Egalik faqat aniq email yoki owner_id mosligi bilan aniqlanadi.
drop policy if exists restaurants_read on public.restaurants;
create policy restaurants_read on public.restaurants for select
  using (
    (is_active and verification_status = 'approved')
    or public.is_admin()
    or owner_id = auth.uid()
    or lower(owner_email) = lower(auth.jwt() ->> 'email')
  );

drop policy if exists restaurants_owner_update on public.restaurants;
create policy restaurants_owner_update on public.restaurants for update
  using (owner_id = auth.uid() or lower(owner_email) = lower(auth.jwt() ->> 'email'))
  with check (owner_id = auth.uid() or lower(owner_email) = lower(auth.jwt() ->> 'email'));

drop policy if exists products_read on public.products;
create policy products_read on public.products for select
  using (
    exists (
      select 1 from public.restaurants r
      where r.id = products.restaurant_id
        and (
          (r.is_active and r.verification_status = 'approved')
          or public.is_admin()
          or public.owns_restaurant(r.id)
        )
    )
  );

commit;

-- ---------- Hujjatlar uchun yopiq storage bucket ----------
insert into storage.buckets (id, name, public)
values ('partner-docs', 'partner-docs', false)
on conflict (id) do nothing;

drop policy if exists partner_docs_upload on storage.objects;
create policy partner_docs_upload on storage.objects for insert to authenticated
  with check (bucket_id = 'partner-docs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists partner_docs_read on storage.objects;
create policy partner_docs_read on storage.objects for select to authenticated
  using (
    bucket_id = 'partner-docs'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
  );
