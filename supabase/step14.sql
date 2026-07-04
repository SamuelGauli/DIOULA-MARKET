-- =====================================================================
--  DIOULA MARKET — ÉTAPE 10e : EMPLOIS DU TEMPS LIVREURS
--  À la prise en charge d'une course, le livreur choisit un CRÉNEAU qui
--  se réserve dans son agenda (un seul créneau à la fois).
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
--  Dépend de `push_notif` (step6.sql).
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Créneau de livraison sur les commandes
-- ---------------------------------------------------------------------
alter table public.orders
  add column if not exists slot_start timestamptz,
  add column if not exists slot_end   timestamptz;

-- ---------------------------------------------------------------------
--  B) claim_order : version « créneau » (remplace celle de step10)
--     Refuse un 2e créneau identique dans l'agenda du même livreur.
-- ---------------------------------------------------------------------
drop function if exists public.claim_order(uuid);

create or replace function public.claim_order(
  p_order_id uuid, p_slot_start timestamptz, p_slot_end timestamptz
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_order public.orders%rowtype;
  v_uid uuid := auth.uid();
begin
  if not exists (select 1 from public.profiles
                 where id = v_uid and role = 'livreur') then
    raise exception 'Réservé aux livreurs.';
  end if;

  -- Verrou : évite que deux livreurs prennent la même course.
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'Commande introuvable.'; end if;
  if v_order.courier_id is not null then
    raise exception 'Cette course a déjà été prise.';
  end if;
  if v_order.status not in ('en_cours', 'preparee') then
    raise exception 'Cette commande n''est pas disponible.';
  end if;

  -- Un seul créneau à la fois dans l'agenda du livreur.
  if p_slot_start is not null and exists (
    select 1 from public.orders
    where courier_id = v_uid
      and status = 'en_livraison'
      and slot_start = p_slot_start
  ) then
    raise exception 'Tu as déjà une course sur ce créneau.';
  end if;

  update public.orders
     set courier_id = v_uid,
         status     = 'en_livraison',
         slot_start = p_slot_start,
         slot_end   = p_slot_end,
         updated_at = now()
   where id = p_order_id;

  perform public.push_notif(v_order.buyer_id, 'livraison',
    'Commande en route 🛵', 'Un livreur a pris en charge ta commande.');
  perform public.push_notif(
    (select owner_id from public.shops where id = v_order.shop_id),
    'livraison', 'Livreur assigné',
    'Un livreur récupère une de tes commandes.');
end; $$;

-- =====================================================================
--  FIN step14.sql
-- =====================================================================
