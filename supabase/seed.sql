-- =====================================================================
--  DIOULA MARKET — SEED (données de démonstration)
--  À exécuter dans : Supabase Dashboard > SQL Editor > New query
--  Ordre global : 1) schema.sql   2) rls.sql   3) seed.sql (ce fichier)
--
--  Contenu :
--    PARTIE A — crée 5 comptes démo dans Supabase Auth (mot de passe commun
--               'demo1234', email déjà confirmé → connexion directe).
--    PARTIE B — remplit profils, boutiques, produits, avis et demandes.
--
--  Idempotent : ré-exécutable. La PARTIE A saute les comptes déjà créés ;
--  la PARTIE B efface puis recrée les données métier des comptes démo.
--
--  ⚠️ Comptes démo (à connaître pour la soutenance) :
--     samira@demo.ci  (Consommatrice — Cocody)
--     raoul@demo.ci   (Commerçant   — « Chez Brou », Adjamé)
--     jacob@demo.ci   (Producteur   — « Ferme Kouamé », Agboville)
--     kader@demo.ci   (Livreur      — Yopougon)
--     anais@demo.ci   (Commerçante  — « Maquis Fatim », Treichville)
--     Mot de passe commun : demo1234
-- =====================================================================


-- =====================================================================
--  PARTIE A — COMPTES AUTH DÉMO
--  (Alternative : créer ces 5 utilisateurs à la main via
--   Authentication > Users > "Add user" en cochant "Auto Confirm User".
--   Dans ce cas, passe directement à la PARTIE B.)
-- =====================================================================
do $$
declare
  r   record;
  uid uuid;
begin
  for r in
    select * from (values
      ('samira@demo.ci', 'Traoré Samira',    '0707000001', 'consommateur'),
      ('raoul@demo.ci',  'Brou Raoul',       '0707000002', 'commercant'),
      ('jacob@demo.ci',  'Kouamé Jacob',     '0707000003', 'producteur'),
      ('kader@demo.ci',  'Yameogo Kader',    '0707000004', 'livreur'),
      ('anais@demo.ci',  'Coulibaly Anaïs',  '0707000005', 'commercant')
    ) as t(email, full_name, phone, role)
  loop
    -- Déjà présent ? on ne recrée pas.
    if exists (select 1 from auth.users where email = r.email) then
      continue;
    end if;

    uid := gen_random_uuid();

    -- Utilisateur auth (email confirmé → pas de mail de confirmation requis).
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated',
      r.email, crypt('demo1234', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('full_name', r.full_name, 'phone', r.phone, 'role', r.role),
      now(), now(),
      '', '', '', ''
    );

    -- Identité "email" (nécessaire pour la connexion mot de passe).
    insert into auth.identities (
      provider_id, user_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      r.email, uid,
      jsonb_build_object('sub', uid::text, 'email', r.email, 'email_verified', true),
      'email',
      now(), now(), now()
    );

    -- (Le trigger handle_new_user a déjà créé la ligne public.profiles.)
  end loop;
end $$;


-- =====================================================================
--  PARTIE B — DONNÉES MÉTIER (profils, boutiques, produits, avis, demandes)
-- =====================================================================
do $$
declare
  uid_samira uuid;
  uid_raoul  uuid;
  uid_jacob  uuid;
  uid_kader  uuid;
  uid_anais  uuid;
  -- ids de boutiques (fixes pour ce run)
  shop_brou    uuid := gen_random_uuid();
  shop_fatim   uuid := gen_random_uuid();
  ferme_kouame uuid := gen_random_uuid();
