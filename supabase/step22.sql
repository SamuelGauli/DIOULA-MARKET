-- =====================================================================
--  DIOULA MARKET — ADMIN 1/3 : SOCLE + TABLEAU DE BORD GLOBAL
--  Helper is_admin(), compte démo admin@demo.ci, statistiques globales.
--  À exécuter dans : SQL Editor (après les précédents ; dépend de step12
--  pour le compteur KYC). Rejouable.
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Helper : l'utilisateur courant est-il admin ?
--     (utilisé par toutes les RPC admin et les policies à venir)
-- ---------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ---------------------------------------------------------------------
--  B) Compte démo admin@demo.ci / demo1234 (même mécanique que seed.sql)
-- ---------------------------------------------------------------------
do $$
declare
  uid uuid;
begin
  if exists (select 1 from auth.users where email = 'admin@demo.ci') then
    -- Compte déjà créé : on s'assure juste du rôle.
    update public.profiles set role = 'admin'
     where id = (select id from auth.users where email = 'admin@demo.ci');
    return;
  end if;

  uid := gen_random_uuid();

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) values (
    '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated',
    'admin@demo.ci', crypt('demo1234', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', 'Admin Dioula', 'phone', '0707000006',
                       'role', 'admin'),
    now(), now(),
    '', '', '', ''
  );

  insert into auth.identities (
    provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    'admin@demo.ci', uid,
    jsonb_build_object('sub', uid::text, 'email', 'admin@demo.ci',
                       'email_verified', true),
    'email',
    now(), now(), now()
  );

  -- Le trigger handle_new_user a créé le profil ; on force le rôle + commune.
  update public.profiles
     set role = 'admin', commune = 'Plateau'
   where id = uid;
end $$;

-- ---------------------------------------------------------------------
--  C) Statistiques globales de la plateforme (tableau de bord admin)
-- ---------------------------------------------------------------------
create or replace function public.admin_stats()
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare v jsonb;
begin
  if not public.is_admin() then
    raise exception 'Action non autorisée.';
  end if;

  select jsonb_build_object(
    'users_total',      (select count(*) from profiles),
    'users_by_role',    (select coalesce(jsonb_object_agg(role, n), '{}'::jsonb)
                           from (select role, count(*) n
                                   from profiles group by role) t),
    'kyc_pending',      (select count(*) from profiles
                          where verification_status = 'en_attente'),
    'shops_total',      (select count(*) from shops),
    'shops_active',     (select count(*) from shops where is_active),
    'products_total',   (select count(*) from products),
    'products_active',  (select count(*) from products where is_active),
    'orders_total',     (select count(*) from orders),
    'orders_by_status', (select coalesce(jsonb_object_agg(status, n), '{}'::jsonb)
                           from (select status, count(*) n
                                   from orders group by status) t),
    'gmv',              (select coalesce(sum(total_amount), 0) from orders
                          where status = 'livree'),
    'reservations_total', (select count(*) from reservations),
    'requests_open',    (select count(*) from requests where status = 'ouverte'),
    'reviews_total',    (select count(*) from reviews)
  ) into v;

  return v;
end; $$;

-- =====================================================================
--  FIN step22.sql
-- =====================================================================
