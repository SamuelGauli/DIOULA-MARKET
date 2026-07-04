-- =====================================================================
--  DIOULA MARKET — ÉTAPE 10a : HISTORIQUE DES ACTIONS (journal d'audit)
--  Chaque utilisateur retrouve l'historique de SES actions (demandes,
--  offres, réservations, commandes, livraisons, avis).
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Table journal + RLS
-- ---------------------------------------------------------------------
create table if not exists public.activity_log (
  id         uuid primary key default gen_random_uuid(),
  actor_id   uuid not null references public.profiles(id) on delete cascade,
  action     text not null,             -- code machine (order_created, …)
  detail     text not null,             -- libellé lisible
  entity     text,                      -- order / reservation / offer / review / request
  entity_id  uuid,
  created_at timestamptz not null default now()
);
create index if not exists idx_activity_actor
  on public.activity_log(actor_id, created_at desc);

alter table public.activity_log enable row level security;

drop policy if exists activity_select_self on public.activity_log;
create policy activity_select_self on public.activity_log
  for select using (auth.uid() = actor_id);

grant select on public.activity_log to authenticated;

-- ---------------------------------------------------------------------
--  B) Helper : journalise une action de l'utilisateur courant
-- ---------------------------------------------------------------------
create or replace function public.log_activity(
  p_action text, p_detail text, p_entity text, p_entity_id uuid
) returns void
language plpgsql security definer set search_path = public as $$
begin
  -- Pas d'utilisateur (seed, trigger système) → on ne journalise pas.
  if auth.uid() is null then return; end if;
  insert into public.activity_log (actor_id, action, detail, entity, entity_id)
  values (auth.uid(), p_action, p_detail, p_entity, p_entity_id);
end; $$;

-- ---------------------------------------------------------------------
--  C) Triggers de journalisation (after insert/update)
-- ---------------------------------------------------------------------

-- Demandes
create or replace function public.trg_requests_log() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    perform public.log_activity('request_published', 'Demande publiée',
      'request', new.id);
  end if;
  return null;
end; $$;
drop trigger if exists trg_requests_activity on public.requests;
create trigger trg_requests_activity after insert on public.requests
  for each row execute function public.trg_requests_log();

-- Offres
create or replace function public.trg_offers_log() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    perform public.log_activity('offer_made', 'Offre envoyée', 'offer', new.id);
  end if;
  return null;
end; $$;
drop trigger if exists trg_offers_activity on public.offers;
create trigger trg_offers_activity after insert on public.offers
  for each row execute function public.trg_offers_log();

-- Réservations
create or replace function public.trg_reservations_log() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    perform public.log_activity('reservation_created', 'Réservation créée',
      'reservation', new.id);
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    if new.status = 'terminee' then
      perform public.log_activity('reservation_done', 'Retrait confirmé',
        'reservation', new.id);
    elsif new.status = 'annulee' then
      perform public.log_activity('reservation_cancelled', 'Réservation annulée',
        'reservation', new.id);
    end if;
  end if;
  return null;
end; $$;
drop trigger if exists trg_reservations_activity on public.reservations;
create trigger trg_reservations_activity
  after insert or update on public.reservations
  for each row execute function public.trg_reservations_log();

-- Commandes / livraison
create or replace function public.trg_orders_log() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    perform public.log_activity('order_created', 'Commande passée', 'order', new.id);
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    if new.status = 'en_livraison' then
      perform public.log_activity('order_claimed', 'Course prise en charge',
        'order', new.id);
    elsif new.status = 'livree' then
      perform public.log_activity('order_delivered', 'Commande livrée',
        'order', new.id);
    end if;
  end if;
  return null;
end; $$;
drop trigger if exists trg_orders_activity on public.orders;
create trigger trg_orders_activity after insert or update on public.orders
  for each row execute function public.trg_orders_log();

-- Avis
create or replace function public.trg_reviews_log() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    perform public.log_activity('review_posted', 'Avis publié', 'review', new.id);
  end if;
  return null;
end; $$;
drop trigger if exists trg_reviews_activity on public.reviews;
create trigger trg_reviews_activity after insert on public.reviews
  for each row execute function public.trg_reviews_log();

-- =====================================================================
--  FIN step11.sql
-- =====================================================================
