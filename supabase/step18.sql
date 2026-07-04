-- =====================================================================
--  DIOULA MARKET — COMMIT 4 : NÉGOCIATION (contre-offre du client)
--  Le client peut proposer un autre prix sur une offre ; le vendeur
--  accepte (l'offre repasse au nouveau prix) ou refuse (prix maintenu).
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
--  Dépend de `push_notif` (step6.sql).
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Colonne prix proposé + statut 'contre_proposee'
-- ---------------------------------------------------------------------
alter table public.offers
  add column if not exists counter_price numeric null;

alter table public.offers drop constraint if exists offers_status_check;
alter table public.offers add constraint offers_status_check
  check (status in ('proposee', 'contre_proposee', 'acceptee', 'refusee'));

-- ---------------------------------------------------------------------
--  B) Le client contre-propose un prix (sur une offre 'proposee')
-- ---------------------------------------------------------------------
create or replace function public.counter_offer(
  p_offer_id uuid, p_price numeric, p_message text
) returns void
language plpgsql security definer set search_path = public as $$
declare v_offer public.offers%rowtype; v_consumer uuid;
begin
  select * into v_offer from public.offers where id = p_offer_id;
  if not found then raise exception 'Offre introuvable.'; end if;

  select consumer_id into v_consumer
    from public.requests where id = v_offer.request_id;
  if v_consumer is distinct from auth.uid() then
    raise exception 'Action non autorisée.';
  end if;
  if v_offer.status <> 'proposee' then
    raise exception 'Cette offre n''est pas négociable.';
  end if;
  if p_price is null or p_price <= 0 then raise exception 'Prix invalide.'; end if;

  update public.offers
     set counter_price = p_price, status = 'contre_proposee'
   where id = p_offer_id;

  perform public.push_notif(v_offer.merchant_id, 'offre',
    'Contre-proposition 💬',
    'Le client propose ' || p_price::text || ' FCFA'
    || case when p_message is not null and length(trim(p_message)) > 0
            then ' — « ' || p_message || ' »' else '' end);
end; $$;

-- ---------------------------------------------------------------------
--  C) Le vendeur ACCEPTE le prix → l'offre repasse 'proposee' au nouveau prix
-- ---------------------------------------------------------------------
create or replace function public.accept_counter(p_offer_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_offer public.offers%rowtype; v_consumer uuid;
begin
  select * into v_offer from public.offers where id = p_offer_id;
  if not found then raise exception 'Offre introuvable.'; end if;
  if v_offer.merchant_id <> auth.uid() then
    raise exception 'Action non autorisée.';
  end if;
  if v_offer.status <> 'contre_proposee' then
    raise exception 'Aucune contre-offre en attente.';
  end if;

  update public.offers
     set price = coalesce(v_offer.counter_price, v_offer.price),
         counter_price = null,
         status = 'proposee'
   where id = p_offer_id;

  select consumer_id into v_consumer
    from public.requests where id = v_offer.request_id;
  perform public.push_notif(v_consumer, 'offre',
    'Prix accepté ✅',
    'Le vendeur a accepté ton prix. Tu peux confirmer la commande.');
end; $$;

-- ---------------------------------------------------------------------
--  D) Le vendeur REFUSE → l'offre revient à son prix initial ('proposee')
-- ---------------------------------------------------------------------
create or replace function public.decline_counter(p_offer_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_offer public.offers%rowtype; v_consumer uuid;
begin
  select * into v_offer from public.offers where id = p_offer_id;
  if not found then raise exception 'Offre introuvable.'; end if;
  if v_offer.merchant_id <> auth.uid() then
    raise exception 'Action non autorisée.';
  end if;
  if v_offer.status <> 'contre_proposee' then
    raise exception 'Aucune contre-offre en attente.';
  end if;

  update public.offers
     set counter_price = null, status = 'proposee'
   where id = p_offer_id;

  select consumer_id into v_consumer
    from public.requests where id = v_offer.request_id;
  perform public.push_notif(v_consumer, 'offre',
    'Prix maintenu', 'Le vendeur a maintenu son prix initial.');
end; $$;

-- =====================================================================
--  FIN step18.sql
-- =====================================================================
