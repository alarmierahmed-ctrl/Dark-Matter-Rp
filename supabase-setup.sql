-- Dark Matter - Supabase setup
-- IMPORTANT: replace YOUR_OWNER_EMAIL@example.com before running this file.

create extension if not exists pgcrypto;

create table if not exists public.site_admins (
    email text primary key,
    created_at timestamptz not null default now()
);

create table if not exists public.supervisors (
    email text primary key,
    added_by uuid references auth.users(id) on delete set null,
    created_at timestamptz not null default now()
);

create table if not exists public.orders (
    id uuid primary key default gen_random_uuid(),
    order_number text unique default ('DM-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))),
    buyer_id uuid not null references auth.users(id) on delete cascade,
    buyer_email text,
    buyer_name text,
    product_name text not null,
    price numeric(10,2) not null default 0,
    status text not null default 'بانتظار الدفع',
    payment_status text not null default 'pending',
    payment_id text,
    received_by uuid references auth.users(id) on delete set null,
    received_by_email text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

insert into public.site_admins(email)
values (lower('YOUR_OWNER_EMAIL@example.com'))
on conflict (email) do nothing;

create or replace function public.is_site_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.site_admins
        where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    );
$$;

create or replace function public.is_site_supervisor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.supervisors
        where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    );
$$;

grant execute on function public.is_site_owner() to authenticated;
grant execute on function public.is_site_supervisor() to authenticated;

alter table public.site_admins enable row level security;
alter table public.supervisors enable row level security;
alter table public.orders enable row level security;

drop policy if exists "site_admins_read_owner" on public.site_admins;
create policy "site_admins_read_owner"
on public.site_admins
for select
to authenticated
using (
    public.is_site_owner()
    or lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
);

drop policy if exists "supervisors_read_self_or_owner" on public.supervisors;
create policy "supervisors_read_self_or_owner"
on public.supervisors
for select
to authenticated
using (
    public.is_site_owner()
    or lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
);

drop policy if exists "supervisors_insert_owner" on public.supervisors;
create policy "supervisors_insert_owner"
on public.supervisors
for insert
to authenticated
with check (public.is_site_owner());

drop policy if exists "supervisors_delete_owner" on public.supervisors;
create policy "supervisors_delete_owner"
on public.supervisors
for delete
to authenticated
using (public.is_site_owner());

drop policy if exists "orders_insert_buyer" on public.orders;
create policy "orders_insert_buyer"
on public.orders
for insert
to authenticated
with check (buyer_id = auth.uid());

drop policy if exists "orders_select_buyer_or_staff" on public.orders;
create policy "orders_select_buyer_or_staff"
on public.orders
for select
to authenticated
using (
    buyer_id = auth.uid()
    or public.is_site_owner()
    or public.is_site_supervisor()
);

drop policy if exists "orders_update_staff" on public.orders;
create policy "orders_update_staff"
on public.orders
for update
to authenticated
using (
    public.is_site_owner()
    or public.is_site_supervisor()
)
with check (
    public.is_site_owner()
    or public.is_site_supervisor()
);

drop policy if exists "orders_delete_owner" on public.orders;
create policy "orders_delete_owner"
on public.orders
for delete
to authenticated
using (public.is_site_owner());

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
before update on public.orders
for each row
execute function public.set_updated_at();

-- Real-time order updates
alter publication supabase_realtime add table public.orders;
