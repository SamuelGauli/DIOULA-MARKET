-- =====================================================================
--  DIOULA MARKET — Schéma de base de données (Supabase / PostgreSQL)
--  À exécuter dans : Supabase Dashboard > SQL Editor > New query
--  Ordre : 1) schema.sql  (ce fichier)   2) rls.sql   3) (option) seed.sql
-- =====================================================================

-- ---------- Extensions ----------
create extension if not exists pgcrypto;       -- gen_random_uuid()
-- create extension if not exists postgis;     -- (optionnel) géométrie avancée
-- On reste sur lat/lng + Haversine pour rester simple (voir nearby_shops()).

-- ---------- Helper : maj automatique de updated_at ----------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =====================================================================
--  1) PROFILS  (1 ligne par utilisateur auth, même id que auth.users)
-- =====================================================================
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  phone       text,
  role        text not null default 'consommateur'
              check (role in ('producteur','commercant','consommateur','livreur','admin')),
  avatar_url  text,
  commune     text,                 -- ex: Cocody, Yopougon...
  latitude    double precision,
  longitude   double precision,
  rating_avg  numeric(3,2) not null default 0,   -- note moyenne (calculée)
  rating_count integer     not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Création auto d'un profil à chaque inscription (auth.users -> profiles)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'phone', ''),
    coalesce(new.raw_user_meta_data->>'role', 'consommateur')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
