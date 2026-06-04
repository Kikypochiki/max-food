-- Migration to set up real-time chat tables, update profiles, and enable Supabase Realtime subscriptions.

-- 1. Extend profiles table with full_name and update policies
alter table public.profiles add column if not exists full_name text;

-- Sync existing auth.users display names to profiles table
update public.profiles p
set full_name = coalesce(u.raw_user_meta_data->>'full_name', u.email)
from auth.users u
where p.id = u.id;

-- Make sure any existing users without a profile get one
insert into public.profiles (id, full_name, avatar_url)
select 
  u.id, 
  coalesce(u.raw_user_meta_data->>'full_name', u.email),
  coalesce(u.raw_user_meta_data->>'avatar_url', '')
from auth.users u
left join public.profiles p on u.id = p.id
where p.id is null
on conflict (id) do nothing;

-- Update Select Policy on Profiles: Allow all authenticated users to read profiles
drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Authenticated users can read all profiles"
on public.profiles
for select
to authenticated
using (true);

-- Create trigger function to automatically create/sync profile on user insert or metadata update
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email),
    coalesce(new.raw_user_meta_data->>'avatar_url', '')
  )
  on conflict (id) do update
  set full_name = coalesce(excluded.full_name, public.profiles.full_name),
      avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url);
  return new;
end;
$$;

-- Trigger to run when user is created in auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- 2. Create Chat Rooms table
create table if not exists public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listing(listing_id) on delete cascade,
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz default now() not null,
  constraint unique_listing_buyer_seller unique (listing_id, buyer_id, seller_id)
);

-- Enable RLS for Chat Rooms
alter table public.chat_rooms enable row level security;

-- Policies for Chat Rooms
drop policy if exists "Users can view rooms they participate in" on public.chat_rooms;
create policy "Users can view rooms they participate in"
on public.chat_rooms
for select
to authenticated
using (auth.uid() = buyer_id or auth.uid() = seller_id);

drop policy if exists "Users can create rooms they participate in" on public.chat_rooms;
create policy "Users can create rooms they participate in"
on public.chat_rooms
for insert
to authenticated
with check (auth.uid() = buyer_id or auth.uid() = seller_id);


-- 3. Create Chat Messages table
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  message text not null,
  created_at timestamptz default now() not null,
  is_read boolean default false not null
);

-- Enable RLS for Chat Messages
alter table public.chat_messages enable row level security;

-- Policies for Chat Messages
drop policy if exists "Users can view messages in their rooms" on public.chat_messages;
create policy "Users can view messages in their rooms"
on public.chat_messages
for select
to authenticated
using (
  exists (
    select 1 from public.chat_rooms
    where id = room_id
    and (buyer_id = auth.uid() or seller_id = auth.uid())
  )
);

drop policy if exists "Users can send messages to their rooms" on public.chat_messages;
create policy "Users can send messages to their rooms"
on public.chat_messages
for insert
to authenticated
with check (
  auth.uid() = sender_id
  and exists (
    select 1 from public.chat_rooms
    where id = room_id
    and (buyer_id = auth.uid() or seller_id = auth.uid())
  )
);


-- 4. Enable Supabase Realtime for Chat Rooms & Chat Messages
-- Try adding to publication; handle if publication does not exist or if already added.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.chat_rooms;
    alter publication supabase_realtime add table public.chat_messages;
  end if;
exception
  when others then
    -- Silence if already added or permission issues in migration
    null;
end;
$$;
