-- Storage policy for listing images.
insert into storage.buckets (id, name, public)
values ('product_image', 'product_image', true)
on conflict (id) do update
set name = excluded.name,
    public = excluded.public;

drop policy if exists "Authenticated users can upload product images" on storage.objects;
create policy "Authenticated users can upload product images"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'product_image');

drop policy if exists "Authenticated users can update product images" on storage.objects;
create policy "Authenticated users can update product images"
on storage.objects
for update
to authenticated
using (bucket_id = 'product_image')
with check (bucket_id = 'product_image');

drop policy if exists "Authenticated users can delete product images" on storage.objects;
create policy "Authenticated users can delete product images"
on storage.objects
for delete
to authenticated
using (bucket_id = 'product_image');

drop policy if exists "Anyone can read product images" on storage.objects;
create policy "Anyone can read product images"
on storage.objects
for select
using (bucket_id = 'product_image');