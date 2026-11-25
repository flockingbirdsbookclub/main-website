-- Storage buckets. Every bucket is publicly readable (the images appear on
-- public pages) and limited to JPEG, PNG and WebP up to 5 MB, enforced by
-- Supabase Storage itself, not just the upload form.
-- Members write only inside a folder named after their own user id:
-- avatars/<user id>/photo.jpg, articles/<user id>/cover.jpg.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars',  'avatars',  true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('covers',   'covers',   true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('partners', 'partners', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('events',   'events',   true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('albums',   'albums',   true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('articles', 'articles', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('merch',    'merch',    true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "site images are public"
  on storage.objects for select to anon, authenticated
  using (bucket_id in ('avatars', 'covers', 'partners', 'events', 'albums', 'articles', 'merch'));

create policy "staff upload site images"
  on storage.objects for insert to authenticated
  with check (bucket_id in ('avatars', 'covers', 'partners', 'events', 'albums', 'articles', 'merch')
              and public.is_staff());
create policy "staff change site images"
  on storage.objects for update to authenticated
  using (bucket_id in ('avatars', 'covers', 'partners', 'events', 'albums', 'articles', 'merch') and public.is_staff())
  with check (bucket_id in ('avatars', 'covers', 'partners', 'events', 'albums', 'articles', 'merch') and public.is_staff());
create policy "staff delete site images"
  on storage.objects for delete to authenticated
  using (bucket_id in ('avatars', 'covers', 'partners', 'events', 'albums', 'articles', 'merch') and public.is_staff());

create policy "members upload to their own folder"
  on storage.objects for insert to authenticated
  with check (bucket_id in ('avatars', 'articles')
              and (storage.foldername(name))[1] = auth.uid()::text
              and public.current_profile_id() is not null);
create policy "members replace their own files"
  on storage.objects for update to authenticated
  using (bucket_id in ('avatars', 'articles') and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id in ('avatars', 'articles') and (storage.foldername(name))[1] = auth.uid()::text);
create policy "members delete their own files"
  on storage.objects for delete to authenticated
  using (bucket_id in ('avatars', 'articles') and (storage.foldername(name))[1] = auth.uid()::text);
