alter table public.category enable row level security;

drop policy if exists "Anyone can read categories" on public.category;
create policy "Anyone can read categories"
on public.category
for select
using (true);
