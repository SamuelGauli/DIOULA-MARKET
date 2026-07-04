-- =====================================================================
--  DIOULA MARKET — ÉTAPE 10b : KYC (vérification d'identité)
--  Vendeurs / livreurs / producteurs déposent une pièce d'identité + un
--  certificat de résidence → statut "en vérification" puis "vérifié".
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
--  ⚠️ Crée AUSSI le bucket Storage et ses politiques (rien à faire à la main).
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Colonnes KYC sur profiles
-- ---------------------------------------------------------------------
alter table public.profiles
  add column if not exists id_doc_path        text,
  add column if not exists residence_doc_path text,
  add column if not exists verified_at        timestamptz,
  add column if not exists verification_status text not null default 'non_soumis'
    check (verification_status in ('non_soumis','en_attente','verifie','refuse'));

-- ---------------------------------------------------------------------
--  B) Bucket Storage privé + politiques (chacun gère SON dossier <uid>/…)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('kyc-docs', 'kyc-docs', false)
on conflict (id) do nothing;

drop policy if exists kyc_insert_own on storage.objects;
create policy kyc_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'kyc-docs'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists kyc_select_own on storage.objects;
create policy kyc_select_own on storage.objects
  for select to authenticated
  using (bucket_id = 'kyc-docs'
         and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists kyc_update_own on storage.objects;
create policy kyc_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'kyc-docs'
         and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------------
--  C) Soumission + validation (simulée)
-- ---------------------------------------------------------------------

-- L'utilisateur soumet ses 2 pièces → passage "en vérification".
create or replace function public.submit_kyc(
  p_id_path text, p_residence_path text
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Non connecté.'; end if;
  update public.profiles
     set id_doc_path        = p_id_path,
         residence_doc_path = p_residence_path,
         verification_status = 'en_attente',
         verified_at        = null
   where id = auth.uid();
end; $$;

-- Validation simulée (en prod : revue par un admin / fournisseur KYC).
create or replace function public.simulate_verify_kyc()
returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Non connecté.'; end if;
  update public.profiles
     set verification_status = 'verifie', verified_at = now()
   where id = auth.uid() and verification_status = 'en_attente';
end; $$;

-- =====================================================================
--  FIN step12.sql
-- =====================================================================
