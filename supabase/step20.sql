-- =====================================================================
--  DIOULA MARKET — COMMIT E : PHOTOS DE PROFIL + BANNIÈRE BOUTIQUE
--  Avatars (tous les rôles) + bannière/logo de boutique (vendeurs).
--  Buckets Storage PUBLICS (lecture par tous) ; écriture dans son dossier.
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Buckets publics (avatars + images de boutique)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('shop-images', 'shop-images', true)
on conflict (id) do update set public = true;

-- ---------------------------------------------------------------------
--  B) Politiques : lecture publique, écriture dans SON dossier (uid/…)
--     (mêmes règles que le bucket KYC de step12, mais en lecture ouverte)
-- ---------------------------------------------------------------------
-- Avatars
drop policy if exists avatars_read_public on storage.objects;
create policy avatars_read_public on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists avatars_write_own on storage.objects;
create policy avatars_write_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists avatars_update_own on storage.objects;
create policy avatars_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text);

-- Images de boutique (logo + bannière)
drop policy if exists shopimg_read_public on storage.objects;
create policy shopimg_read_public on storage.objects
  for select using (bucket_id = 'shop-images');

drop policy if exists shopimg_write_own on storage.objects;
create policy shopimg_write_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'shop-images'
    and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists shopimg_update_own on storage.objects;
create policy shopimg_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'shop-images'
    and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------------
--  C) Colonne bannière sur la boutique
-- ---------------------------------------------------------------------
alter table public.shops
  add column if not exists banner_url text;

-- =====================================================================
--  FIN step20.sql
-- =====================================================================
