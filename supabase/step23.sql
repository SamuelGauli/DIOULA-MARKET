-- =====================================================================
--  DIOULA MARKET — ADMIN 2/3 : MODÉRATION + VALIDATION KYC RÉELLE
--  Bannir/réactiver un compte (suspend ses boutiques), suspendre une
--  boutique, masquer un produit, approuver/refuser une identité.
--  À exécuter dans : SQL Editor (après step22). Rejouable.
--  Dépend de is_admin() (step22), push_notif (step6), activity_log (step11).
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Bannissement : colonnes sur le profil
-- ---------------------------------------------------------------------
alter table public.profiles
  add column if not exists is_active boolean not null default true;
alter table public.profiles
  add column if not exists ban_reason text;

-- ---------------------------------------------------------------------
--  B) RPC — bannir / réactiver un utilisateur (cascade boutiques)
-- ---------------------------------------------------------------------
create or replace function public.admin_set_user_active(
  p_user uuid, p_active boolean, p_reason text default null
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Action non autorisée.'; end if;

  update public.profiles
     set is_active = p_active,
         ban_reason = case when p_active then null else p_reason end
   where id = p_user;

  -- Bannir suspend aussi ses boutiques ; réactiver les rouvre.
  update public.shops set is_active = p_active where owner_id = p_user;

  perform public.push_notif(p_user, 'info',
    case when p_active then 'Compte réactivé ✅' else 'Compte suspendu' end,
    case when p_active
         then 'Ton compte Dioula Market est de nouveau actif.'
         else 'Ton compte a été suspendu par la modération'
              || coalesce(' : ' || p_reason, '') || '.' end);

  insert into public.activity_log(actor_id, action, detail, entity, entity_id)
  values (auth.uid(),
          case when p_active then 'admin_user_reactive' else 'admin_user_ban' end,
          case when p_active then 'Compte réactivé par l''admin'
               else 'Compte suspendu par l''admin'
                    || coalesce(' — motif : ' || p_reason, '') end,
          'profile', p_user);
end; $$;

-- ---------------------------------------------------------------------
--  C) RPC — suspendre / réactiver une boutique
-- ---------------------------------------------------------------------
create or replace function public.admin_set_shop_active(
  p_shop uuid, p_active boolean
) returns void
language plpgsql security definer set search_path = public as $$
declare v_owner uuid; v_name text;
begin
  if not public.is_admin() then raise exception 'Action non autorisée.'; end if;

  update public.shops set is_active = p_active where id = p_shop
  returning owner_id, name into v_owner, v_name;

  if v_owner is not null then
    perform public.push_notif(v_owner, 'info',
      case when p_active then 'Boutique réactivée ✅'
           else 'Boutique suspendue' end,
      'Ta boutique « ' || v_name || ' » a été '
        || case when p_active then 'réactivée' else 'suspendue' end
        || ' par la modération.');
  end if;

  insert into public.activity_log(actor_id, action, detail, entity, entity_id)
  values (auth.uid(),
          case when p_active then 'admin_shop_reactive' else 'admin_shop_suspend' end,
          'Boutique « ' || coalesce(v_name, '?') || ' » '
            || case when p_active then 'réactivée' else 'suspendue' end
            || ' par l''admin',
          'shop', p_shop);
end; $$;

-- ---------------------------------------------------------------------
--  D) RPC — masquer / republier un produit
-- ---------------------------------------------------------------------
create or replace function public.admin_set_product_active(
  p_product uuid, p_active boolean
) returns void
language plpgsql security definer set search_path = public as $$
declare v_owner uuid; v_name text;
begin
  if not public.is_admin() then raise exception 'Action non autorisée.'; end if;

  update public.products set is_active = p_active where id = p_product
  returning name into v_name;

  select s.owner_id into v_owner
    from public.products p join public.shops s on s.id = p.shop_id
   where p.id = p_product;

  if v_owner is not null then
    perform public.push_notif(v_owner, 'info',
      case when p_active then 'Produit republié ✅' else 'Produit masqué' end,
      'Ton produit « ' || coalesce(v_name, '?') || ' » a été '
        || case when p_active then 'republié' else 'masqué' end
        || ' par la modération.');
  end if;

  insert into public.activity_log(actor_id, action, detail, entity, entity_id)
  values (auth.uid(),
          case when p_active then 'admin_product_show' else 'admin_product_hide' end,
          'Produit « ' || coalesce(v_name, '?') || ' » '
            || case when p_active then 'republié' else 'masqué' end
            || ' par l''admin',
          'product', p_product);
end; $$;

-- ---------------------------------------------------------------------
--  E) RPC — approuver / refuser une vérification d'identité (KYC)
-- ---------------------------------------------------------------------
create or replace function public.admin_review_kyc(
  p_user uuid, p_approve boolean
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Action non autorisée.'; end if;

  update public.profiles
     set verification_status = case when p_approve then 'verifie' else 'refuse' end,
         verified_at = case when p_approve then now() else null end
   where id = p_user and verification_status = 'en_attente';

  perform public.push_notif(p_user, 'info',
    case when p_approve then 'Identité vérifiée ✅' else 'Vérification refusée' end,
    case when p_approve
         then 'Ta vérification d''identité a été approuvée par l''équipe.'
         else 'Tes documents n''ont pas pu être validés. Tu peux les soumettre à nouveau.' end);

  insert into public.activity_log(actor_id, action, detail, entity, entity_id)
  values (auth.uid(),
          case when p_approve then 'admin_kyc_approve' else 'admin_kyc_reject' end,
          'Vérification d''identité '
            || case when p_approve then 'approuvée' else 'refusée' end
            || ' par l''admin',
          'profile', p_user);
end; $$;

-- ---------------------------------------------------------------------
--  F) Storage — l'admin peut consulter les pièces du bucket privé kyc-docs
-- ---------------------------------------------------------------------
drop policy if exists kyc_select_admin on storage.objects;
create policy kyc_select_admin on storage.objects
  for select to authenticated
  using (bucket_id = 'kyc-docs' and public.is_admin());

-- =====================================================================
--  FIN step23.sql
-- =====================================================================
