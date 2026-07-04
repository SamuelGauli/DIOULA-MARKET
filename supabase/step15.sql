-- =====================================================================
--  DIOULA MARKET — ÉTAPE 10c : CNI CONSOMMATEUR (grosse commande)
--  Un consommateur doit renseigner sa pièce d'identité (CNI) avant de
--  valider une commande/réservation d'un montant élevé (> 250 000 FCFA).
--  Réutilise l'infra KYC de step12 (colonnes + bucket + statut).
--  À exécuter dans : SQL Editor (après step12). Rejouable.
-- =====================================================================

-- Soumission d'une SEULE pièce (CNI) pour le consommateur → "en vérification".
-- (Le certificat de résidence reste réservé aux comptes professionnels.)
create or replace function public.submit_cni(p_id_path text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Non connecté.'; end if;
  update public.profiles
     set id_doc_path        = p_id_path,
         verification_status = 'en_attente',
         verified_at        = null
   where id = auth.uid();
end; $$;

-- =====================================================================
--  FIN step15.sql
-- =====================================================================
