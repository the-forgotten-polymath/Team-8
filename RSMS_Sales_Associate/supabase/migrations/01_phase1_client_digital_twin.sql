-- =============================================================
-- RSMS Sales Associate — Supabase SQL Migration
-- Phase 1: Client Digital Twin (Epic S1 Core)
-- =============================================================

-- TABLE: clients
create table if not exists public.clients (
    id                  uuid primary key default uuid_generate_v4(),
    customer_id         uuid,
    first_name          text not null,
    last_name           text not null,
    email               text,
    phone               text,
    date_of_birth       date,
    tier                customer_tier not null default 'standard',
    lifetime_spend      numeric(12,2) not null default 0.00,
    preferred_store     uuid references public.stores(id),
    preferred_advisor   uuid references public.profiles(id),
    created_at          timestamp with time zone default now(),
    updated_at          timestamp with time zone default now()
);

-- Search Index (pg_trgm)
create index idx_clients_search on public.clients using gin (
    first_name gin_trgm_ops,
    last_name gin_trgm_ops,
    email gin_trgm_ops,
    phone gin_trgm_ops
);

-- TABLE: client_preferences
create table if not exists public.client_preferences (
    client_id               uuid primary key references public.clients(id) on delete cascade,
    preferred_brands        text[] default '{}',
    preferred_categories    product_category[] default '{}',
    preferred_colors        text[] default '{}',
    preferred_materials     text[] default '{}',
    communication_channel   communication_channel default 'email',
    language_preference     text default 'en',
    shopping_occasions      jsonb default '[]',
    anniversary_date        date,
    birthday_date           date,
    notes                   text
);

-- TABLE: client_sizes
create table if not exists public.client_sizes (
    client_id   uuid primary key references public.clients(id) on delete cascade,
    ring        text,
    dress       text,
    suit        text,
    shirt       text,
    shoes       text,
    wrist       text,
    custom      jsonb default '{}'
);

-- TABLE: client_events
create table if not exists public.client_events (
    id                      uuid primary key default uuid_generate_v4(),
    client_id               uuid not null references public.clients(id) on delete cascade,
    date                    timestamp with time zone default now(),
    type                    client_event_type not null,
    title                   text not null,
    description             text not null,
    location                text,
    performed_by            uuid references public.profiles(id),
    linked_product_twin_id  uuid,
    metadata                jsonb
);

-- TABLE: wishlist_items
create table if not exists public.wishlist_items (
    id                  uuid primary key default uuid_generate_v4(),
    client_id           uuid not null references public.clients(id) on delete cascade,
    sku                 text not null,
    product_name        text not null,
    added_date          timestamp with time zone default now(),
    added_by            uuid references public.profiles(id),
    is_available        boolean default false,
    available_stores    uuid[] default '{}',
    notify_on_restock   boolean default false,
    notes               text
);

-- TABLE: consent_records
create table if not exists public.consent_records (
    client_id                       uuid primary key references public.clients(id) on delete cascade,
    marketing_email                 boolean default false,
    marketing_sms                   boolean default false,
    marketing_whatsapp              boolean default false,
    marketing_push                  boolean default false,
    data_processing                 boolean default false,
    profiling_for_recommendations   boolean default false,
    consent_date                    timestamp with time zone default now(),
    consent_version                 text not null,
    withdrawn_date                  timestamp with time zone
);

-- TABLE: gdpr_flags
create table if not exists public.gdpr_flags (
    client_id                   uuid primary key references public.clients(id) on delete cascade,
    can_store                   boolean default true,
    can_process                 boolean default true,
    can_profile                 boolean default false,
    right_to_erasure_requested  boolean default false,
    export_requested            boolean default false
);

-- TABLE: owned_products
create table if not exists public.owned_products (
    id                          uuid primary key default uuid_generate_v4(),
    client_id                   uuid not null references public.clients(id) on delete cascade,
    twin_id                     uuid not null, -- Links to product twins
    product_name                text not null,
    serial_number               text,
    purchase_date               timestamp with time zone default now(),
    purchase_store              uuid references public.stores(id),
    purchase_price              numeric(12,2) not null,
    current_warranty_status     warranty_status not null default 'active'
);

-- ENABLE ROW LEVEL SECURITY
alter table public.clients enable row level security;
alter table public.client_preferences enable row level security;
alter table public.client_sizes enable row level security;
alter table public.client_events enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.consent_records enable row level security;
alter table public.gdpr_flags enable row level security;
alter table public.owned_products enable row level security;

-- POLICIES (Simplistic for Phase 1: All authenticated staff can access all clients)
-- In a real scenario, restrict to store_id or territory.
create policy "Staff can view all clients" on public.clients for select using (auth.role() = 'authenticated');
create policy "Staff can insert clients" on public.clients for insert with check (auth.role() = 'authenticated');
create policy "Staff can update clients" on public.clients for update using (auth.role() = 'authenticated');

create policy "Staff can view client preferences" on public.client_preferences for select using (auth.role() = 'authenticated');
create policy "Staff can insert client preferences" on public.client_preferences for insert with check (auth.role() = 'authenticated');
create policy "Staff can update client preferences" on public.client_preferences for update using (auth.role() = 'authenticated');

create policy "Staff can view client sizes" on public.client_sizes for select using (auth.role() = 'authenticated');
create policy "Staff can insert client sizes" on public.client_sizes for insert with check (auth.role() = 'authenticated');
create policy "Staff can update client sizes" on public.client_sizes for update using (auth.role() = 'authenticated');

create policy "Staff can view client events" on public.client_events for select using (auth.role() = 'authenticated');
create policy "Staff can insert client events" on public.client_events for insert with check (auth.role() = 'authenticated');

create policy "Staff can view wishlist items" on public.wishlist_items for select using (auth.role() = 'authenticated');
create policy "Staff can insert wishlist items" on public.wishlist_items for insert with check (auth.role() = 'authenticated');
create policy "Staff can delete wishlist items" on public.wishlist_items for delete using (auth.role() = 'authenticated');

create policy "Staff can view consent records" on public.consent_records for select using (auth.role() = 'authenticated');
create policy "Staff can insert consent records" on public.consent_records for insert with check (auth.role() = 'authenticated');
create policy "Staff can update consent records" on public.consent_records for update using (auth.role() = 'authenticated');

create policy "Staff can view gdpr flags" on public.gdpr_flags for select using (auth.role() = 'authenticated');
create policy "Staff can insert gdpr flags" on public.gdpr_flags for insert with check (auth.role() = 'authenticated');
create policy "Staff can update gdpr flags" on public.gdpr_flags for update using (auth.role() = 'authenticated');

create policy "Staff can view owned products" on public.owned_products for select using (auth.role() = 'authenticated');
create policy "Staff can insert owned products" on public.owned_products for insert with check (auth.role() = 'authenticated');