begin
  -- Récupère les ids démo par email (marche que les comptes viennent de la
  -- PARTIE A ou du dashboard).
  select id into uid_samira from auth.users where email = 'samira@demo.ci';
  select id into uid_raoul  from auth.users where email = 'raoul@demo.ci';
  select id into uid_jacob  from auth.users where email = 'jacob@demo.ci';
  select id into uid_kader  from auth.users where email = 'kader@demo.ci';
  select id into uid_anais  from auth.users where email = 'anais@demo.ci';

  if uid_raoul is null or uid_anais is null or uid_jacob is null then
    raise exception
      'Comptes démo introuvables : exécute d''abord la PARTIE A (ou crée-les via le dashboard).';
  end if;

  -- ---- Profils : compléter commune / géoloc / avatar ----
  update public.profiles set commune='Cocody',      latitude=5.3599, longitude=-3.9876,
         avatar_url='https://i.pravatar.cc/150?img=47' where id=uid_samira;
  update public.profiles set commune='Adjamé',       latitude=5.3604, longitude=-4.0241,
         avatar_url='https://i.pravatar.cc/150?img=12' where id=uid_raoul;
  update public.profiles set commune='Agboville',    latitude=5.9280, longitude=-4.2130,
         avatar_url='https://i.pravatar.cc/150?img=33' where id=uid_jacob;
  update public.profiles set commune='Yopougon',     latitude=5.3450, longitude=-4.0890,
         avatar_url='https://i.pravatar.cc/150?img=15' where id=uid_kader;
  update public.profiles set commune='Treichville',  latitude=5.2920, longitude=-4.0050,
         avatar_url='https://i.pravatar.cc/150?img=5'  where id=uid_anais;

  -- ---- Nettoyage des données démo précédentes (ré-exécutable) ----
  delete from public.requests
    where consumer_id in (uid_samira, uid_raoul, uid_jacob, uid_kader, uid_anais);
  -- delete shops → cascade products / reviews(shop) / réservations liées
  delete from public.shops
    where owner_id in (uid_raoul, uid_jacob, uid_anais);

  -- ---- Boutiques (2 commerçants + 1 producteur) ----
  insert into public.shops
    (id, owner_id, name, description, category, commune, address, phone,
     latitude, longitude, rating_avg, rating_count)
  values
    (shop_brou, uid_raoul, 'Chez Brou',
     'Épicerie & vivriers frais au marché Gouro.', 'Épicerie',
     'Adjamé', 'Marché Gouro, Adjamé', '0707000002',
     5.3604, -4.0241, 4.6, 23),
    (shop_fatim, uid_anais, 'Maquis Fatim',
     'Plats préparés ivoiriens : alloco, attiéké, garba.', 'Plats préparés',
     'Treichville', 'Rue 12, Treichville', '0707000005',
     5.2920, -4.0050, 4.8, 41),
    (ferme_kouame, uid_jacob, 'Ferme Kouamé',
     'Production locale : céréales, tubercules et légumes frais.', 'Producteur',
     'Agboville', 'Route d''Agboville', '0707000003',
     5.9280, -4.2130, 4.7, 12);

  -- ---- Produits (répartis sur les 2 boutiques + le producteur) ----
  insert into public.products
    (shop_id, name, description, category, unit, price, stock, image_url)
  values
    -- Ferme Kouamé (producteur)
    (ferme_kouame, 'Maïs en grain',      'Maïs séché local, sac de 50 kg.',           'Céréales & graines', 'sac',    18000, 25, 'https://picsum.photos/seed/mais/600/400'),
    (ferme_kouame, 'Riz local',          'Riz blanc de Côte d''Ivoire.',              'Céréales & graines', 'sac',    22000, 18, 'https://picsum.photos/seed/riz/600/400'),
    (ferme_kouame, 'Semences potagères', 'Lot de semences (tomate, piment, gombo).',  'Céréales & graines', 'sachet',  1500, 60, 'https://picsum.photos/seed/semences/600/400'),
    (ferme_kouame, 'Igname',             'Igname fraîche (variété Kponan).',          'Féculents',          'tas',     3000, 40, 'https://picsum.photos/seed/igname/600/400'),
    (ferme_kouame, 'Manioc',             'Manioc frais, récolté du jour.',            'Féculents',          'tas',     2000, 35, 'https://picsum.photos/seed/manioc/600/400'),
    (ferme_kouame, 'Banane plantain',    'Régime de plantain bien mûr.',              'Féculents',          'régime',  4000, 22, 'https://picsum.photos/seed/plantain/600/400'),
    (ferme_kouame, 'Aubergine gnagnan',  'Aubergine locale amère (gnagnan).',         'Légumes',            'tas',     1000, 50, 'https://picsum.photos/seed/gnagnan/600/400'),
    -- Chez Brou (épicerie)
    (shop_brou, 'Tomate fraîche', 'Tomates mûres, idéales pour la sauce.', 'Légumes',  'kg',    1200, 30, 'https://picsum.photos/seed/tomate/600/400'),
    (shop_brou, 'Oignon',         'Oignon violet, qualité marché.',        'Légumes',  'kg',    1000, 45, 'https://picsum.photos/seed/oignon/600/400'),
    (shop_brou, 'Piment frais',   'Piment fort local.',                    'Légumes',  'kg',    1500, 20, 'https://picsum.photos/seed/piment/600/400'),
    (shop_brou, 'Gombo',          'Gombo frais pour sauce.',               'Légumes',  'kg',    1300, 25, 'https://picsum.photos/seed/gombo/600/400'),
    (shop_brou, 'Huile rouge',    'Huile de palme rouge artisanale.',      'Épicerie', 'litre', 1500, 40, 'https://picsum.photos/seed/huilerouge/600/400'),
    (shop_brou, 'Poisson fumé',   'Poisson fumé (machoiron).',             'Poissons', 'kg',    3500, 15, 'https://picsum.photos/seed/poissonfume/600/400'),
    (shop_brou, 'Poisson frais',  'Carpe / machoiron du jour.',            'Poissons', 'kg',    2500, 18, 'https://picsum.photos/seed/poissonfrais/600/400'),
    -- Maquis Fatim (plats préparés)
    (shop_fatim, 'Alloco',  'Banane plantain frite, portion.',         'Plats préparés', 'portion', 1000, 100, 'https://picsum.photos/seed/alloco/600/400'),
    (shop_fatim, 'Attiéké', 'Boules d''attiéké (semoule de manioc).',   'Plats préparés', 'portion',  500, 100, 'https://picsum.photos/seed/attieke/600/400'),
    (shop_fatim, 'Garba',   'Attiéké + thon frit, la portion.',         'Plats préparés', 'portion', 1500,  80, 'https://picsum.photos/seed/garba/600/400');

  -- ---- Avis pré-remplis (écrans vivants) ----
  insert into public.reviews (author_id, shop_id, rating, comment) values
    (uid_samira, shop_brou,  5, 'Produits toujours frais, je recommande !'),
    (uid_samira, shop_fatim, 5, 'Le meilleur garba de Treichville 😋'),
    (uid_jacob,  shop_brou,  4, 'Bon accueil au marché Gouro.'),
    (uid_kader,  shop_fatim, 4, 'Service rapide, parfait pour les livraisons.');

  -- ---- Demandes instantanées en cours (exemples) ----
  insert into public.requests
    (consumer_id, title, product_name, quantity, unit, radius_km,
     latitude, longitude, status, expires_at)
  values
    (uid_samira, '20 kg d''oignons',            'Oignon',  20, 'kg',      10, 5.3599, -3.9876, 'ouverte', now() + interval '2 days'),
    (uid_samira, 'Attiéké pour 10 personnes',   'Attiéké', 10, 'portion',  5, 5.3599, -3.9876, 'ouverte', now() + interval '6 hours');

end $$;

-- =====================================================================
--  FIN seed.sql
--  Connexion de test : n'importe quel email ci-dessus + mot de passe demo1234
-- =====================================================================
