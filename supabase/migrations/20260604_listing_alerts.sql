-- 1. Create Listing Alerts Subscriptions table
create table if not exists public.listing_alerts_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_id uuid references public.category(category_id) on delete cascade,
  farmer_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz default now() not null,
  -- Ensure that either category_id or farmer_id is provided, but not both null
  constraint check_subscription_type check (
    (category_id is not null and farmer_id is null) or
    (category_id is null and farmer_id is not null)
  ),
  -- Avoid duplicate subscriptions per user
  constraint unique_user_category unique (user_id, category_id),
  constraint unique_user_farmer unique (user_id, farmer_id)
);

-- Enable RLS for Subscriptions
alter table public.listing_alerts_subscriptions enable row level security;

-- Policies for Subscriptions
drop policy if exists "Users can view their own subscriptions" on public.listing_alerts_subscriptions;
create policy "Users can view their own subscriptions"
on public.listing_alerts_subscriptions
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can create their own subscriptions" on public.listing_alerts_subscriptions;
create policy "Users can create their own subscriptions"
on public.listing_alerts_subscriptions
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own subscriptions" on public.listing_alerts_subscriptions;
create policy "Users can delete their own subscriptions"
on public.listing_alerts_subscriptions
for delete
to authenticated
using (auth.uid() = user_id);


-- 2. Create Notifications table
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null, -- 'new_listing', 'new_message'
  title text not null,
  body text not null,
  is_read boolean default false not null,
  created_at timestamptz default now() not null,
  data jsonb -- extra metadata like { "listing_id": "...", "room_id": "..." }
);

-- Enable RLS for Notifications
alter table public.notifications enable row level security;

-- Policies for Notifications
drop policy if exists "Users can view their own notifications" on public.notifications;
create policy "Users can view their own notifications"
on public.notifications
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can update their own notifications" on public.notifications;
create policy "Users can update their own notifications"
on public.notifications
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);


-- 3. Trigger Function for New Listings
create or replace function public.handle_new_listing_notification()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  product_cat_id uuid;
  product_name text;
  farmer_name text;
begin
  -- Get the category_id and product name for the new listing
  select category_id, name 
  into product_cat_id, product_name
  from public.product 
  where product_id = new.product_id;

  -- Get the farmer's display name
  select coalesce(full_name, 'A farmer')
  into farmer_name
  from public.profiles
  where id = new.farmer_user_id;

  -- Insert notifications for users subscribed to this category OR this farmer
  -- (excluding the farmer themselves)
  insert into public.notifications (user_id, type, title, body, data)
  select distinct sub.user_id, 
         'new_listing',
         'New Listing Alert!',
         farmer_name || ' posted a new harvest: ' || product_name,
         jsonb_build_object('listing_id', new.listing_id)
  from public.listing_alerts_subscriptions sub
  where (sub.category_id = product_cat_id or sub.farmer_id = new.farmer_user_id)
    and sub.user_id <> new.farmer_user_id;

  return new;
end;
$$;

-- Trigger on public.listing insert
drop trigger if exists on_listing_inserted on public.listing;
create trigger on_listing_inserted
  after insert on public.listing
  for each row execute procedure public.handle_new_listing_notification();


-- 4. Trigger Function for New Chat Messages
create or replace function public.handle_new_chat_message_notification()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  recipient_uuid uuid;
  sender_name text;
begin
  -- Retrieve room participants and identify recipient
  select case 
           when buyer_id = new.sender_id then seller_id 
           else buyer_id 
         end
  into recipient_uuid
  from public.chat_rooms
  where id = new.room_id;

  -- Get the sender's display name
  select coalesce(full_name, 'Someone')
  into sender_name
  from public.profiles
  where id = new.sender_id;

  -- Only notify if recipient is found
  if recipient_uuid is not null then
    insert into public.notifications (user_id, type, title, body, data)
    values (
      recipient_uuid,
      'new_message',
      'New message from ' || sender_name,
      new.message,
      jsonb_build_object('room_id', new.room_id, 'message_id', new.id)
    );
  end if;

  return new;
end;
$$;

-- Trigger on public.chat_messages insert
drop trigger if exists on_chat_message_inserted on public.chat_messages;
create trigger on_chat_message_inserted
  after insert on public.chat_messages
  for each row execute procedure public.handle_new_chat_message_notification();


-- 5. Enable Supabase Realtime for Notifications table
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.notifications;
  end if;
exception
  when others then
    null;
end;
$$;
