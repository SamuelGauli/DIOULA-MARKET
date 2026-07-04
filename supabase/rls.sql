-- =====================================================================
--  DIOULA MARKET — Row Level Security (RLS)
--  À exécuter APRÈS schema.sql, dans Supabase > SQL Editor.
--  Politiques volontairement simples (projet d'école). On durcira plus tard.
-- =====================================================================

-- Active RLS partout
alter table public.profiles     enable row level security;
alter table public.shops        enable row level security;
alter table public.products     enable row level security;
alter table public.requests     enable row level security;
alter table public.offers       enable row level security;
alter table public.reservations enable row level security;
alter table public.orders       enable row level security;
alter table public.order_items  enable row level security;
alter table public.reviews      enable row level security;
alter table public.payments     enable row level security;

-- ---------- Privilèges de TABLE (indispensables EN PLUS des policies) ----------
-- Une policy RLS ne donne pas le droit d'accès : il faut aussi GRANT au rôle.
-- Sans ça → « permission denied for table … (42501) ». Les RLS filtrent ensuite
-- les lignes réellement visibles par chaque utilisateur.
grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

-- S'applique aussi aux futures tables créées par la suite.
alter default privileges in schema public
  grant select on tables to anon, authenticated;
alter default privileges in schema public
  grant insert, update, delete on tables to authenticated;
alter default privileges in schema public
  grant usage, select on sequences to anon, authenticated;

-- ---------- Rejouable : on retire d'abord les policies existantes ----------
-- (Postgres n'a pas de "create or replace policy" ; on nettoie puis recrée.)
do $$
declare p record;
begin
  for p in
    select policyname, tablename
    from pg_policies
    where schemaname = 'public'
      and tablename in ('profiles','shops','products','requests','offers',
                        'reservations','orders','order_items','reviews','payments')
  loop
    execute format('drop policy if exists %I on public.%I', p.policyname, p.tablename);
  end loop;
end $$;

-- ---------- PROFILES ----------
-- Lecture publique (nom, note...), mais on ne modifie que SON profil.
create policy "profiles_select_all"  on public.profiles
  for select using (true);
create policy "profiles_insert_self" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_update_self" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- ---------- SHOPS ----------
create policy "shops_select_all"   on public.shops
  for select using (true);
create policy "shops_insert_owner" on public.shops
  for insert with check (auth.uid() = owner_id);
create policy "shops_update_owner" on public.shops
  for update using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "shops_delete_owner" on public.shops
  for delete using (auth.uid() = owner_id);

-- ---------- PRODUCTS ----------
-- Lecture publique ; écriture réservée au propriétaire de la boutique.
create policy "products_select_all" on public.products
  for select using (true);
create policy "products_write_owner" on public.products
  for all using (
    exists (select 1 from public.shops s
            where s.id = products.shop_id and s.owner_id = auth.uid())
  ) with check (
    exists (select 1 from public.shops s
            where s.id = products.shop_id and s.owner_id = auth.uid())
  );

-- ---------- REQUESTS (demandes instantanées) ----------
-- Visibles par tous les utilisateurs connectés (les commerçants doivent voir).
create policy "requests_select_auth" on public.requests
  for select using (auth.role() = 'authenticated');
create policy "requests_insert_owner" on public.requests
  for insert with check (auth.uid() = consumer_id);
create policy "requests_update_owner" on public.requests
  for update using (auth.uid() = consumer_id) with check (auth.uid() = consumer_id);
create policy "requests_delete_owner" on public.requests
  for delete using (auth.uid() = consumer_id);

-- ---------- OFFERS (offres) ----------
-- Visibles par l'auteur de l'offre ET par le consommateur propriétaire de la demande.
create policy "offers_select_involved" on public.offers
  for select using (
    auth.uid() = merchant_id
    or exists (select 1 from public.requests r
               where r.id = offers.request_id and r.consumer_id = auth.uid())
  );
create policy "offers_insert_merchant" on public.offers
  for insert with check (auth.uid() = merchant_id);
-- Le commerçant modifie son offre ; le consommateur peut l'accepter/refuser (status).
create policy "offers_update_involved" on public.offers
  for update using (
    auth.uid() = merchant_id
    or exists (select 1 from public.requests r
               where r.id = offers.request_id and r.consumer_id = auth.uid())
  );

-- ---------- RESERVATIONS ----------
-- Visibles par l'acheteur et par le propriétaire de la boutique.
create policy "reservations_select_involved" on public.reservations
  for select using (
    auth.uid() = buyer_id
    or exists (select 1 from public.shops s
               where s.id = reservations.shop_id and s.owner_id = auth.uid())
  );
create policy "reservations_insert_buyer" on public.reservations
  for insert with check (auth.uid() = buyer_id);
create policy "reservations_update_involved" on public.reservations
  for update using (
    auth.uid() = buyer_id
    or exists (select 1 from public.shops s
               where s.id = reservations.shop_id and s.owner_id = auth.uid())
  );

-- ---------- ORDERS ----------
create policy "orders_select_involved" on public.orders
  for select using (
    auth.uid() = buyer_id
    or auth.uid() = courier_id
    or exists (select 1 from public.shops s
               where s.id = orders.shop_id and s.owner_id = auth.uid())
  );
create policy "orders_insert_buyer" on public.orders
  for insert with check (auth.uid() = buyer_id);
create policy "orders_update_involved" on public.orders
  for update using (
    auth.uid() = buyer_id
    or auth.uid() = courier_id
    or exists (select 1 from public.shops s
               where s.id = orders.shop_id and s.owner_id = auth.uid())
  );

-- ---------- ORDER_ITEMS ----------
-- Accès via la commande parente.
create policy "order_items_select_involved" on public.order_items
  for select using (
    exists (select 1 from public.orders o
            where o.id = order_items.order_id
              and (o.buyer_id = auth.uid()
                   or o.courier_id = auth.uid()
                   or exists (select 1 from public.shops s
                              where s.id = o.shop_id and s.owner_id = auth.uid())))
  );
create policy "order_items_insert_buyer" on public.order_items
  for insert with check (
    exists (select 1 from public.orders o
            where o.id = order_items.order_id and o.buyer_id = auth.uid())
  );

-- ---------- REVIEWS ----------
-- Lecture publique ; on écrit/modifie/supprime uniquement ses propres avis.
create policy "reviews_select_all" on public.reviews
  for select using (true);
create policy "reviews_insert_author" on public.reviews
  for insert with check (auth.uid() = author_id);
create policy "reviews_update_author" on public.reviews
  for update using (auth.uid() = author_id) with check (auth.uid() = author_id);
create policy "reviews_delete_author" on public.reviews
  for delete using (auth.uid() = author_id);

-- ---------- PAYMENTS (simulés) ----------
create policy "payments_select_self" on public.payments
  for select using (auth.uid() = payer_id);
create policy "payments_insert_self" on public.payments
  for insert with check (auth.uid() = payer_id);

-- =====================================================================
--  FIN rls.sql
-- =====================================================================
