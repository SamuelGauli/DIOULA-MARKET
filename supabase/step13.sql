-- =====================================================================
--  DIOULA MARKET — ÉTAPE 10d : CALENDRIER DE CRÉNEAUX (livraison/retrait)
--  La réservation se fait désormais sur un CRÉNEAU (jour + plage horaire)
--  choisi dans un calendrier, au lieu d'une échéance libre.
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Colonnes de créneau sur les réservations
-- ---------------------------------------------------------------------
alter table public.reservations
  add column if not exists slot_start timestamptz,
  add column if not exists slot_end   timestamptz;

-- ---------------------------------------------------------------------
--  B) reserve_product : version « créneau »
--     (remplace la version « échéance » de step6 — on droppe l'ancienne
--      signature pour éviter toute ambiguïté de surcharge).
--     deadline = fin du créneau → la logique annulation/expiration
--     (step6) continue de fonctionner telle quelle.
-- ---------------------------------------------------------------------
drop function if exists public.reserve_product(uuid, numeric, timestamptz);

create or replace function public.reserve_product(
  p_product_id uuid,
  p_quantity   numeric,
  p_slot_start timestamptz,
  p_slot_end   timestamptz
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_product public.products%rowtype;
  v_uid uuid := auth.uid();
  v_total numeric; v_deposit numeric; v_res_id uuid;
begin
  if v_uid is null then raise exception 'Non connecté.'; end if;
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Quantité invalide.';
  end if;

  select * into v_product from public.products where id = p_product_id;
  if not found then raise exception 'Produit introuvable.'; end if;
  if v_product.stock < p_quantity then
    raise exception 'Stock insuffisant (reste %).', v_product.stock;
  end if;

  v_total   := v_product.price * p_quantity;
  v_deposit := round(v_total * 0.30, 2);

  insert into public.reservations (
    product_id, shop_id, buyer_id, quantity, unit_price,
    total_amount, deposit_amount, deposit_paid, status,
    deadline, slot_start, slot_end
  ) values (
    p_product_id, v_product.shop_id, v_uid, p_quantity, v_product.price,
    v_total, v_deposit, true, 'payee',
    p_slot_end, p_slot_start, p_slot_end
  ) returning id into v_res_id;

  update public.products set stock = stock - p_quantity where id = p_product_id;

  insert into public.payments (payer_id, reservation_id, amount, kind, status)
  values (v_uid, v_res_id, v_deposit, 'acompte', 'simule');

  return v_res_id;
end; $$;

-- =====================================================================
--  FIN step13.sql
-- =====================================================================
