-- =====================================================================
--  DIOULA MARKET — ÉTAPE 5 : Demande instantanée (Realtime + acceptation)
--  À exécuter dans : Supabase Dashboard > SQL Editor (après schema/rls/seed).
--  Rejouable.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1) REALTIME : publier les tables requests & offers
--     (permet aux flux .stream() de recevoir les changements en direct)
-- ---------------------------------------------------------------------
do $$
begin
  -- La publication existe par défaut sur Supabase ; on la crée au besoin.
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'requests'
  ) then
    alter publication supabase_realtime add table public.requests;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'offers'
  ) then
    alter publication supabase_realtime add table public.offers;
  end if;
end $$;

-- Émettre la ligne complète lors des UPDATE (statut d'offre, etc.).
alter table public.requests replica identity full;
alter table public.offers   replica identity full;

-- ---------------------------------------------------------------------
--  2) ACCEPTATION D'UNE OFFRE (atomique)
--     → crée une commande + 1 ligne, accepte l'offre, refuse les autres,
--       clôt la demande. Renvoie l'id de la commande créée.
-- ---------------------------------------------------------------------
create or replace function public.accept_offer(p_offer_id uuid)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_offer    public.offers%rowtype;
  v_request  public.requests%rowtype;
  v_shop_id  uuid;
  v_order_id uuid;
begin
  select * into v_offer from public.offers where id = p_offer_id;
  if not found then
    raise exception 'Offre introuvable.';
  end if;

  select * into v_request from public.requests where id = v_offer.request_id;

  -- Seul le consommateur propriétaire de la demande peut accepter.
  if v_request.consumer_id <> auth.uid() then
    raise exception 'Action non autorisée.';
  end if;
  if v_request.status <> 'ouverte' then
    raise exception 'Cette demande est déjà clôturée.';
  end if;

  -- Boutique du vendeur (depuis l'offre, sinon sa 1re boutique).
  v_shop_id := coalesce(
    v_offer.shop_id,
    (select id from public.shops where owner_id = v_offer.merchant_id limit 1)
  );

  -- Commande + ligne de commande.
  insert into public.orders (buyer_id, shop_id, status, total_amount)
  values (
    v_request.consumer_id,
    v_shop_id,
    'en_cours',
    coalesce(v_offer.price, 0) * coalesce(v_offer.quantity, 1)
  )
  returning id into v_order_id;

  insert into public.order_items (order_id, product_name, quantity, unit_price)
  values (
    v_order_id,
    v_request.product_name,
    coalesce(v_offer.quantity, 1),
    coalesce(v_offer.price, 0)
  );

  -- Accepter cette offre, refuser les autres encore "proposee".
  update public.offers set status = 'acceptee' where id = p_offer_id;
  update public.offers
     set status = 'refusee'
   where request_id = v_offer.request_id
     and id <> p_offer_id
     and status = 'proposee';

  -- Clôturer la demande.
  update public.requests set status = 'pourvue' where id = v_request.id;

  return v_order_id;
end;
$$;

-- ---------------------------------------------------------------------
--  3) (OPTIONNEL) EXPIRATION AUTOMATIQUE des demandes échues
--     À appeler manuellement, ou via pg_cron si tu l'actives.
-- ---------------------------------------------------------------------
create or replace function public.expire_old_requests()
returns integer
language plpgsql
security definer set search_path = public
as $$
declare
  v_count integer;
begin
  update public.requests
     set status = 'expiree'
   where status = 'ouverte'
     and expires_at is not null
     and expires_at < now();
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- Exemple d'activation périodique (si l'extension pg_cron est disponible) :
-- select cron.schedule('expire-requests', '*/15 * * * *',
--   $$ select public.expire_old_requests(); $$);

-- =====================================================================
--  FIN step5_requests.sql
-- =====================================================================
