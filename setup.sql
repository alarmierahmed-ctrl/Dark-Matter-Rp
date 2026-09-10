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
  order_number text unique default ('DM-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,8))),
  buyer_id uuid not null references auth.users(id) on delete cascade,
  buyer_email text,
  buyer_name text,
  product_name text not null,
  price numeric(10,2) not null default 22.99,
  amount_halalas integer not null default 2299,
  currency text not null default 'SAR',
  status text not null default 'بانتظار الدفع',
  payment_status text not null default 'pending',
  payment_id text,
  received_by uuid references auth.users(id) on delete set null,
  received_by_email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.site_admins(email)
values (lower('alarmierahmed@gmail.com'))
on conflict (email) do nothing;

create or replace function public.is_site_owner()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.site_admins where lower(email)=lower(coalesce(auth.jwt()->>'email','')));
$$;

create or replace function public.is_site_supervisor()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.supervisors where lower(email)=lower(coalesce(auth.jwt()->>'email','')));
$$;

alter table public.site_admins enable row level security;
alter table public.supervisors enable row level security;
alter table public.orders enable row level security;

drop policy if exists "admin self read" on public.site_admins;
create policy "admin self read" on public.site_admins for select to authenticated
using (lower(email)=lower(coalesce(auth.jwt()->>'email','')));

drop policy if exists "supervisor self or owner read" on public.supervisors;
create policy "supervisor self or owner read" on public.supervisors for select to authenticated
using (public.is_site_owner() or lower(email)=lower(coalesce(auth.jwt()->>'email','')));

drop policy if exists "owner adds supervisor" on public.supervisors;
create policy "owner adds supervisor" on public.supervisors for insert to authenticated
with check (public.is_site_owner());

drop policy if exists "owner removes supervisor" on public.supervisors;
create policy "owner removes supervisor" on public.supervisors for delete to authenticated
using (public.is_site_owner());

drop policy if exists "buyer creates own order" on public.orders;
create policy "buyer creates own order" on public.orders for insert to authenticated
with check (buyer_id=auth.uid());

drop policy if exists "buyer or staff reads orders" on public.orders;
create policy "buyer or staff reads orders" on public.orders for select to authenticated
using (buyer_id=auth.uid() or public.is_site_owner() or public.is_site_supervisor());

drop policy if exists "staff updates orders" on public.orders;
create policy "staff updates orders" on public.orders for update to authenticated
using (public.is_site_owner() or public.is_site_supervisor())
with check (public.is_site_owner() or public.is_site_supervisor());
