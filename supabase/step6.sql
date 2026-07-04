-- =====================================================================
--  DIOULA MARKET — ÉTAPE 6 : Réservation + acompte (simulé) + stock
--                            + NOTIFICATIONS (in-app, temps réel)
--  À exécuter dans : Supabase Dashboard > SQL Editor (après les précédents).
--  Rejouable.
-- =====================================================================

-- =====================================================================
--  A) NOTIFICATIONS
-- =====================================================================
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  type       text not null default 'info',   -- offre / reservation / stock / info
  title      text not null,
  body       text,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user
  on public.notifications(user_id, is_read);

alter table public.notifications enable row level security;

drop policy if exists notifications_select_self on public.notifications;
create policy notifications_select_self on public.notifications
  for select using (auth.uid() = user_id);

drop policy if exists notifications_update_self on public.notifications;
create policy notifications_update_self on public.notifications
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select, update on public.notifications to authenticated;

-- Helper d'insertion d'une notification (utilisé par les triggers).
create or replace function public.push_notif(
  p_user uuid, p_type text, p_title text, p_body text
) returns void
language plpgsql security definer set search_path = public
as $$
begin
  if p_user is null then return; end if;
  insert into public.notifications (user_id, type, title, body)
  values (p_user, p_type, p_title, p_body);
end; $$;

-- ---- Triggers de notification ----

-- Nouvelle offre → notifier le consommateur de la demande.
create or replace function public.trg_offer_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_consumer uuid; v_product text;
begin
  select consumer_id, product_name into v_consumer, v_product
  from public.requests where id = new.request_id;
  perform public.push_notif(v_consumer, 'offre', 'Nouvelle offre reçue',
    'Un vendeur a répondu à votre demande : ' || coalesce(v_product, ''));
  return new;
end; $$;
drop trigger if exists trg_offers_insert_notify on public.offers;
create trigger trg_offers_insert_notify
  after insert on public.offers
  for each row execute function public.trg_offer_insert();

-- Offre acceptée / refusée → notifier le vendeur.
create or replace function public.trg_offer_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status then
    if new.status = 'acceptee' then
      perform public.push_notif(new.merchant_id, 'offre', 'Offre acceptée 🎉',
        'Votre offre a été acceptée. Une commande a été créée.');
    elsif new.status = 'refusee' then
      perform public.push_notif(new.merchant_id, 'offre', 'Offre non retenue',
        'Une autre offre a été retenue pour cette demande.');
    end if;
  end if;
  return new;
end; $$;
drop trigger if exists trg_offers_update_notify on public.offers;
create trigger trg_offers_update_notify
  after update on public.offers
  for each row execute function public.trg_offer_update();

-- Nouvelle réservation → notifier le vendeur (propriétaire boutique).
create or replace function public.trg_reservation_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_owner uuid;
begin
  select owner_id into v_owner from public.shops where id = new.shop_id;
  perform public.push_notif(v_owner, 'reservation', 'Nouvelle réservation',
    'Un client a réservé un de vos produits (acompte payé).');
  return new;
end; $$;
drop trigger if exists trg_reservations_insert_notify on public.reservations;
create trigger trg_reservations_insert_notify
  after insert on public.reservations
  for each row execute function public.trg_reservation_insert();

-- Changement de statut de réservation → notifier l'acheteur.
create or replace function public.trg_reservation_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status then
    if new.status = 'terminee' then
      perform public.push_notif(new.buyer_id, 'reservation',
        'Réservation terminée ✅', 'Retrait confirmé, solde réglé. Merci !');
    elsif new.status = 'annulee' then
      perform public.push_notif(new.buyer_id, 'reservation',
        'Réservation annulée', 'Acompte remboursé sur votre portefeuille.');
    elsif new.status = 'expiree' then
      perform public.push_notif(new.buyer_id, 'reservation',
        'Réservation expirée', 'Échéance dépassée — remboursement partiel effectué.');
    end if;
  end if;
  return new;
end; $$;
drop trigger if exists trg_reservations_update_notify on public.reservations;
create trigger trg_reservations_update_notify
  after update on public.reservations
  for each row execute function public.trg_reservation_update();

-- Stock bas → notifier le vendeur.
create or replace function public.trg_low_stock() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_owner uuid;
begin
  if new.stock < 5 and old.stock >= 5 then
    select owner_id into v_owner from public.shops where id = new.shop_id;
    perform public.push_notif(v_owner, 'stock', 'Stock bas',
      'Le produit « ' || new.name || ' » passe sous 5 ' || new.unit || '.');
  end if;
  return new;
end; $$;
drop trigger if exists trg_products_low_stock on public.products;
create trigger trg_products_low_stock
  after update on public.products
  for each row execute function public.trg_low_stock();

