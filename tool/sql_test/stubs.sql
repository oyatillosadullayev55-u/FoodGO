-- Supabase muhitining testga yetarli soxta nusxasi.
-- Asosiy jadvallar tuzilishi ilova kodidan tiklangan (repoda DDL yo'q).
create role anon;
create role authenticated;

create schema auth;
create table auth.users (
  id uuid primary key,
  email text,
  raw_user_meta_data jsonb not null default '{}'
);
create function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create function auth.jwt() returns jsonb language sql stable as
  $$ select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb $$;

create schema storage;
create table storage.buckets (id text primary key, name text, public boolean);
create table storage.objects (
  id serial primary key,
  bucket_id text,
  name text
);
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language sql immutable as
  $$ select (string_to_array(name, '/'))[1 : array_length(string_to_array(name, '/'), 1) - 1] $$;

grant usage on schema public, auth, storage to anon, authenticated;
grant all on all tables in schema storage to anon, authenticated;
grant all on all sequences in schema storage to anon, authenticated;
alter default privileges in schema public grant all on tables to anon, authenticated;
alter default privileges in schema public grant execute on functions to anon, authenticated;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'customer'
    check (role in ('customer', 'courier', 'restaurant', 'admin')),
  full_name text,
  phone text
);
create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  address text,
  lat double precision,
  lng double precision,
  image_url text,
  rating numeric(2, 1) not null default 0,
  open_time time,
  close_time time
);
create table public.categories (
  id uuid primary key,
  name text not null,
  icon text,
  sort_order int not null default 0
);
create table public.products (
  id uuid primary key,
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  category_id uuid references public.categories (id),
  name text not null,
  price int not null,
  description text,
  image_url text,
  is_available boolean not null default true
);
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users (id),
  restaurant_id uuid not null references public.restaurants (id),
  status text not null default 'pending',
  address_text text not null,
  phone text not null,
  note text,
  subtotal int not null,
  delivery_fee int not null,
  total int not null,
  lat double precision,
  lng double precision,
  created_at timestamptz not null default now()
);
create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid not null references public.products (id),
  name_snapshot text not null,
  price_snapshot int not null,
  quantity int not null
);

-- Serverdagi create_order() o'rnini bosuvchi sodda funksiya.
create function public.test_create_order(p_restaurant uuid, p_product uuid, p_qty int)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; p public.products;
begin
  select * into p from public.products where id = p_product;
  insert into public.orders (customer_id, restaurant_id, address_text, phone, subtotal, delivery_fee, total)
  values (auth.uid(), p_restaurant, 'Test manzil', '+998901112233', p.price * p_qty, 10000, p.price * p_qty + 10000)
  returning id into v_id;
  insert into public.order_items (order_id, product_id, name_snapshot, price_snapshot, quantity)
  values (v_id, p.id, p.name, p.price, p_qty);
  return v_id;
end $$;