--  2) BOUTIQUES  (un commerçant/producteur peut avoir une boutique)
-- =====================================================================
create table if not exists public.shops (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references public.profiles(id) on delete cascade,
  name        text not null,
  description text,
  category    text,
  logo_url    text,
  address     text,
  commune     text,
  phone       text,
  latitude    double precision,
  longitude   double precision,
  is_active   boolean not null default true,
  rating_avg  numeric(3,2) not null default 0,
  rating_count integer     not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists idx_shops_owner on public.shops(owner_id);

drop trigger if exists trg_shops_updated on public.shops;
create trigger trg_shops_updated
  before update on public.shops
  for each row execute function public.set_updated_at();

-- =====================================================================
--  3) PRODUITS  (catalogue d'une boutique, avec stock)
-- =====================================================================
create table if not exists public.products (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid not null references public.shops(id) on delete cascade,
  name        text not null,
  description text,
  category    text,
  unit        text not null default 'unité',   -- kg, sac, litre, unité...
  price       numeric(12,2) not null default 0,
  stock       numeric(12,2) not null default 0,
  image_url   text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists idx_products_shop on public.products(shop_id);
create index if not exists idx_products_category on public.products(category);

drop trigger if exists trg_products_updated on public.products;
create trigger trg_products_updated
  before update on public.products
  for each row execute function public.set_updated_at();

-- =====================================================================
--  4) DEMANDES INSTANTANÉES  (un consommateur publie un besoin)
-- =====================================================================
create table if not exists public.requests (
  id           uuid primary key default gen_random_uuid(),
  consumer_id  uuid not null references public.profiles(id) on delete cascade,
  title        text not null,                  -- ex: "20 kg d'oignons"
  product_name text not null,
  quantity     numeric(12,2),
  unit         text default 'unité',
  description  text,
  radius_km    numeric(6,2) not null default 10,
  latitude     double precision,
  longitude    double precision,
  status       text not null default 'ouverte'
               check (status in ('ouverte','pourvue','expiree','annulee')),
  expires_at   timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists idx_requests_consumer on public.requests(consumer_id);
create index if not exists idx_requests_status on public.requests(status);

drop trigger if exists trg_requests_updated on public.requests;
create trigger trg_requests_updated
  before update on public.requests
  for each row execute function public.set_updated_at();

-- =====================================================================
--  5) OFFRES  (réponses des commerçants à une demande)
-- =====================================================================
create table if not exists public.offers (
  id            uuid primary key default gen_random_uuid(),
  request_id    uuid not null references public.requests(id) on delete cascade,
  merchant_id   uuid not null references public.profiles(id) on delete cascade,
  shop_id       uuid references public.shops(id) on delete set null,
  price         numeric(12,2) not null,
  quantity      numeric(12,2),
  unit          text default 'unité',
  delivery_delay text,                          -- ex: "sous 2h", "demain"
  message       text,
  status        text not null default 'proposee'
                check (status in ('proposee','acceptee','refusee')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists idx_offers_request on public.offers(request_id);
create index if not exists idx_offers_merchant on public.offers(merchant_id);

drop trigger if exists trg_offers_updated on public.offers;
create trigger trg_offers_updated
  before update on public.offers
  for each row execute function public.set_updated_at();

-- =====================================================================
--  6) RÉSERVATIONS AVEC ACOMPTE  (paiement simulé)
-- =====================================================================
create table if not exists public.reservations (
  id            uuid primary key default gen_random_uuid(),
  product_id    uuid not null references public.products(id) on delete cascade,
  shop_id       uuid not null references public.shops(id) on delete cascade,
  buyer_id      uuid not null references public.profiles(id) on delete cascade,
  quantity      numeric(12,2) not null default 1,
  unit_price    numeric(12,2) not null default 0,
  total_amount  numeric(12,2) not null default 0,
  deposit_amount numeric(12,2) not null default 0,  -- acompte demandé
  deposit_paid  boolean not null default false,     -- acompte payé (simulé)
  refund_amount numeric(12,2) not null default 0,   -- remboursement si expirée
  status        text not null default 'en_attente'
                check (status in ('en_attente','payee','confirmee','terminee','annulee','expiree')),
  deadline      timestamptz,                          -- date limite de retrait
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists idx_reservations_buyer on public.reservations(buyer_id);
create index if not exists idx_reservations_shop on public.reservations(shop_id);
create index if not exists idx_reservations_status on public.reservations(status);

drop trigger if exists trg_reservations_updated on public.reservations;
create trigger trg_reservations_updated
  before update on public.reservations
  for each row execute function public.set_updated_at();

-- =====================================================================
--  7) COMMANDES + LIGNES DE COMMANDE
-- =====================================================================
create table if not exists public.orders (
  id              uuid primary key default gen_random_uuid(),
  buyer_id        uuid not null references public.profiles(id) on delete cascade,
  shop_id         uuid not null references public.shops(id) on delete cascade,
  courier_id      uuid references public.profiles(id) on delete set null, -- livreur
  status          text not null default 'en_cours'
                  check (status in ('en_cours','preparee','en_livraison','livree','annulee')),
  total_amount    numeric(12,2) not null default 0,
  delivery_address text,
  latitude        double precision,
  longitude       double precision,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists idx_orders_buyer on public.orders(buyer_id);
create index if not exists idx_orders_shop on public.orders(shop_id);
create index if not exists idx_orders_courier on public.orders(courier_id);

drop trigger if exists trg_orders_updated on public.orders;
create trigger trg_orders_updated
  before update on public.orders
  for each row execute function public.set_updated_at();

create table if not exists public.order_items (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders(id) on delete cascade,
  product_id  uuid references public.products(id) on delete set null,
  product_name text not null,          -- copie figée (au cas où produit supprimé)
  quantity    numeric(12,2) not null default 1,
  unit_price  numeric(12,2) not null default 0
);
create index if not exists idx_order_items_order on public.order_items(order_id);

-- =====================================================================
--  8) AVIS / NOTATION CROISÉE  (5 étoiles + commentaire)
--     author_id note target_id (et/ou une boutique).
-- =====================================================================
create table if not exists public.reviews (
  id          uuid primary key default gen_random_uuid(),
  author_id   uuid not null references public.profiles(id) on delete cascade,
  target_id   uuid references public.profiles(id) on delete cascade, -- user noté
  shop_id     uuid references public.shops(id) on delete cascade,    -- ou boutique notée
  order_id    uuid references public.orders(id) on delete set null,
  rating      integer not null check (rating between 1 and 5),
  comment     text,
  created_at  timestamptz not null default now(),
  -- empêche un même auteur de noter 2x la même cible pour la même commande
  unique (author_id, target_id, order_id)
);
create index if not exists idx_reviews_target on public.reviews(target_id);
create index if not exists idx_reviews_shop on public.reviews(shop_id);

-- =====================================================================
--  9) PAIEMENTS (SIMULÉS)  — trace des acomptes / paiements de démo
-- =====================================================================
create table if not exists public.payments (
  id              uuid primary key default gen_random_uuid(),
  payer_id        uuid not null references public.profiles(id) on delete cascade,
  reservation_id  uuid references public.reservations(id) on delete set null,
  order_id        uuid references public.orders(id) on delete set null,
  amount          numeric(12,2) not null,
  kind            text not null default 'acompte'
                  check (kind in ('acompte','solde','total','remboursement')),
  status          text not null default 'simule'   -- toujours "simulé" pour la démo
                  check (status in ('simule','paye','rembourse','echec')),
  created_at      timestamptz not null default now()
);
create index if not exists idx_payments_payer on public.payments(payer_id);

-- =====================================================================
--  10) GÉOLOCALISATION — distance Haversine + boutiques proches
-- =====================================================================
-- Distance en km entre deux points (lat/lng en degrés).
create or replace function public.distance_km(
  lat1 double precision, lng1 double precision,
  lat2 double precision, lng2 double precision
) returns double precision
language sql immutable
as $$
  select 6371 * 2 * asin(sqrt(
      power(sin(radians(lat2 - lat1) / 2), 2) +
      cos(radians(lat1)) * cos(radians(lat2)) *
      power(sin(radians(lng2 - lng1) / 2), 2)
  ));
$$;

-- Boutiques actives dans un rayon donné, triées par distance.
-- Appel depuis Flutter : supabase.rpc('nearby_shops', {lat, lng, radius_km})
create or replace function public.nearby_shops(
  lat double precision, lng double precision, radius_km double precision default 10
)
returns table (
  id uuid, name text, commune text, latitude double precision,
  longitude double precision, rating_avg numeric, distance_km double precision
)
language sql stable
as $$
  select s.id, s.name, s.commune, s.latitude, s.longitude, s.rating_avg,
         public.distance_km(lat, lng, s.latitude, s.longitude) as distance_km
  from public.shops s
  where s.is_active
    and s.latitude is not null and s.longitude is not null
    and public.distance_km(lat, lng, s.latitude, s.longitude) <= radius_km
  order by distance_km asc;
$$;

-- =====================================================================
--  FIN schema.sql  → enchaîner avec rls.sql
-- =====================================================================
