-- Fix listing image storage: image_url should store a storage URL/path, not a bucket id.
-- The current foreign key blocks valid image URLs, so remove it.

alter table public.listing
drop constraint if exists lising_image_url_fkey;
