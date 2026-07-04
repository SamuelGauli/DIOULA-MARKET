-- =====================================================================
--  DIOULA MARKET — COMMIT 2 : SUIVI DÉTAILLÉ DU COLIS
--  Le livreur fait avancer la livraison étape par étape ; acheteur &
--  vendeur voient la progression en temps réel.
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
--  Dépend de `push_notif` (step6.sql).
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Étape de livraison sur les commandes (0 → 5)
-- ---------------------------------------------------------------------
alter table public.orders
  add column if not exists delivery_step int not null default 0;

-- ---------------------------------------------------------------------
--  B) Le livreur assigné fait avancer la livraison d'une étape
--     Étapes : 0 pas encore récupéré · 1 récupéré · 2 en route ·
--              3 presque là · 4 arrivé · 5 livré (→ status 'livree')
-- ---------------------------------------------------------------------
create or replace function public.advance_delivery(p_order_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_order public.orders%rowtype;
  v_step  int;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'Commande introuvable.'; end if;
  if v_order.courier_id <> auth.uid() then
    raise exception 'Action non autorisée.';
  end if;
  if v_order.status <> 'en_livraison' then
    raise exception 'Commande non en cours de livraison.';
  end if;

  v_step := least(coalesce(v_order.delivery_step, 0) + 1, 5);

  update public.orders
     set delivery_step = v_step,
         status = case when v_step >= 5 then 'livree' else status end,
         updated_at = now()
   where id = p_order_id;

  if v_step = 1 then
    perform public.push_notif(v_order.buyer_id, 'livraison',
      'Colis récupéré 📦', 'Le livreur a récupéré ton colis.');
  elsif v_step >= 5 then
    perform public.push_notif(v_order.buyer_id, 'livraison',
      'Colis livré ✅', 'Ton colis a été réceptionné avec succès !');
    perform public.push_notif(
      (select owner_id from public.shops where id = v_order.shop_id),
      'livraison', 'Commande livrée', 'Le client a reçu le colis.');
  end if;
end; $$;

-- =====================================================================
--  FIN step16.sql
-- =====================================================================
