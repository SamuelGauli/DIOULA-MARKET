-- =====================================================================
--  DIOULA MARKET — ÉTAPE 10 : LIVRAISON (pool de livreurs)
--  Les commandes (créées par accept_offer, step5) sont distribuées à un
--  pool de livreurs : un livreur voit les courses disponibles, en prend
--  une (→ en_livraison), puis la marque livrée (→ livree).
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
--  Dépend de `push_notif` (step6.sql).
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) RLS — laisser les LIVREURS voir le « pool » (commandes non assignées)
--     Policies ADDITIVES (OR avec les policies existantes de rls.sql).
-- ---------------------------------------------------------------------
drop policy if exists orders_select_courier_pool on public.orders;
create policy orders_select_courier_pool on public.orders
  for select using (
    courier_id is null
    and status in ('en_cours', 'preparee')
    and exists (select 1 from public.profiles p
                where p.id = auth.uid() and p.role = 'livreur')
  );

drop policy if exists order_items_select_courier_pool on public.order_items;
create policy order_items_select_courier_pool on public.order_items
  for select using (
    exists (select 1 from public.orders o
            where o.id = order_items.order_id
              and o.courier_id is null
              and o.status in ('en_cours', 'preparee'))
    and exists (select 1 from public.profiles p
                where p.id = auth.uid() and p.role = 'livreur')
  );

-- ---------------------------------------------------------------------
--  B) Fonctions atomiques : prendre / livrer une course (+ notifications)
-- ---------------------------------------------------------------------

-- Un livreur prend en charge une commande disponible.
create or replace function public.claim_order(p_order_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_order public.orders%rowtype;
begin
  if not exists (select 1 from public.profiles
                 where id = auth.uid() and role = 'livreur') then
    raise exception 'Réservé aux livreurs.';
  end if;

  -- Verrou de ligne : évite que deux livreurs prennent la même course.
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'Commande introuvable.'; end if;
  if v_order.courier_id is not null then
    raise exception 'Cette course a déjà été prise.';
  end if;
  if v_order.status not in ('en_cours', 'preparee') then
    raise exception 'Cette commande n''est pas disponible.';
  end if;

  update public.orders
     set courier_id = auth.uid(), status = 'en_livraison', updated_at = now()
   where id = p_order_id;

  perform public.push_notif(v_order.buyer_id, 'livraison',
    'Commande en route 🛵', 'Un livreur a pris en charge ta commande.');
  perform public.push_notif(
    (select owner_id from public.shops where id = v_order.shop_id),
    'livraison', 'Livreur assigné',
    'Un livreur récupère une de tes commandes.');
end; $$;

-- Le livreur assigné marque la commande comme livrée.
create or replace function public.mark_order_delivered(p_order_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_order public.orders%rowtype;
begin
  select * into v_order from public.orders where id = p_order_id;
  if not found then raise exception 'Commande introuvable.'; end if;
  if v_order.courier_id <> auth.uid() then
    raise exception 'Action non autorisée.';
  end if;
  if v_order.status <> 'en_livraison' then
    raise exception 'Commande non en cours de livraison.';
  end if;

  update public.orders set status = 'livree', updated_at = now()
   where id = p_order_id;

  perform public.push_notif(v_order.buyer_id, 'livraison',
    'Commande livrée ✅', 'Ta commande a été livrée. Merci !');
  perform public.push_notif(
    (select owner_id from public.shops where id = v_order.shop_id),
    'livraison', 'Commande livrée', 'Une de tes commandes a été livrée.');
end; $$;

-- ---------------------------------------------------------------------
--  C) REALTIME sur orders (suivi acheteur / pool livreur)
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime'
     and schemaname='public' and tablename='orders') then
    alter publication supabase_realtime add table public.orders;
  end if;
end $$;
alter table public.orders replica identity full;

-- ---------------------------------------------------------------------
--  D) DÉMO : amorcer 2 commandes livrables (si le pool est vide)
--     → le livreur kader voit immédiatement des courses à prendre.
-- ---------------------------------------------------------------------
do $$
declare
  uid_samira uuid;
  shop_brou  uuid;
  shop_fatim uuid;
  v_order    uuid;
begin
  select id into uid_samira from auth.users where email = 'samira@demo.ci';
  select id into shop_brou  from public.shops where name = 'Chez Brou'    limit 1;
  select id into shop_fatim from public.shops where name = 'Maquis Fatim' limit 1;
  if uid_samira is null then return; end if;

  -- N'amorce QUE si aucune course n'est disponible (ne casse pas un vrai flux).
  if exists (select 1 from public.orders
             where courier_id is null and status = 'en_cours') then
    return;
  end if;

  if shop_brou is not null then
    insert into public.orders (buyer_id, shop_id, status, total_amount, delivery_address)
    values (uid_samira, shop_brou, 'en_cours', 12000, 'Cocody, Rue des Jardins')
    returning id into v_order;
    insert into public.order_items (order_id, product_name, quantity, unit_price)
    values (v_order, 'Tomate fraîche', 5, 1200),
           (v_order, 'Oignon', 6, 1000);
  end if;

  if shop_fatim is not null then
    insert into public.orders (buyer_id, shop_id, status, total_amount, delivery_address)
    values (uid_samira, shop_fatim, 'en_cours', 4500, 'Cocody, Angré 7e tranche')
    returning id into v_order;
    insert into public.order_items (order_id, product_name, quantity, unit_price)
    values (v_order, 'Garba', 3, 1500);
  end if;
end $$;

-- =====================================================================
--  FIN step10.sql
-- =====================================================================
