-- =============================================================
-- RSMS Sales Associate — Supabase SQL Migration
-- Phase 0: Foundation — Profiles, Stores, and Auth Setup
-- Run this entire file in your Supabase SQL Editor
-- =============================================================

-- EXTENSIONS
create extension if not exists "uuid-ossp";
create extension if not exists "pg_trgm";
create extension if not exists "unaccent";

-- CUSTOM TYPES
create type staff_role as enum ('sales_associate','boutique_manager','corporate_admin');
create type customer_tier as enum ('standard','vip','vvip');
create type communication_channel as enum ('push','sms','email','whatsapp','in_app');
create type payment_method as enum ('apple_pay','card','upi','cash','store_credit','gift_card','bank_transfer');
create type payment_status as enum ('pending','completed','failed','refunded');
create type transaction_status as enum ('draft','completed','voided','refunded');
create type receipt_type as enum ('digital','printed','gift');
create type appointment_type as enum ('in_store','video_consult','phone_call','remote_cart');
create type appointment_status as enum ('scheduled','confirmed','in_progress','completed','cancelled','no_show');
create type cart_status as enum ('draft','shared','viewed','converted','expired');
create type order_type as enum ('bopis','endless_aisle','ship_from_store','reservation');
create type order_status as enum ('pending','ready_for_pickup','packed','shipped','delivered','picked_up','cancelled');
create type warranty_type as enum ('standard','extended','brand_care');
create type warranty_status as enum ('active','expiring','expired','voided');
create type opportunity_status as enum ('new','acted_on','converted','dismissed');
create type urgency_level as enum ('low','medium','high');
create type product_category as enum ('Watches','Jewellery','Leather Goods','Accessories','Fragrance','Apparel','Home Decor','Eyewear');
create type client_event_type as enum ('boutique_visit','purchase','return_processed','exchange','appointment_booked','appointment_completed','remote_sell_session','curated_cart_viewed','wishlist_added','wishlist_fulfilled','warranty_registered','authentication_done','valuation_received','vip_event_attended','outreach_sent','feedback_provided');
create type relationship_type as enum ('spouse','child','parent','sibling','friend','colleague','other');

-- TABLE: stores
create table if not exists public.stores (
    id              uuid primary key default uuid_generate_v4(),
    name            text not null,
    code            text not null unique,
    address_line1   text not null,
    address_line2   text,
    city            text not null,
    state           text not null,
    postal_code     text not null,
    country         text not null default 'India',
    phone           text,
    email           text,
    latitude        double precision,
    longitude       double precision,
    is_active       boolean not null default true,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

create index if not exists stores_name_idx on public.stores using gin(to_tsvector('english', name));

-- TABLE: profiles
create table if not exists public.profiles (
    id              uuid primary key references auth.users(id) on delete cascade,
    first_name      text not null,
    last_name       text not null,
    email           text not null,
    role            staff_role not null default 'sales_associate',
    store_id        uuid references public.stores(id) on delete set null,
    avatar_url      text,
    is_active       boolean not null default true,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

create index if not exists profiles_store_id_idx on public.profiles(store_id);
create index if not exists profiles_role_idx on public.profiles(role);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
    insert into public.profiles (id, first_name, last_name, email, role)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'first_name', 'Associate'),
        coalesce(new.raw_user_meta_data->>'last_name', ''),
        new.email,
        coalesce((new.raw_user_meta_data->>'role')::staff_role, 'sales_associate')
    );
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

-- Updated_at trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger set_stores_updated_at before update on public.stores for each row execute procedure public.set_updated_at();
create trigger set_profiles_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();

-- RLS
alter table public.stores   enable row level security;
alter table public.profiles enable row level security;

create policy "Authenticated users can read stores" on public.stores for select using (auth.role() = 'authenticated');
create policy "Corporate admin can manage stores" on public.stores for all using (exists (select 1 from public.profiles where id = auth.uid() and role = 'corporate_admin'));
create policy "Users can read own profile" on public.profiles for select using (id = auth.uid());
create policy "Managers can read store profiles" on public.profiles for select using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('boutique_manager','corporate_admin') and (p.store_id = profiles.store_id or p.role = 'corporate_admin')));
create policy "Users can update own profile" on public.profiles for update using (id = auth.uid());

-- SEED: stores
insert into public.stores (name, code, address_line1, city, state, postal_code, country, latitude, longitude)
values
    ('RSMS Delhi Boutique',     'DLH', 'Select Citywalk, Saket',         'New Delhi',  'Delhi',       '110017', 'India', 28.5274, 77.2192),
    ('RSMS Mumbai Boutique',    'MUM', 'Palladium Mall, Lower Parel',     'Mumbai',     'Maharashtra', '400013', 'India', 18.9980, 72.8258),
    ('RSMS Bangalore Boutique', 'BLR', 'UB City, Vittal Mallya Rd',      'Bengaluru',  'Karnataka',   '560001', 'India', 12.9716, 77.5946),
    ('RSMS Chennai Boutique',   'CHN', 'Express Avenue, Royapettah',      'Chennai',    'Tamil Nadu',  '600002', 'India', 13.0569, 80.2628),
    ('RSMS Hyderabad Boutique', 'HYD', 'Jubilee Hills Road No. 36',       'Hyderabad',  'Telangana',   '500033', 'India', 17.4326, 78.4071)
on conflict (code) do nothing;
