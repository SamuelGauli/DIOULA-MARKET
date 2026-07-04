-- =====================================================================
--  DIOULA MARKET — COMMIT 3 : PROMO (anti-gaspillage) sur les produits
--  Le vendeur peut brader un produit (prix promo) pour éviter le
--  gaspillage. La réservation applique automatiquement le prix promo.
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Prix promo (null = pas de promo)
-- ---------------------------------------------------------------------
alter table public.products
  add column if not exists promo_price numeric null;

-- ---------------------------------------------------------------------
--  B) reserve_product applique le prix EFFECTIF (promo si défini)
--     (remplace la version de step13 — même signature « créneau »)
-- ---------------------------------------------------------------------
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
  v_price numeric; v_total numeric; v_deposit numeric; v_res_id uuid;
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

  -- Prix effectif : promo si présente (et positive), sinon prix normal.
  v_price := case
               when v_product.promo_price is not null and v_product.promo_price > 0
                 then v_product.promo_price
               else v_product.price
             end;
  v_total   := v_price * p_quantity;
  v_deposit := round(v_total * 0.30, 2);

  insert into public.reservations (
    product_id, shop_id, buyer_id, quantity, unit_price,
    total_amount, deposit_amount, deposit_paid, status,
    deadline, slot_start, slot_end
  ) values (
    p_product_id, v_product.shop_id, v_uid, p_quantity, v_price,
    v_total, v_deposit, true, 'payee',
    p_slot_end, p_slot_start, p_slot_end
  ) returning id into v_res_id;

  update public.products set stock = stock - p_quantity where id = p_product_id;

  insert into public.payments (payer_id, reservation_id, amount, kind, status)
  values (v_uid, v_res_id, v_deposit, 'acompte', 'simule');

  return v_res_id;
end; $$;

-- =====================================================================
--  FIN step17.sql
-- =====================================================================