-- =====================================================================
--  B) RÉSERVATION AVEC ACOMPTE (simulé) + STOCK
--     Acompte 30 %. Expiration : 40 % remboursés à l'acheteur,
--     40 % au vendeur, 20 % plateforme.
-- =====================================================================

-- Réserver + payer l'acompte (simulé) + décrémenter le stock. Renvoie l'id.
create or replace function public.reserve_product(
  p_product_id uuid, p_quantity numeric, p_deadline timestamptz
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
    total_amount, deposit_amount, deposit_paid, status, deadline
  ) values (
    p_product_id, v_product.shop_id, v_uid, p_quantity, v_product.price,
    v_total, v_deposit, true, 'payee', p_deadline
  ) returning id into v_res_id;

  -- décrément du stock à la confirmation
  update public.products set stock = stock - p_quantity where id = p_product_id;

  -- paiement de l'acompte (simulé)
  insert into public.payments (payer_id, reservation_id, amount, kind, status)
  values (v_uid, v_res_id, v_deposit, 'acompte', 'simule');

  return v_res_id;
end; $$;

-- Retrait à temps → solde réglé, réservation terminée.
create or replace function public.complete_reservation(p_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare v_res public.reservations%rowtype; v_balance numeric;
begin
  select * into v_res from public.reservations where id = p_id;
  if not found then raise exception 'Réservation introuvable.'; end if;

  -- acheteur OU propriétaire de la boutique
  if v_res.buyer_id <> auth.uid()
     and not exists (select 1 from public.shops s
                     where s.id = v_res.shop_id and s.owner_id = auth.uid()) then
    raise exception 'Action non autorisée.';
  end if;
  if v_res.status <> 'payee' then raise exception 'Réservation non active.'; end if;

  v_balance := v_res.total_amount - v_res.deposit_amount;
  update public.reservations set status = 'terminee' where id = p_id;
  insert into public.payments (payer_id, reservation_id, amount, kind, status)
  values (v_res.buyer_id, p_id, v_balance, 'solde', 'simule');
end; $$;

-- Annulation volontaire (jusqu'à 12 h avant l'échéance) → remboursement
-- intégral de l'acompte + ré-incrément du stock.
create or replace function public.cancel_reservation(p_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare v_res public.reservations%rowtype;
begin
  select * into v_res from public.reservations where id = p_id;
  if not found then raise exception 'Réservation introuvable.'; end if;
  if v_res.buyer_id <> auth.uid() then raise exception 'Action non autorisée.'; end if;
  if v_res.status <> 'payee' then raise exception 'Réservation non annulable.'; end if;
  if v_res.deadline is not null
     and v_res.deadline - now() < interval '12 hours' then
    raise exception 'Annulation impossible à moins de 12 h de l''échéance.';
  end if;

  update public.products set stock = stock + v_res.quantity
   where id = v_res.product_id;
  update public.reservations
     set status = 'annulee', refund_amount = v_res.deposit_amount
   where id = p_id;
  insert into public.payments (payer_id, reservation_id, amount, kind, status)
  values (v_res.buyer_id, p_id, v_res.deposit_amount, 'remboursement', 'rembourse');
end; $$;

-- Expiration auto des réservations échues (appelée par l'app à l'ouverture
-- de « Mes réservations »). Remboursement partiel 40 % à l'acheteur.
create or replace function public.expire_reservations()
returns integer
language plpgsql security definer set search_path = public as $$
declare v_res public.reservations%rowtype; v_count int := 0; v_refund numeric;
begin
  for v_res in
    select * from public.reservations
    where status = 'payee' and deadline is not null and deadline < now()
  loop
    v_refund := round(v_res.deposit_amount * 0.40, 2);
    update public.products set stock = stock + v_res.quantity
     where id = v_res.product_id;
    update public.reservations
       set status = 'expiree', refund_amount = v_refund
     where id = v_res.id;
    insert into public.payments (payer_id, reservation_id, amount, kind, status)
    values (v_res.buyer_id, v_res.id, v_refund, 'remboursement', 'rembourse');
    v_count := v_count + 1;
  end loop;
  return v_count;
end; $$;

-- =====================================================================
--  C) REALTIME (notifications + réservations)
-- =====================================================================
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime'
     and schemaname='public' and tablename='notifications') then
    alter publication supabase_realtime add table public.notifications;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime'
     and schemaname='public' and tablename='reservations') then
    alter publication supabase_realtime add table public.reservations;
  end if;
end $$;
alter table public.notifications replica identity full;
alter table public.reservations  replica identity full;

-- =====================================================================
--  FIN step6.sql
-- =====================================================================
