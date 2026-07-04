-- =====================================================================
--  DIOULA MARKET — ADMIN 3/3 : AVIS, ANNONCES & AUDIT GLOBAL
--  Masquer/rétablir un avis (recalcul sans les avis masqués), diffuser
--  une annonce à tous, et laisser l'admin lire tout le journal d'audit.
--  À exécuter dans : SQL Editor (après step22/23). Rejouable.
--  Dépend de is_admin() (step22) et du trigger de recalcul (step8).
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Colonne « avis masqué »
-- ---------------------------------------------------------------------
alter table public.reviews
  add column if not exists is_hidden boolean not null default false;

-- ---------------------------------------------------------------------
--  B) Recalcul des moyennes en EXCLUANT les avis masqués (remplace step8)
--     (le trigger trg_review_changed relance déjà ces fonctions à chaque
--      insert/update/delete d'avis, dont le masquage).
-- ---------------------------------------------------------------------
create or replace function public.recompute_shop_rating(p_shop uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_shop is null then return; end if;
  update public.shops s set
    rating_avg = coalesce(
      (select round(avg(rating)::numeric, 2) from public.reviews
        where shop_id = p_shop and coalesce(is_hidden, false) = false), 0),
    rating_count = (select count(*) from public.reviews
        where shop_id = p_shop and coalesce(is_hidden, false) = false)
  where s.id = p_shop;
end; $$;

create or replace function public.recompute_profile_rating(p_profile uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_profile is null then return; end if;
  update public.profiles p set
    rating_avg = coalesce(
      (select round(avg(rating)::numeric, 2) from public.reviews
        where target_id = p_profile and coalesce(is_hidden, false) = false), 0),
    rating_count = (select count(*) from public.reviews
        where target_id = p_profile and coalesce(is_hidden, false) = false)
  where p.id = p_profile;
end; $$;

-- ---------------------------------------------------------------------
--  C) RPC — masquer / rétablir un avis
-- ---------------------------------------------------------------------
create or replace function public.admin_set_review_hidden(
  p_review uuid, p_hidden boolean
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Action non autorisée.'; end if;

  -- Le trigger trg_review_changed recalculera la note (hors avis masqués).
  update public.reviews set is_hidden = p_hidden where id = p_review;

  insert into public.activity_log(actor_id, action, detail, entity, entity_id)
  values (auth.uid(),
          case when p_hidden then 'admin_review_hide' else 'admin_review_show' end,
          'Avis ' || case when p_hidden then 'masqué' else 'rétabli' end
            || ' par l''admin',
          'review', p_review);
end; $$;

-- ---------------------------------------------------------------------
--  D) RPC — annonce à tous les utilisateurs actifs
-- ---------------------------------------------------------------------
create or replace function public.admin_broadcast(
  p_title text, p_body text
) returns integer
language plpgsql security definer set search_path = public as $$
declare v_count integer;
begin
  if not public.is_admin() then raise exception 'Action non autorisée.'; end if;
  if p_title is null or length(trim(p_title)) = 0 then
    raise exception 'Titre requis.';
  end if;

  insert into public.notifications(user_id, type, title, body)
  select id, 'info', p_title, p_body
    from public.profiles where is_active;
  get diagnostics v_count = row_count;

  insert into public.activity_log(actor_id, action, detail, entity, entity_id)
  values (auth.uid(), 'admin_broadcast',
          'Annonce envoyée à ' || v_count || ' utilisateur(s) : ' || p_title,
          null, null);

  return v_count;
end; $$;

-- ---------------------------------------------------------------------
--  E) L'admin lit TOUT le journal d'audit (en plus de sa propre policy)
-- ---------------------------------------------------------------------
drop policy if exists activity_admin_select on public.activity_log;
create policy activity_admin_select on public.activity_log
  for select to authenticated using (public.is_admin());

-- =====================================================================
--  FIN step24.sql
-- =====================================================================
