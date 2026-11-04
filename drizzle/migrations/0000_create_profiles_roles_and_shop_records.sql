-- Profiles for signed-in staff
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  email text not null default '',
  mobile text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Staff roles (first account becomes Admin)
create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('Admin','Shop Owner','Manager','Cashier','Inventory Staff','Accountant')),
  unique (user_id, role)
);

-- Local-first shop data mirrored from the app (Dexie) to the cloud
create table public.shop_records (
  entity text not null,
  local_id integer not null,
  payload jsonb not null default '{}'::jsonb,
  deleted boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (entity, local_id)
);

create or replace function public.touch_shop_record()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

create trigger shop_records_touch
before update on public.shop_records
for each row execute function public.touch_shop_record();

-- Create profile + role on signup; the first ever account becomes Admin
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.email, '')
  );

  if not exists (select 1 from public.user_roles) then
    insert into public.user_roles (user_id, role) values (new.id, 'Admin');
  else
    insert into public.user_roles (user_id, role) values (new.id, 'Cashier');
  end if;
  return new;
end $$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Grants
grant select, update on public.profiles to authenticated;
grant select on public.user_roles to authenticated;
grant select, insert, update, delete on public.shop_records to authenticated;
grant all on public.profiles to service_role;
grant all on public.user_roles to service_role;
grant all on public.shop_records to service_role;

-- RLS
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.shop_records enable row level security;

create policy "Staff can view profiles"
  on public.profiles for select to authenticated using (true);
create policy "Users can update own profile"
  on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
create policy "Staff can view roles"
  on public.user_roles for select to authenticated using (true);
create policy "Staff can manage shop records"
  on public.shop_records for all to authenticated using (true) with check (true);