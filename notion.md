# 📒 Dioula Market — Documentation projet

> Application mobile **Flutter** : marketplace de commerce local (Côte d'Ivoire)
> reliant **producteurs, commerçants, consommateurs et livreurs**.
> Projet de soutenance — priorité à une **démo fonctionnelle**, livrée vite.

Ce document est la **source de vérité vivante** du projet. Il est mis à jour à
**chaque étape**.

---

## 1. Stack technique

| Couche        | Choix                                              |
|---------------|----------------------------------------------------|
| UI            | Flutter (Dart 3.8) — Material 3                     |
| État          | Riverpod (`flutter_riverpod` ^3.x)                 |
| Navigation    | `go_router` ^17                                    |
| Backend       | **Supabase** (Postgres, Auth, Storage, Realtime)   |
| Auth          | Email + mot de passe + **2FA SMS simulée**         |
| Paiement      | **Simulé** (acompte de réservation)                |
| Carte / Géo   | Haversine SQL + `flutter_map` (OSM) + `geolocator` (GPS) |
| Animations    | `flutter_animate` (effets natifs) + `confetti`     |
| Env / secrets | `flutter_dotenv` (`.env` non commité)              |

### Rôles utilisateurs
`producteur` · `commercant` · `consommateur` · `livreur` · `admin`
(stockés dans `profiles.role`).

### 🎨 Charte graphique (design system) — **refonte « marché ivoirien »**
Palette **tons terre chauds** (terracotta / ocre / beige profond), surfaces
**crème**, cartes blanches à **ombres douces**, sémantiques complètes.
On garde l'esprit des templates (Foodly + Rive) mais en **plus riche et coloré**,
façon vraie app de production. Police **Poppins** (`google_fonts`).

| Token | Hex | Usage |
|-------|-----|-------|
| `clay` (primary / CTA) | `#E0703A` | Terracotta — boutons, actions, liens |
| `clayDark` | `#C85A28` | Variante foncée (texte sur fond clair) |
| `ocre` (accent) | `#F2A03D` | Ambre — accents, badges secondaires |
| `beige` (marque) | `#C9A06B` | En-têtes, logo, aplats doux |
| `cream` (fond clair) | `#FBF4EA` | Scaffold clair (blanc cassé chaud) |
| `ink` (titres) | `#2A2018` | Texte principal (clair) |
| `body` | `#867B6C` | Texte secondaire |
| `inputLight` / `borderLight` | `#F6EEE1` / `#EFE5D6` | Champs & bordures (clair) |
| `bgDark` / `cardDark` | `#1C1712` / `#27201A` | Scaffold & cartes (sombre, brun chaud) |
| `success` / `warning` / `info` / `danger` | `#3FA86A` / `#E8A93C` / `#3E84C9` / `#E1493B` | Sémantiques |

- **Dégradés** : `accentGradient` (CTA), `headerGradient` (bannières chaudes),
  `brandGradient` (beige), `authGradient` (brun profond — onboarding).
- **Badges** produits : Promo (`clay`), Halal (`success`), Frais (`info`).
- Radius : champs/boutons 12, **cartes 18** (ombre douce, élévation visible).
  Boutons hauts (54 px). Bottom nav M3 : indicateur teinté `clay`.
- **Mode sombre** complet (clair / sombre / système), persistant 🌙/☀️.
- **Compatibilité** : les anciens noms `AppColors.green` / `.orange` / `.title`
  restent en **alias** (→ `clay` / `ocre` / `ink`) ; les écrans existants
  adoptent donc la nouvelle palette sans modification.
- Terracotta + ocre + beige = l'ambiance **terre / marché** ivoirien 🇨🇮.

---

## 2. Architecture des dossiers (feature-first)

```
lib/
├─ main.dart                  # bootstrap : dotenv + Supabase.initialize + runApp
├─ app.dart                   # MaterialApp.router + thème
├─ core/
│  ├─ config/env.dart         # lecture des variables .env
│  ├─ constants/app_constants.dart   # enums (rôles, statuts) + constantes
│  ├─ providers/supabase_provider.dart  # client + état d'auth
│  ├─ router/                 # routes.dart (chemins) + app_router.dart (go_router)
│  └─ theme/app_theme.dart    # thème (orange/vert ivoirien)
└─ features/                  # 1 dossier par fonctionnalité
   ├─ auth/         (data / domain / presentation)
   ├─ profile/
   ├─ shops/        (boutiques)
   ├─ products/
   ├─ requests/     (demandes instantanées)
   ├─ offers/       (offres des commerçants)
   ├─ reservations/ (réservation + acompte)
   ├─ orders/       (commandes + livraison)
   ├─ map/          (géolocalisation)
   ├─ reviews/      (notation croisée)
   ├─ dashboard/    (tableau de bord commerçant)
   └─ home/         (accueil temporaire)
```
Chaque feature suit `data` (accès Supabase) / `domain` (modèles) /
`presentation` (écrans + widgets + providers UI).

### Cartographie détaillée des fichiers (`lib/`)

| Fichier | Rôle |
|---------|------|
| `main.dart` | Démarrage : charge `.env`, initialise Supabase, lance l'app |
| `app.dart` | `MaterialApp.router` + thème |
| **core/config/** | |
| `env.dart` | Lit `SUPABASE_URL` / `SUPABASE_ANON_KEY` + `isConfigured` |
| **core/constants/** | |
| `app_constants.dart` | Enums (rôles, statuts), constantes (taux d'acompte) |
| **core/providers/** | |
| `supabase_provider.dart` | Client Supabase + flux d'auth + session courante |
| **core/router/** | |
| `routes.dart` | Constantes de chemins (`/login`, `/shop`, …) |
| `app_router.dart` | go_router + redirection selon session/2FA |
| **core/theme/** | |
| `app_colors.dart` | Palette (couleurs des templates, clair + sombre) |
| `app_theme.dart` | Thèmes Material 3 **clair & sombre** (Poppins) |
| `theme_provider.dart` | `ThemeMode` persistant (toggle dark mode) |
| **core/widgets/** | (composants UI réutilisables) |
| `primary_button.dart` | Bouton CTA (plein / dégradé, **animation au tap**, chargement) |
| `app_text_field.dart` | Champ de saisie stylé |
| `app_loader.dart` | Chargement animé (3 points rebondissants) |
| `animated_background.dart` | Fond animé (formes floutées en mouvement) |
| `app_card.dart` | Carte standard (arrondie, ombre douce, tap) |
| `app_badge.dart` | Badge pilule (Promo/Halal/Frais) + cloche de notif |
| `section_header.dart` | Titre de section + action « Voir tout » |
| `category_chip.dart` | Chip de catégorie colorée (sélectionnable) |
| `skeleton.dart` | Squelettes *shimmer* (états de chargement) |
| `empty_state.dart` | État vide illustré (icône + titre + action) |
| `theme_toggle_button.dart` | Bouton bascule clair/sombre |
| `guest_gate.dart` | Bouchon visiteur (invite à se connecter) |
| **features/auth/** | |
| `data/auth_repository.dart` | signUp / signIn / signOut (Supabase) |
| `presentation/auth_controller.dart` | Logique d'auth + 2FA + tuto + visiteur |
| `presentation/otp_controller.dart` | 2FA simulée (génère/vérifie le code) |
| `presentation/guest_provider.dart` | Mode visiteur (`guestMode`, `isGuest`) |
| `presentation/welcome_screen.dart` | Onboarding (accueil non connecté) |
| `presentation/login_screen.dart` | Écran de connexion |
| `presentation/register_screen.dart` | Inscription (avec choix du rôle) |
| `presentation/otp_screen.dart` | Saisie du code 2FA (+ secousse si code erroné) |
| `presentation/success_screen.dart` | Succès 2FA : coche animée + **confettis** |
| `presentation/widgets/auth_scaffold.dart` | Gabarit commun auth (fond animé + entrée) |
| **features/profile/** | |
| `domain/profile.dart` | Modèle `Profile` (rôle, géoloc, note) |
| `data/profile_repository.dart` | Lecture/MAJ profil + `currentProfileProvider` + upload KYC |
| `presentation/profile_page.dart` | Onglet Profil (infos + paramètres) |
| `presentation/kyc_screen.dart` | Vérification d'identité (dépôt pièces + statut) |
| **features/tutorial/** | |
| `domain/tutorial_step.dart` | Étapes du tuto **par rôle** (logique métier) |
| `presentation/tutorial_provider.dart` | Tuto en attente après inscription |
| `presentation/tutorial_screen.dart` | Écran du mini-tutoriel (PageView) |
| **features/shops/** | |
| `domain/shop.dart` | Modèle `Shop` (+ `fromMap`, `toWriteMap`, `copyWith`) |
| `data/shop_repository.dart` | CRUD boutique + `myShopProvider` |
| `presentation/shop_controller.dart` | Création / édition de la boutique |
| `presentation/my_shop_screen.dart` | « Ma boutique » (voir / gérer) |
| `presentation/shop_form_screen.dart` | Formulaire créer/éditer boutique |
| **features/products/** | |
| `domain/product.dart` | Modèle `Product` (prix, unité, stock) |
| `data/product_repository.dart` | CRUD produits + `productsByShopProvider` |
| `presentation/product_controller.dart` | Créer / éditer / supprimer produit |
| `presentation/products_screen.dart` | Liste des produits + suppression |
| `presentation/product_form_screen.dart` | Formulaire produit |
| **features/home/** | |
| `presentation/main_shell.dart` | Coquille + barre de navigation basse |
| `presentation/home_feed_page.dart` | **Accueil riche** (header, services, carrousel, sections vivantes, pull-to-refresh) |
| **features/catalog/** | (consultation publique du catalogue) |
| `domain/catalog_product.dart` | Produit + infos boutique (jointure) |
| `domain/instant_request.dart` | Résumé d'une demande ouverte |
| `domain/categories.dart` | Catégories (libellé + icône + couleur) |
| `data/catalog_repository.dart` | Lecture produits/boutiques/demandes + providers |
| `presentation/product_detail_screen.dart` | Fiche produit (Hero, actions gated) |
| `presentation/shop_detail_screen.dart` | Fiche boutique + ses produits |
| `presentation/search_screen.dart` | Recherche + filtres catégories |
| `presentation/widgets/product_card.dart` | Carte produit riche (+ `ProductImage`) |
| `presentation/widgets/shop_card.dart` | Carte boutique |
| `features/auth/.../widgets/guest_invite_sheet.dart` | Modale visiteur + `requireAccount()` |

| **features/requests/** | (demande instantanée — cœur, Realtime) |
| `domain/market_request.dart` | Modèle d'une demande |
| `domain/offer.dart` | Modèle d'une offre vendeur |
| `data/requests_repository.dart` | CRUD + **flux temps réel** + RPC `accept_offer` |
| `presentation/requests_hub_screen.dart` | Hub adapté au rôle (mes demandes / demandes ouvertes) |
| `presentation/create_request_screen.dart` | Formulaire de publication |
| `presentation/request_detail_screen.dart` | Offres temps réel + faire une offre + accepter |
| `presentation/widgets/request_bits.dart` | Pastille statut + libellés |
| **features/reservations/** | (réservation + acompte simulé) |
| `domain/reservation.dart` | Modèle réservation (+ jointures produit/boutique) |
| `data/reservations_repository.dart` | RPC reserve/complete/cancel/expire + providers |
| `presentation/reserve_screen.dart` | Quantité + échéance + acompte (30 %) |
| `presentation/fake_payment_screen.dart` | **Faux écran de paiement** (simulé) |
| `presentation/my_reservations_screen.dart` | Mes réservations + annulation (12h) |
| `presentation/shop_reservations_screen.dart` | Reçues (vendeur) : confirmer retrait |
| `presentation/widgets/reservation_card.dart` | Carte réservation (montants, statut) |
| **features/notifications/** | (in-app, temps réel) |
| `domain/app_notification.dart` | Modèle notification |
| `data/notifications_repository.dart` | Flux temps réel + non-lues + mark read |
| `presentation/notification_bell_button.dart` | Cloche + badge (connectée) |
| `presentation/notifications_screen.dart` | Liste des notifications |
| **features/map/** | (géolocalisation — carte de proximité) |
| `domain/nearby_shop.dart` | Boutique proche (position + distance calculée) |
| `data/location_service.dart` | Position GPS réelle (`geolocator`) + permissions |
| `data/map_repository.dart` | RPC `nearby_shops` + providers (position, rayon) |
| `presentation/nearby_map_screen.dart` | Carte OSM + marqueurs + liste triée par distance |
| `presentation/widgets/nearby_shop_tile.dart` | Ligne « boutique proche » (distance, note) |
| **features/reviews/** | (notation croisée 5 étoiles) |
| `domain/review.dart` | Modèle d'un avis (note, commentaire, auteur) |
| `data/reviews_repository.dart` | Lecture/écriture des avis + providers |
| `presentation/rating_sheet.dart` | Feuille de notation (étoiles + commentaire) |
| `presentation/widgets/star_rating.dart` | Étoiles (affichage + sélecteur) |
| `presentation/widgets/review_tile.dart` | Ligne d'avis (auteur, note, date, texte) |
| **features/dashboard/** | (tableau de bord commerçant) |
| `presentation/seller_dashboard_screen.dart` | Synthèse boutique : stats, stock bas, CA simulé |
| `presentation/widgets/dashboard_charts.dart` | Diagrammes (camembert réservations + barres CA) |
| **features/orders/** | (commandes & livraison — pool de livreurs) |
| `domain/order.dart` | Modèle commande (+ boutique, acheteur, articles) |
| `data/orders_repository.dart` | Pool / mes courses / mes commandes + RPC livraison |
| `presentation/courier_courses_screen.dart` | Livreur : disponibles + mes courses |
| `presentation/my_orders_screen.dart` | Acheteur : suivi de ses commandes |
| `presentation/shop_orders_screen.dart` | Vendeur : commandes reçues (suivi) |
| `presentation/order_tracking_screen.dart` | Suivi temps réel d'une commande + roadmap |
| `presentation/widgets/order_card.dart` | Carte commande (articles, adresse, statut) |
| `presentation/widgets/delivery_timeline.dart` | Roadmap du colis (étapes franchies) |
| `presentation/widgets/slot_picker.dart` | Feuille de choix de créneau (calendrier + plage) |

> Toutes les features prévues au déroulé sont désormais implémentées.

---

## 3. Base de données Supabase

Fichiers SQL à exécuter dans **SQL Editor** (dans l'ordre) :
1. [`supabase/schema.sql`](supabase/schema.sql) — tables, fonctions, triggers
2. [`supabase/rls.sql`](supabase/rls.sql) — Row Level Security
3. [`supabase/seed.sql`](supabase/seed.sql) — **données de démo** (comptes,
   boutiques, produits, avis, demandes). Ré-exécutable.
4. [`supabase/step5_requests.sql`](supabase/step5_requests.sql) — **étape 5** :
   active le **Realtime** sur `requests`/`offers` + fonction `accept_offer`
   (acceptation atomique) + `expire_old_requests` (optionnel). Ré-exécutable.
5. [`supabase/step6.sql`](supabase/step6.sql) — **étape 6** : table
   `notifications` (+ RLS, Realtime) & **triggers** (offres, réservations, stock
   bas) ; fonctions **réservation** `reserve_product` / `complete_reservation` /
   `cancel_reservation` / `expire_reservations` (acompte + stock auto).
   Ré-exécutable.
6. [`supabase/step8.sql`](supabase/step8.sql) — **étape 8** : notation croisée —
   colonne `reviews.reservation_id` (+ anti-doublon), **recalcul auto** des
   moyennes (`shops`/`profiles`) par trigger, notification de nouvel avis.
   Ré-exécutable (dépend de `push_notif` de step6).
7. [`supabase/step10.sql`](supabase/step10.sql) — **étape 10** : livraison —
   RLS « pool » pour les livreurs, fonctions `claim_order` / `mark_order_delivered`
   (+ notifications), Realtime sur `orders`, et **2 commandes de démo**.
   Ré-exécutable (dépend de `push_notif` de step6).
8. [`supabase/step11.sql`](supabase/step11.sql) — **étape 10a** : historique des
   actions — table `activity_log` (+ RLS) & `log_activity` + triggers
   (demandes, offres, réservations, commandes, avis). Ré-exécutable.
9. [`supabase/step12.sql`](supabase/step12.sql) — **étape 10b** : KYC — colonnes
   de vérification sur `profiles`, **bucket Storage `kyc-docs`** + politiques
   (créés par le script, rien à faire à la main), RPC `submit_kyc` /
   `simulate_verify_kyc`. Ré-exécutable.
10. [`supabase/step13.sql`](supabase/step13.sql) — **étape 10d** : créneaux —
    colonnes `slot_start`/`slot_end` sur `reservations` + `reserve_product`
    version « créneau » (remplace celle de step6). Ré-exécutable.
11. [`supabase/step14.sql`](supabase/step14.sql) — **étape 10e** : planning
    livreurs — colonnes de créneau sur `orders` + `claim_order` version
    « créneau » (remplace celle de step10, refuse un créneau déjà pris). Ré-exécutable.
12. [`supabase/step15.sql`](supabase/step15.sql) — **étape 10c** : CNI
    consommateur — RPC `submit_cni` (1 pièce) pour valider une grosse commande.
    Réutilise l'infra KYC de step12. Ré-exécutable.
13. [`supabase/step16.sql`](supabase/step16.sql) — **suivi détaillé** :
    `orders.delivery_step` + RPC `advance_delivery` (le livreur avance la
    livraison étape par étape). Ré-exécutable (dépend de `push_notif`).
14. [`supabase/step17.sql`](supabase/step17.sql) — **promo** : `products.promo_price`
    + `reserve_product` applique le **prix effectif** (promo si définie). Ré-exécutable.
15. [`supabase/step18.sql`](supabase/step18.sql) — **négociation** :
    `offers.counter_price` + statut `contre_proposee` + RPC `counter_offer` /
    `accept_counter` / `decline_counter`. Ré-exécutable (dépend de `push_notif`).
16. [`supabase/step19.sql`](supabase/step19.sql) — **vente en gros / en détail** :
    `products.sale_mode` (`detail` / `gros` / `les_deux`) + auto-classement des
    produits existants d'après l'unité (sac/carton/régime → gros). Ré-exécutable
    (le classement initial ne joue qu'au 1er passage, respecte les réglages vendeur).
17. [`supabase/step20.sql`](supabase/step20.sql) — **photos** : buckets Storage
    **publics** `avatars` + `shop-images` (+ politiques lecture publique / écriture
    dans son dossier) + `shops.banner_url`. Ré-exécutable.
18. [`supabase/step21.sql`](supabase/step21.sql) — **avis après commande** :
    `reviews.order_id` + index anti-doublon `(author_id, order_id)`. L'acheteur note
    la boutique (commentaire optionnel) après une **livraison**. Ré-exécutable
    (réutilise le trigger de recalcul de step8).
19. [`supabase/step22.sql`](supabase/step22.sql) — **admin 1/3 (socle)** : helper
    `is_admin()`, compte démo **admin@demo.ci** (rôle admin, même mécanique que le
    seed) et RPC `admin_stats()` (compteurs globaux du tableau de bord). Ré-exécutable.
20. [`supabase/step23.sql`](supabase/step23.sql) — **admin 2/3 (modération + KYC)** :
    `profiles.is_active`/`ban_reason`, RPC `admin_set_user_active` (bannir = suspend
    aussi ses boutiques) / `admin_set_shop_active` / `admin_set_product_active` /
    `admin_review_kyc` (approuver/refuser une identité), et policy Storage
    `kyc_select_admin` (l'admin lit les pièces du bucket privé). Chaque action
    notifie la cible et s'inscrit dans `activity_log`. Ré-exécutable.
21. [`supabase/step24.sql`](supabase/step24.sql) — **admin 3/3 (avis, annonces,
    audit)** : `reviews.is_hidden` + recalcul des moyennes **hors avis masqués**
    (remplace les fonctions de step8), RPC `admin_set_review_hidden` et
    `admin_broadcast` (annonce à tous les comptes actifs), et policy
    `activity_admin_select` (l'admin lit **tout** le journal). Ré-exécutable.

### 🌱 Comptes de démonstration (seed) — mot de passe commun `demo1234`
| Email | Rôle | Lieu / boutique |
|-------|------|-----------------|
| `samira@demo.ci` | Consommatrice | Cocody |
| `raoul@demo.ci` | Commerçant | « Chez Brou », Adjamé (marché Gouro) |
| `jacob@demo.ci` | Producteur | « Ferme Kouamé », Agboville |
| `kader@demo.ci` | Livreur | Yopougon |
| `anais@demo.ci` | Commerçante | « Maquis Fatim », Treichville |
| `admin@demo.ci` | **Admin** (supervision & modération) | Plateau — créé par `step22.sql` |

- Le seed crée ces comptes **email confirmé** (connexion directe) + ~17 produits
  répartis (céréales, légumes, plats préparés, poissons, féculents), des avis et
  2 demandes en cours.
- La **2FA simulée** s'applique à **toutes les connexions** (démo comprise) : après
  email + mot de passe, l'écran OTP s'affiche avec le **code visible** (un tap valide).
- Alternative à la PARTIE A du seed : créer les 5 users via *Authentication >
  Users > Add user* (cocher *Auto Confirm*), puis lancer la PARTIE B.

### Tables
| Table          | Rôle |
|----------------|------|
| `profiles`     | Profil utilisateur (lié à `auth.users`), rôle, géoloc, note |
| `shops`        | Boutiques virtuelles (1 propriétaire) |
| `products`     | Produits d'une boutique + stock |
| `requests`     | Demandes instantanées (besoin d'un consommateur) |
| `offers`       | Offres des commerçants en réponse à une demande |
| `reservations` | Réservation d'un produit + acompte (simulé) |
| `orders` / `order_items` | Commandes et leurs lignes |
| `reviews`      | Avis 5 étoiles (notation croisée) |
| `payments`     | Trace des paiements **simulés** |

### Fonctions / triggers clés
- `handle_new_user()` → crée automatiquement un `profiles` à l'inscription.
- `set_updated_at()` → met à jour `updated_at` sur modification.
- `distance_km(...)` + `nearby_shops(lat,lng,radius)` → boutiques proches (Haversine),
  appelable via `supabase.rpc('nearby_shops', {...})`.

---

## 4. Configuration Supabase (à faire côté dashboard)

> ⚠️ La clé **`service_role` ne doit JAMAIS** être mise dans l'app ni commitée.

1. **Créer le projet** sur [supabase.com](https://supabase.com) → noter la région.
2. **Récupérer les clés** : *Project Settings → API*
   - `Project URL`  → `SUPABASE_URL`
   - clé `anon public` → `SUPABASE_ANON_KEY`
3. **Configurer `.env`** à la racine du projet Flutter :
   ```
   cp .env.example .env       # puis remplir les 2 valeurs
   ```
4. **Exécuter le SQL** : SQL Editor → coller `schema.sql`, exécuter →
   puis `rls.sql`.
5. **Auth** : *Authentication → Providers → Email* activé.
   (Pour la démo on peut désactiver "Confirm email" pour aller plus vite.)
6. **Storage** (plus tard) : créer les buckets `avatars`, `shop-logos`,
   `product-images` (public en lecture).

---

## 5. Lancer l'application

```bash
flutter pub get
flutter run -d chrome        # test rapide sur le web (Chrome)
# plus tard : flutter run -d <émulateur Android>  (via Android Studio)
```
Tant que `.env` n'est pas rempli, l'app se lance quand même (mode démo) et
affiche « Supabase non configuré » sur l'écran d'accueil.

> **Web / Chrome** : `supabase_flutter` charge le SDK Passkeys (WebAuthn) sur le
> web. On ne l'utilise pas, mais il faut inclure son bundle pour éviter l'erreur
> « Passkeys Web SDK not loaded ». C'est fait : `web/bundle.js` + une balise
> `<script src="bundle.js">` dans `web/index.html`. **Garder `web/bundle.js` dans
> le dépôt** (nécessaire au build web).

---

## 6. Avancement par étapes

| # | Étape | Statut |
|---|-------|--------|
| 1 | Setup projet + structure + schéma SQL | ✅ Fait |
| 2 | Auth (email + mdp + 2FA SMS simulée) + profils/rôle | ✅ Fait |
| 3 | Boutiques + CRUD produits (stock) | ✅ Fait |
| 4 | Catalogue, recherche, fiche produit + boutique | ✅ Fait |
| 5 | Demande instantanée (Realtime) + offres + acceptation | ✅ Fait |
| 6 | Réservation avec acompte (simulé) + automatisations stock | ✅ Fait |
| 7 | Géolocalisation (carte, tri proximité) | ✅ Fait |
| 8 | Notation croisée 5 étoiles | ✅ Fait |
| 9 | Dashboard commerçant | ✅ Fait |
| 10 | Livraison (pool de livreurs) | ✅ Fait |
| 🎨 | Refonte UI (templates Foodly + Rive, dark mode) | ✅ Fait (3/3) |
| ➕ | Accès visiteur + mini-tuto par rôle | ✅ Fait |
| 🎬 | Animations (cahier des charges : fond, tap, succès…) | ✅ Fait |
| 🎨 | Design system « marché ivoirien » + seed démo | ✅ Fait |
| 🏠 | Accueil riche visiteur + catalogue + gating + bypass 2FA | ✅ Fait |
| ⚡ | Demande instantanée : publication + Realtime + offres + acceptation | ✅ Fait |
| 🎟️ | Réservation + acompte simulé + annulation 12h + stock auto | ✅ Fait |
| 🔔 | Notifications in-app temps réel (offres, réservations, stock) | ✅ Fait |
| 🗺️ | Géolocalisation : carte de proximité (flutter_map/OSM) + GPS réel + tri distance | ✅ Fait |
| ⭐ | Notation croisée : acheteur↔vendeur après retrait + recalcul des moyennes | ✅ Fait |
| 📊 | Dashboard commerçant : produits, stock bas, réservations, CA (simulé) | ✅ Fait |
| 🛵 | Livraison : pool de livreurs (prise en charge → livrée) + suivi acheteur | ✅ Fait |

### Journal
- **Étape 1** — Projet `dioula_market` initialisé (Flutter 3.32 / Dart 3.8).
  Dépendances : riverpod, go_router, supabase_flutter, flutter_dotenv, intl,
  cached_network_image. Structure feature-first créée. Schéma SQL complet
  (10 tables + RLS + fonctions géo) fourni. `.env` ignoré par git.
- **Étape 2** — Authentification fonctionnelle :
  - `features/auth` : `AuthRepository` (Supabase), `AuthController` (Riverpod
    `AsyncNotifier`), écrans `login` / `register` (avec choix du rôle) / `otp`.
  - **2FA SMS simulée** : génération d'un code 6 chiffres affiché à l'écran +
    log (`OtpController`), vérifié localement.
  - `features/profile` : modèle `Profile` + `ProfileRepository` +
    `currentProfileProvider` (profil + rôle de l'utilisateur connecté).
  - Le rôle choisi à l'inscription est créé en base par le trigger SQL
    `handle_new_user` (via les métadonnées d'auth).
  - Router : redirection automatique selon session + état 2FA
    (non connecté → login ; connecté + 2FA en attente → otp ; sinon → home).
  - Accueil authentifié : nom, rôle, bouton de déconnexion.
- **Étape 3** — Boutiques + produits (CRUD complet avec stock) :
  - `features/shops` : modèle `Shop`, `ShopRepository` (créer / éditer / lire),
    `myShopProvider` (la boutique de l'utilisateur), `ShopController`,
    écrans « Ma boutique » + formulaire créer/éditer.
  - `features/products` : modèle `Product`, `ProductRepository`
    (créer / lire / éditer / **supprimer**), `productsByShopProvider` (liste par
    boutique), `ProductController`, écran liste produits (avec stock + suppression
    confirmée) + formulaire (nom, catégorie, prix FCFA, unité, stock, image, desc).
  - Navigation : routes `/shop`, `/shop/form`, `/shop/products`,
    `/shop/products/form` ; entrée « Ma boutique & produits » depuis l'accueil
    (les fonctionnalités non encore dispo sont grisées 🔒).
  - Rafraîchissement automatique des écrans après chaque opération
    (`ref.invalidate`).
  - **Setup web/Chrome** : ajout de `web/bundle.js` (SDK Passkeys) + script dans
    `web/index.html` pour supprimer l'erreur « Passkeys Web SDK not loaded » au
    lancement sur Chrome. Titre/description de la page web mis à jour.

#### État actuel — ce qui marche déjà
- Créer un compte (avec rôle) → 2FA simulée → accueil.
- Créer / modifier sa boutique.
- Ajouter, modifier, supprimer des produits avec gestion du **stock**.
- Tout est protégé par les RLS (chacun ne gère que SA boutique / SES produits).
- Vérifié : `flutter analyze` = 0 problème, smoke test au vert.
- **Setup web/Chrome** : `web/bundle.js` (SDK Passkeys) ajouté.

- **🎨 Refonte UI — Partie 1/3 : Design system** — refonte du front-end pour
  reprendre exactement le style des templates Abu Anwar (Foodly + Rive) avec
  **mode sombre** :
  - Couleurs **extraites du code source** des templates (voir Charte graphique).
  - `core/theme/app_colors.dart` : palette complète (clair + sombre).
  - `core/theme/app_theme.dart` : thèmes **clair & sombre** (police **Poppins**
    via `google_fonts`), boutons/champs/cartes/chips/bottom-nav stylés.
  - `core/theme/theme_provider.dart` : `themeModeProvider` (clair/sombre/système)
    **persisté** avec `shared_preferences`.
  - `core/widgets/` : `PrimaryButton` (CTA, dégradé optionnel), `AppTextField`,
    `ThemeToggleButton` (bascule dark mode dans l'AppBar).
  - `app.dart`/`main.dart` branchés (light/dark/themeMode + chargement prefs).
  - Bouton 🌙/☀️ ajouté sur l'accueil pour tester le mode sombre.
  - Vérifié : `flutter analyze` = 0 problème, test au vert.
  - Suite : Partie 2 (auth/onboarding), Partie 3 (app principale).

- **🎨 Refonte UI — Partie 2/3 : Auth & onboarding** (style template Rive) :
  - `features/auth/presentation/widgets/auth_scaffold.dart` : gabarit commun
    (fond **dégradé navy**, barre haut avec retour + bascule thème, logo, titre,
    sous-titre, carte du formulaire). Réutilisé par tous les écrans d'auth.
  - **Nouvel écran d'accueil (onboarding)** `welcome_screen.dart` : point d'entrée
    des visiteurs non connectés, 2 CTA (Se connecter / Créer un compte).
  - `login_screen` / `register_screen` / `otp_screen` **refondus** avec le nouveau
    style (champs `AppTextField`, boutons `PrimaryButton`) — **logique inchangée**.
  - Router : route `/welcome` + redirection mise à jour (non connecté → welcome).
  - Le mode sombre s'applique automatiquement aux écrans d'auth (carte
    blanche/sombre sur le dégradé).
  - Vérifié : `flutter analyze` = 0 problème, test au vert.
  - Suite : Partie 3 (app principale : bottom-nav + home + boutiques/produits).

- **🎨 Refonte UI — Partie 3/3 : App principale** (style template Foodly) :
  - `features/home/presentation/main_shell.dart` : **coquille** avec
    **barre de navigation basse** (NavigationBar) → onglets *Accueil / Boutique /
    Profil* en `IndexedStack` (garde l'état). Remplace l'ancien `home_screen.dart`
    (supprimé).
  - `features/home/presentation/home_feed_page.dart` : **accueil façon Foodly** —
    salutation + avatar, barre de recherche, catégories horizontales, bannière
    promo (Demande instantanée), raccourcis (boutique actif, reste grisé).
  - `features/profile/presentation/profile_page.dart` : profil (avatar, rôle,
    email/tél) + **paramètres** (interrupteur mode sombre, accès boutique,
    déconnexion).
  - `products_screen.dart` : cartes produits **restylées** (vignette image via
    `cached_network_image`, prix en vert, badge de stock).
  - Tous les écrans existants profitent automatiquement du nouveau thème
    clair/sombre. **Aucune logique métier modifiée.**
  - Vérifié : `flutter analyze` = 0 problème, test au vert.
  - ✅ **Refonte front-end terminée (3/3).**

- **➕ Accès visiteur + mini-tutoriel par rôle** :
  - **Accès visiteur** : bouton « Continuer en visiteur » sur l'accueil →
    `guestModeProvider` ; le router laisse explorer l'app sans compte.
    `isGuestProvider` verrouille les sections réservées (Ma boutique, Profil)
    via le widget `GuestGate` (invite à se connecter / s'inscrire). L'accueil
    affiche « Visiteur ».
  - **Mini-tutoriel par rôle** (logique métier) : `tutorialStepsForRole(role)`
    renvoie 4 étapes différentes selon Producteur / Commerçant / Consommateur /
    Livreur. Affiché **une fois après l'inscription** (via `pendingTutorialProvider`,
    armé à l'inscription, consommé après l'OTP) et **« Revoir le tutoriel »**
    dans le profil. Écran `TutorialScreen` (PageView + points + Passer/Commencer).
  - Le logout réinitialise mode visiteur + tuto en attente.
  - Vérifié : `flutter analyze` = 0 problème, test au vert.

- **🎬 Animations (direction design du cahier des charges)** — reprise des
  effets du template Rive, **recréés en natif** avec `flutter_animate` +
  `confetti` (aucun asset payant, aucun fichier externe à télécharger) :
  - **Fond animé à formes floutées** (`core/widgets/animated_background.dart`) :
    grandes bulles vertes/orange qui dérivent et pulsent en boucle derrière un
    flou ; utilisé sur l'auth, l'onboarding et l'écran de succès.
  - **Bouton animé au tap** : `PrimaryButton` s'enfonce légèrement (scale) à
    l'appui ; en chargement il affiche `AppLoader` (3 points rebondissants).
  - **Animation d'erreur** : secousse (*shake*) du formulaire (login / register)
    et du champ code (OTP) quand la saisie est refusée.
  - **Succès + confettis** (`features/auth/.../success_screen.dart`, route
    `/success`) : après la 2FA, coche verte en rebond élastique + confettis,
    puis redirection auto vers le tutoriel (ou l'accueil).
  - **Icônes animées dans la bottom nav** : l'icône sélectionnée rebondit
    (élastique) à chaque changement d'onglet.
  - **Transitions fluides entre écrans** : toutes les routes go_router passent
    par une transition fondu + léger glissement (`pageBuilder` + `_fade`).
  - **Entrées animées légères** : fondu/glissement du contenu d'auth, des
    catégories et de la bannière de l'accueil, et de l'icône du tutoriel.
  - Dépendances ajoutées : `flutter_animate`, `confetti` (dans `pubspec.yaml`).
  - Vérifié : `flutter analyze` = 0 problème.

- **🎨 Refonte design system « marché ivoirien » (partie 1 — fondations)** :
  - **Nouvelle palette riche** (`core/theme/app_colors.dart`) : terracotta
    (`clay`, CTA), ocre (`ocre`), beige profond (`beige`), fond crème (`cream`),
    `ink`/`body`, sémantiques `success`/`warning`/`info`/`danger`, badges
    (Promo/Halal/Frais) et 4 dégradés. **Alias rétro-compat** (`green`→`clay`,
    `orange`→`ocre`, `title`→`ink`) → les écrans existants adoptent la palette
    sans modification.
  - **Thème refondu** (`core/theme/app_theme.dart`) : scaffold crème, cartes à
    **ombre douce** (élévation 6, radius 18), bottom nav **Material 3** stylée
    (indicateur teinté), typographie Poppins avec hiérarchie (titres gras).
  - **Composants clés** ajoutés : `AppCard`, `AppBadge` + `NotificationBell`,
    `SectionHeader`, `CategoryChip`, `Skeleton`/`ProductCardSkeleton`,
    `EmptyState`. (Prêts à assembler lors de la refonte des écrans.)
  - Fond animé re-teinté en tons chauds.
  - **Seed SQL** (`supabase/seed.sql`) : 5 comptes démo (email confirmé,
    `demo1234`), 3 boutiques, ~17 produits, avis et 2 demandes. Ré-exécutable.
    Constante `DemoAccounts` côté app (bypass 2FA à brancher à l'étape auth).
  - Vérifié : `flutter analyze` = 0 problème.
  - **Suite** : partie 2 = refonte des écrans (accueil riche visiteur,
    sections vivantes, cartes produits) + parcours visiteur→tuto→app + bypass 2FA.

- **🏠 Refonte des écrans (partie 2) — accueil riche + catalogue + parcours** :
  - **Feature `catalog`** : `CatalogRepository` (lecture publique) + providers
    `allProductsProvider`, `allShopsProvider`, `producerShopsProvider`,
    `openRequestsProvider`, `shopProductsProvider`. Modèles `CatalogProduct`
    (produit + boutique via jointure), `InstantRequest`, `categories`.
  - **Accueil riche** (`home_feed_page.dart`, consultable en **visiteur**) :
    en-tête (salutation + localisation + avatar + cloche notif), barre de
    recherche, **services** (Recherche, Demande, Réserver, Vendre, Livraison),
    **carrousel promo**, **catégories** colorées, et sections **En vedette /
    Près de vous / Producteurs locaux / Meilleures notes / Demandes en cours**
    (skeleton au chargement, états vides, **pull-to-refresh**, animations
    d'apparition).
  - **Cartes & écrans** : `ProductCard` (image **Hero**, badge frais/épuisé,
    note, prix, bouton +), `ShopCard`, **fiche produit** (`ProductDetailScreen`,
    image Hero, boutons Réserver/Demander), **fiche boutique**
    (`ShopDetailScreen` : grille de produits), **recherche** (`SearchScreen` :
    requête + filtres catégories).
  - **Parcours visiteur** : tout est **consultable** sans compte ; **toute
    action** (réserver, demander, suivre livraison, +) ouvre la **modale
    d'invitation** (`guest_invite_sheet.dart`, helper `requireAccount`).
  - **Bypass 2FA démo** : `AuthController.signIn` saute la 2FA pour les emails
    de `DemoAccounts` (connexion directe) ; le login route vers OTP ou accueil
    selon `otpPending`. La 2FA reste active pour une vraie inscription.
  - Routes ajoutées : `/search`, `/product`, `/shop/view`.
  - **Données** : alimenté par `supabase/seed.sql` (boutiques, produits, avis,
    demandes). Images = placeholders `picsum.photos` (remplaçables).
  - Vérifié : `flutter analyze` = 0 problème.

- **⚡ Étape 5 — Demande instantanée (cœur, temps réel)** :
  - **Feature `requests`** : `RequestsRepository` (publication, flux temps réel
    `.stream()`, soumission d'offre, RPC `accept_offer`, annulation) + modèles
    `MarketRequest` / `Offer` + providers Riverpod (`myRequestsStreamProvider`,
    `openRequestsStreamProvider`, `offersForRequestProvider`, `requestByIdProvider`).
  - **Parcours complet** : le consommateur **publie** une demande (produit,
    quantité, rayon, échéance) → elle apparaît **en direct** chez les vendeurs
    (hub « Demandes près de vous ») → un vendeur **soumet une offre** (prix,
    quantité, délai, message) → elle remonte **en direct** au consommateur →
    il **accepte** → la fonction SQL `accept_offer` crée la **commande**, passe
    l'offre en *acceptée*, les autres en *refusée*, et clôt la demande.
  - **Écrans** : hub adapté au rôle (`requests_hub_screen`), création
    (`create_request_screen`), détail temps réel (`request_detail_screen` :
    offres live, bottom sheet « Faire une offre », bouton « Accepter »).
  - **Câblage** : service « Demande » de l'accueil + cartes « Demandes en cours »
    → hub / détail (avec gating visiteur). Routes `/requests`, `/requests/new`,
    `/requests/detail`.
  - **SQL à exécuter** : `supabase/step5_requests.sql` (Realtime + `accept_offer`).
  - Vérifié : `flutter analyze` = 0 problème.

- **🧭 Cohérence des rôles (correctifs logique)** — l'app exposait les mêmes
  fonctionnalités à tous les rôles. Corrigé :
  - **Navigation basse adaptée au rôle** (`main_shell.dart`) :
    Consommateur/visiteur → *Accueil · Demandes · Profil* ;
    Commerçant/Producteur → *Accueil · Boutique · Demandes · Profil* ;
    Livreur → *Accueil · Courses (bientôt) · Profil*.
  - **Services de l'accueil adaptés au rôle** (`home_feed_page.dart`) : plus de
    « Vendre » pour un consommateur ; le vendeur voit *Ma boutique / Demandes /
    Tableau de bord* ; le livreur voit *Courses*.
  - **Boutique réservée aux vendeurs** : `MyShopScreen` bloque les rôles
    consommateur/livreur ; la tuile « Ma boutique » du profil n'apparaît que
    pour un vendeur.
  - **Hub demandes** : le livreur n'est plus traité comme un vendeur (écran
    « non concerné »).
  - **Extension `UserRoleX`** (`isSeller` / `isConsumer` / `isCourier`) +
    correctifs mineurs (avatar du profil affiché, cloche de notif sans faux compteur).
  - **Côté base** : ajout des `GRANT` table-level (anon/authenticated) dans
    `rls.sql` (sinon « permission denied 42501 » malgré les policies).
  - Vérifié : `flutter analyze` = 0 problème.

- **🎟️ Étape 6 — Réservation + acompte simulé + automatisations** :
  - **Parcours** : fiche produit → « Réserver » → quantité + échéance →
    récap (Total / **Acompte 30 %** / Solde) → **faux écran de paiement** →
    réservation **active** (`reserve_product` : crée la résa, **décrémente le
    stock**, trace l'acompte dans `payments`).
  - **Mes réservations** (acheteur) : liste + **annulation jusqu'à 12 h** avant
    l'échéance (remboursement intégral de l'acompte + ré-incrément du stock).
  - **Réservations reçues** (vendeur, depuis sa boutique) : **confirmer le
    retrait** (`complete_reservation` : solde réglé, statut terminée).
  - **Expiration auto** (côté app, à l'ouverture de l'écran) :
    `expire_reservations` → statut *expirée*, **remboursement 40 %** à
    l'acheteur (40 % vendeur / 20 % plateforme) + ré-incrément du stock.
  - **Stock** : décrément à la confirmation, ré-incrément à l'annulation/
    expiration, **alerte stock bas** (< 5) au vendeur (trigger).
  - Tout l'argent est **simulé** (table `payments` : acompte / solde /
    remboursement).
- **🔔 Notifications in-app (temps réel)** :
  - Table `notifications` + **triggers** : nouvelle offre → consommateur ;
    offre acceptée/refusée → vendeur ; nouvelle réservation → vendeur ;
    statut de réservation → acheteur ; **stock bas** → vendeur.
  - **Cloche connectée** dans l'accueil : badge du nombre de non-lues (temps
    réel), clic → écran des notifications (marquées lues à l'ouverture).
  - **SQL à exécuter** : `supabase/step6.sql`.
  - Vérifié : `flutter analyze` = 0 problème.

- **🗺️ Étape 7 — Géolocalisation (carte de proximité + tri par distance)** :
  - **Feature `map`** : modèle `NearbyShop` (boutique + distance), `LocationService`
    (position GPS **réelle** via `geolocator`, gestion des permissions avec
    messages d'erreur lisibles), `MapRepository` (appel de la fonction SQL
    `nearby_shops` — Haversine côté serveur) + providers Riverpod
    (`currentPositionProvider`, `selectedRadiusProvider`, `nearbyShopsProvider`).
  - **Écran carte** (`nearby_map_screen.dart`) : carte **OpenStreetMap**
    (`flutter_map`, sans clé API) centrée sur la position, **marqueur
    utilisateur** + un **marqueur par boutique** (tap → fiche boutique), **chips
    de rayon** (5 / 10 / 25 km / Tout) et **liste triée par distance** sous la
    carte. Bouton **« recentrer »**. États gérés : localisation en cours, erreur
    (permission refusée → « Réessayer » / « Ouvrir les réglages »), liste vide
    (→ bouton **« Tout voir »** qui élargit le rayon).
  - **Câblage** : route `/map` enregistrée ; service **« Carte »** sur l'accueil
    (consultable en visiteur) + action **« Voir la carte »** sur la section
    « Près de vous ».
  - **Permissions natives** : `ACCESS_FINE/COARSE_LOCATION` (Android),
    `NSLocationWhenInUseUsageDescription` (iOS). Web : autorisation navigateur.
  - **Aucun SQL à exécuter** : `nearby_shops` / `distance_km` sont déjà dans
    `schema.sql` ; les boutiques du seed ont déjà leurs coordonnées.
  - Dépendances ajoutées : `flutter_map`, `latlong2`, `geolocator`.
  - Vérifié : `flutter analyze` = 0 problème.

- **⭐ Étape 8 — Notation croisée (avis 5 étoiles)** :
  - **Croisée** : après un **retrait confirmé** (réservation *terminée*),
    l'**acheteur note la boutique** (depuis « Mes réservations ») **et** le
    **vendeur note l'acheteur** (depuis « Réservations reçues »). Bouton
    « Noter » remplacé par « Noté ✓ » une fois l'avis donné (anti-doublon).
  - **Feuille de notation** (`rating_sheet.dart`) : sélecteur d'étoiles 1–5 +
    commentaire optionnel. Widgets `StarsDisplay` / `StarPicker` / `ReviewTile`.
  - **Recalcul auto des moyennes** (SQL `step8.sql`) : un **trigger** recalcule
    `shops.rating_avg`/`rating_count` et `profiles.rating_avg`/`rating_count` à
    chaque insert/update/delete d'avis ; **notification** au destinataire.
  - **Affichage** : section **« Avis (N) »** sur la fiche boutique ; **note +
    étoiles** sur le profil (dès le 1ᵉʳ avis reçu). Les notes déjà présentes
    partout (cartes produits/boutiques) profitent du recalcul.
  - **SQL à exécuter** : `supabase/step8.sql` (dépend de `step6.sql`).
  - Vérifié : `flutter analyze` = 0 problème.

- **📊 Étape 9 — Tableau de bord commerçant** :
  - **Écran** (`seller_dashboard_screen.dart`, réservé aux vendeurs) : en-tête
    boutique (nom, commune, note), **4 tuiles** (Produits, Stock bas,
    Réservations actives, Retraits confirmés), carte **Chiffre d'affaires
    simulé** (CA confirmé / acomptes en attente / remboursé), **liste stock bas**
    (< 5) et raccourcis (Gérer mes produits / Réservations reçues).
  - **Agrégation** : tout est calculé côté app à partir des données déjà
    disponibles (`myShopProvider`, `productsByShopProvider`,
    `shopReservationsProvider`) — le CA est dérivé des **réservations** (lisibles
    par le vendeur via RLS), pas de la table `payments`. **Aucun SQL** à exécuter.
  - **Câblage** : route `/dashboard` enregistrée ; le service **« Tableau de
    bord »** de l'accueil (vendeur) ouvre l'écran (fin du placeholder « bientôt »).
  - Vérifié : `flutter analyze` = 0 problème.

- **🛵 Étape 10 — Livraison (pool de livreurs)** :
  - **Cycle de vie d'une commande** : créée à l'acceptation d'une offre
    (*en_cours*) → un **livreur la prend** (`claim_order` → *en_livraison*) →
    il la **marque livrée** (`mark_order_delivered` → *livree*).
  - **Espace livreur** (`courier_courses_screen.dart`, onglet « Courses ») :
    deux onglets **Disponibles** (le pool) et **Mes courses**. L'onglet
    « bientôt » du livreur est remplacé par cet écran réel.
  - **Suivi acheteur** (`my_orders_screen.dart`) : le service **« Commandes »**
    de l'accueil (ex-« Livraison ») liste ses commandes avec leur **statut**.
  - **Automatisations (SQL `step10.sql`)** : RLS additive pour que les livreurs
    voient le **pool** (commandes non assignées), fonctions atomiques (verrou de
    ligne pour éviter la double prise), **notifications** à l'acheteur et au
    vendeur (en route / livrée), Realtime sur `orders`, **2 commandes de démo**
    (amorcées si le pool est vide → kader a tout de suite des courses).
  - **SQL à exécuter** : `supabase/step10.sql` (dépend de `step6.sql`).
  - Vérifié : `flutter analyze` = 0 problème.

- **🔧 Cohérence (demandes) + carrousel dynamique** :
  - **Demandes réservées aux comptes concernés** : les **visiteurs** et les
    **livreurs** n'ont plus accès aux demandes — onglet « Demandes » masqué pour
    le visiteur (`main_shell`), section « Demandes en cours » et service
    « Demande » de l'accueil affichés **seulement** pour consommateur/vendeur
    (`home_feed_page`). Le hub restait déjà gated, c'est l'accueil qui exposait
    l'entrée.
  - **Carrousel** : auto-défilement en boucle (~4 s) + **bannières cliquables**
    (Demande → hub gated / Frais → recherche / Livraison → carte).
  - Pas de SQL, pas de nouvelle dépendance. Vérifié : `flutter analyze` = 0 problème.

- **📦 Suivi colis en temps réel (roadmap de livraison)** :
  - **Écran de suivi** (`order_tracking_screen.dart`) ouvrable depuis n'importe
    quelle carte commande (acheteur, vendeur, livreur) : récap + **roadmap
    verticale** (`delivery_timeline.dart`) Commande passée → Prise en charge →
    Livrée, qui **avance en direct**.
  - **Temps réel** : `orderLiveProvider` = `StreamProvider` sur la ligne `orders`
    (déjà publiée en Realtime à l'étape 10) → statut **et** `courier_id` live.
    Quand le livreur prend/livre, la timeline bouge instantanément côté acheteur
    et vendeur (sans rafraîchir).
  - **Action contextuelle** : le livreur peut **prendre** / **marquer livrée**
    directement depuis l'écran de suivi.
  - **Accès vendeur** : nouvel écran « Commandes de la boutique »
    (`shop_orders_screen.dart`) atteignable depuis le tableau de bord.
  - Pas de SQL (réutilise le Realtime de `step10.sql`), pas de dépendance.
    Vérifié : `flutter analyze` = 0 problème.

- **📈 Diagrammes du tableau de bord** :
  - Ajout de `fl_chart`. Le tableau de bord commerçant gagne un **camembert**
    « Réservations par statut » (actives / terminées / perdues) et un
    **histogramme** « Chiffre d'affaires (simulé) » (CA / acompte / remboursé),
    en plus des chiffres exacts déjà présents.
  - `presentation/widgets/dashboard_charts.dart` (`ReservationsPieChart` +
    `RevenueBarChart`), gère le cas « pas encore de données ».
  - Dépendance ajoutée : **`fl_chart 0.69`** (la 1.x exige un `vector_math` plus
    récent que celui du SDK → erreur `Matrix4.translateByDouble`). Pas de SQL.
    Vérifié : `flutter analyze` = 0 problème.

- **🩹 Correctifs run (web)** :
  - **Hero dupliqué** : un même produit pouvait apparaître dans « En vedette »
    ET « Meilleures notes » → tags de Hero en double. `ProductCard` accepte un
    `heroTag` ; chaque rail de l'accueil utilise un préfixe unique.
  - **Avatars** : nouveau widget `core/widgets/user_avatar.dart` (photo réseau
    avec **repli gracieux sur l'initiale** si l'image échoue — fini les
    `EncodingError` pravatar dans la console). Utilisé dans l'accueil, le profil
    et les avis.

- **🧾 Étape 10a — Historique des actions (journal d'audit)** :
  - Table `activity_log` + helper `log_activity` + **triggers** (demandes,
    offres, réservations, commandes/livraisons, avis) → chaque action de
    l'utilisateur est tracée (`step11.sql`).
  - **Feature `activity`** : `ActivityEntry`, `ActivityRepository`
    (`myActivityProvider`), écran **« Historique »** (icône par type + temps
    relatif), accessible depuis le **profil**. Chacun ne voit que **ses**
    actions (RLS `actor_id = auth.uid()`).
  - **SQL à exécuter** : `supabase/step11.sql`. Vérifié : `flutter analyze` = 0 problème.
  - *(Premier des 5 sous-lots « gros lot simulé » : 10a historique ✅, puis 10b
    KYC, 10c CNI consommateur, 10d calendrier de créneaux, 10e planning livreurs.)*

- **🪪 Étape 10b — KYC (vérification d'identité)** :
  - **Vendeurs / producteurs / livreurs** déposent **pièce d'identité** +
    **certificat de résidence** (via `image_picker`, téléversés dans le **bucket
    Storage privé `kyc-docs`**, dossier = uid) → statut **en vérification** puis
    **vérifié** (validation simulée `simulate_verify_kyc`).
  - **Écran « Vérification d'identité »** (`profile/presentation/kyc_screen.dart`)
    accessible depuis le profil ; **badge « Vérifié »** sur le profil et sur la
    **fiche boutique** (jointure `shops → profiles.verification_status`).
  - **Profil** : champs `verification_status` / `id_doc_path` /
    `residence_doc_path` ; RPC `submit_kyc`. **Tout le Storage est créé par
    `step12.sql`** (bucket + politiques RLS « chacun son dossier »).
  - Dépendance ajoutée : `image_picker`. **SQL à exécuter** : `supabase/step12.sql`.
    Vérifié : `flutter analyze` = 0 problème.
  - *Note : ici la vérification se fait depuis le profil (non bloquante) ; en prod
    elle serait exigée à l'inscription. La porte « obligatoire » arrive en 10c
    (CNI consommateur avant grosse commande).*

- **🗓️ Étape 10d — Calendrier de créneaux de livraison** :
  - La réservation se fait sur un **créneau** (jour + plage horaire) choisi dans
    un **calendrier** (`table_calendar`) au lieu d'une échéance libre.
  - **Règles simulées** : livraison à partir de **demain**, sur **14 jours**,
    **hors dimanche** ; plages ouvertes **08h–12h** / **14h–18h**.
  - `reserve_screen` : calendrier + chips de plage + récap du créneau ; le
    créneau (`slot_start`/`slot_end`) est stocké et affiché sur la carte
    réservation. `deadline` = fin du créneau → annulation 12h / expiration
    (step6) inchangées.
  - Dépendance ajoutée : `table_calendar`. **SQL à exécuter** : `supabase/step13.sql`.
    Vérifié : `flutter analyze` = 0 problème.
  - *(10c CNI consommateur reporté à la demande de l'utilisateur ; reste ensuite
    10e planning livreurs.)*

- **🛵 Étape 10e — Emplois du temps livreurs** :
  - À la **prise en charge** d'une course, le livreur choisit un **créneau**
    (feuille `showSlotPicker`, mêmes règles que 10d) → le créneau se **réserve
    dans son agenda** ; `claim_order` **refuse un 2ᵉ créneau identique**
    (un seul par créneau).
  - **Onglet « Planning »** dans l'espace livreur : agenda **groupé par jour**
    (heure du créneau + boutique + adresse, tap → suivi). Le créneau s'affiche
    aussi sur les cartes commande et l'écran de suivi.
  - `orders` gagne `slot_start`/`slot_end` ; provider `myScheduleProvider`.
  - **SQL à exécuter** : `supabase/step14.sql` (remplace `claim_order`). Vérifié :
    `flutter analyze` = 0 problème.

- **🪪 Étape 10c — CNI consommateur (grosse commande)** :
  - Avant de valider une **réservation de plus de 250 000 FCFA**
    (`kLargeOrderThreshold`), le consommateur doit avoir une **CNI vérifiée** ;
    sinon une **boîte de dialogue** l'invite à la renseigner (→ écran KYC).
  - **Écran KYC adapté au rôle** : le consommateur ne dépose qu'**une pièce**
    (CNI, RPC `submit_cni`) au lieu des 2 pièces des comptes pros.
  - La tuile « Vérification d'identité » du profil est désormais visible pour
    **tous les rôles**.
  - **SQL à exécuter** : `supabase/step15.sql` (dépend de step12). Vérifié :
    `flutter analyze` = 0 problème.
  - ✅ **Gros lot « simulé » terminé (10a→10e + 10c).**

- **🩹 Correctifs & améliorations (post-lot)** :
  - **Commit 1 — bugs & accès** : accueil **résilient** (la requête boutiques ne
    dépend plus d'une colonne KYC → fin de l'erreur `verification_status` ; badge
    « vérifié » via provider tolérant `shopOwnerVerifiedProvider`) ; **notifications
    cliquables** (navigation selon le type) ; carte **« Mon activité »** dans le
    profil (réservations / commandes / historique / dashboard selon le rôle) ;
    accès **historique** ajouté au tableau de bord. *Aucun SQL.*
  - **Commit 2 — suivi détaillé du colis** (`step16.sql`) : `orders.delivery_step`
    + RPC `advance_delivery`. Le **livreur fait avancer** la livraison
    (récupéré → en route → presque là → arrivé → livré) ; **timeline role-aware**
    (`delivery_timeline.dart`) : **6 étapes côté client**, **3 côté vendeur**, en
    **temps réel** (stream `orderLiveProvider`). Le livreur avance depuis « Mes
    courses » ou l'écran de suivi ; l'onglet **Planning** affiche l'action en cours.
  - **Commit 3 — boutique vendeur : promo + infos** (`step17.sql`) : le vendeur
    peut **mettre un produit en promo** (prix barré) pour éviter le gaspillage —
    action rapide « Promo » dans « Mes produits » + champ dans le formulaire. La
    **réservation applique le prix promo** (`reserve_product` utilise le prix
    effectif). Côté catalogue : **badge Promo** + **prix barré** + prix promo
    (cartes, fiche produit, écran de réservation).
  - **Commit 4 — négociation (contre-offre)** (`step18.sql`) : sur une offre, le
    client peut **« Négocier »** (proposer un prix + message → statut
    *contre-offre*) ; le vendeur **accepte** (l'offre repasse au nouveau prix,
    le client confirme) ou **refuse** (prix initial maintenu). Notifications aux
    deux parties. Temps réel via le flux `offers`.
  - **Commit 5 — images du carrousel** (*aucun SQL*) : chaque bannière promo de
    l'accueil affiche une **vraie image de fond** (Unsplash) + un **voile sombre**
    pour la lisibilité du texte blanc. Repli automatique sur le **dégradé** si
    l'image ne charge pas (via `CachedNetworkImage` + `errorWidget`, comme
    `UserAvatar`). Auto-défilement et bannières cliquables conservés.
  - **Flux consommateur — proximité + actualisation** (*aucun SQL*) : le rail
    « En vedette » et « Près de vous » priorisent les vendeurs **proches**
    (distance GPS réelle via `LocationService`, repli sur la **commune** du
    consommateur si le GPS est refusé/indispo — `feedPositionProvider` tolérant).
    Le **pull-to-refresh** fait tourner une **fenêtre glissante** (`feedTickProvider`)
    → d'autres articles apparaissent + SnackBar « Flux mis à jour ». Tri client via
    `distanceKm` (Haversine Dart, `core/utils/geo.dart`), coordonnées boutique
    ajoutées à `CatalogProduct`.
  - **Vente en gros / en détail** (`step19.sql`) : le vendeur classe chaque produit
    (`sale_mode` : détail / gros / les deux) dans le formulaire ; petit badge sur la
    tuile « Mes produits ». Côté consommateur, une rangée de **chips** (Tout / En
    détail / En gros — `feedSaleModeProvider`) **divise** les sections produits.
    Un produit « les deux » apparaît dans les deux filtres.
  - **Boutique plus fluide** (*aucun SQL*) : la fiche boutique gagne un en-tête
    **image de couverture** (`logoUrl` via `CachedNetworkImage`, repli dégradé +
    voile sombre), des **squelettes** (`ProductCardSkeleton`) au chargement des
    produits (au lieu du spinner), une grille plus aérée (espacement 16), un titre
    via `SectionHeader`, l'apparition des cartes **en cascade** (`fadeIn`/`slideY`)
    et des **squelettes** pour les avis.
  - **Logo & icône de l'app** (*aucun SQL*) : logo **généré dans le repo** (monogramme
    « D » terracotta sur disque crème) via `tool/generate_app_icon.dart` (package
    `image`), puis **`flutter_launcher_icons`** produit les icônes Android (adaptatif),
    iOS et web. Le logo remplace l'icône générique sur les écrans d'auth ; nom
    « Dioula Market » dans le manifest web. Régénérer : `dart run tool/generate_app_icon.dart`
    puis `dart run flutter_launcher_icons`.
  - **Photos de profil + bannière boutique** (`step20.sql`) : upload d'**avatar**
    (tous les rôles) via un nouvel écran **« Modifier mon profil »** (`profile_edit_screen`,
    bouton d'édition dans l'AppBar du profil) ; côté vendeur, upload **bannière + logo**
    dans le formulaire boutique (la **description** existait déjà). Images stockées dans
    des buckets **publics** (`avatars`, `shop-images`), URL publique enregistrée sur le
    profil/boutique. La fiche boutique affiche la **bannière** en couverture
    (`bannerUrl ?? logoUrl`). Réutilise le modèle d'upload KYC (`image_picker` +
    `uploadBinary` + `getPublicUrl`).
  - **2FA à chaque connexion + accès direct « Ma boutique »** (*aucun SQL*) : on retire
    le **bypass démo** dans `auth_controller.signIn` → l'écran **OTP** (code affiché en
    clair) s'affiche pour **toute** connexion, donc **constatable** en soutenance.
    « Ma boutique » gagne un bouton **« Voir ma boutique (vue client) »** qui ouvre la
    **fiche publique** (`ShopDetailScreen` via `shopView`), en plus de la gestion.
  - **Avis + commentaire après une commande** (`step21.sql`) : après la **livraison**
    d'une commande, l'acheteur peut **« Noter la boutique »** dans « Mes commandes » — la
    feuille de notation affiche le **commentaire (optionnel)**. Comme pour les
    réservations, le commentaire n'apparaît **qu'après un achat** ; il s'affiche ensuite
    dans la section **« Avis & commentaires »** de la boutique. `reviews.order_id` +
    anti-doublon ; note recalculée par le trigger de step8.
  - **Admin 1/3 — socle + tableau de bord global** (`step22.sql`) : helper SQL
    `is_admin()`, compte démo **admin@demo.ci** (demo1234), RPC `admin_stats()`
    (compteurs globaux). Côté app : raccourci `UserRoleX.isAdmin`, **onglets admin**
    dans la coquille (Accueil · **Supervision** · **Modération** · Profil), nouvelle
    feature `lib/features/admin/` avec le **tableau de bord global** (tuiles : users,
    boutiques, produits, commandes, **GMV**, réservations, demandes ; camembert
    commandes par statut ; barres utilisateurs par rôle ; alerte KYC en attente) et
    le **hub Modération** (tuiles verrouillées « bientôt », branchées aux commits 2-3).
    Routes `/admin/*` déclarées.
  - **Admin 2/3 — modération + KYC réel** (`step23.sql`) : 4 écrans branchés au hub —
    **Utilisateurs** (recherche + suspendre avec motif / réactiver ; bannir suspend
    aussi ses boutiques et le compte est **déconnecté** à la connexion suivante avec
    le motif), **Boutiques** et **Produits** (interrupteur actif/suspendu — le
    catalogue masque aussi les produits d'une boutique suspendue via une jointure
    `shops!inner`), **Vérifications (KYC)** (file `en_attente`, pièces consultées via
    **URL signée** du bucket privé, **Approuver/Refuser** → notif à l'utilisateur).
    Chaque action de modération est notifiée à la cible et tracée dans le journal.
  - **Admin 3/3 — avis, annonces & audit** (`step24.sql`) : 3 derniers écrans du hub —
    **Avis** (tous les avis ; **masquer/rétablir** un avis inapproprié → retiré des
    fiches boutique et **exclu du calcul de la note**, `reviews.is_hidden` + recalcul
    mis à jour), **Annonce** (formulaire titre+message → notification à **tous** les
    comptes actifs, `admin_broadcast`), **Audit global** (journal de **toute** la
    plateforme avec le nom de l'acteur, policy `activity_admin_select`). Le
    back-office admin est complet.

---

## 7. Notes & décisions

- **Géoloc** : lat/lng + Haversine SQL (`distance_km` / `nearby_shops`). La carte
  utilise `flutter_map` (OSM, sans clé) + `geolocator` (GPS réel). PostGIS reste
  possible plus tard (extension commentée dans `schema.sql`).
- **Paiement & SMS** : 100 % simulés pour la soutenance ; branchements réels
  (provider SMS, paiement mobile money) prévus après.
- **Animations** : effets du template Rive **recréés en natif** avec
  `flutter_animate` (+ `confetti` pour le succès). Choix volontaire de **ne pas**
  utiliser de fichiers Lottie externes pour garder la démo robuste (aucun
  téléchargement d'asset). On peut ajouter des `.json` Lottie gratuits plus tard
  si besoin, sans rien casser.
- **Git** : tous les commits/push sont faits manuellement (aucune commande git
  exécutée automatiquement).

---

## 8. 📖 Glossaire (termes techniques + exemples)

> Mis à jour à chaque nouveauté. Chaque terme est suivi d'un **exemple concret**
> tiré de Dioula Market.

### A. Flutter & Dart
- **Flutter** — Framework de Google pour créer des apps (Android, iOS, web) avec
  un seul code. *Ex. : toute l'app Dioula Market est écrite en Flutter.*
- **Dart** — Langage de programmation utilisé par Flutter.
  *Ex. : `final code = generate();` dans `OtpController` est du Dart.*
- **SDK** (*Software Development Kit*) — Ensemble d'outils pour développer.
  *Ex. : le « Flutter SDK 3.32 » contient le compilateur, les libs, l'émulateur.*
- **Widget** — Brique d'interface (bouton, texte, écran…). Tout est widget.
  *Ex. : `FilledButton(child: Text('Se connecter'))` est un widget bouton.*
- **StatelessWidget / StatefulWidget** — Widget sans état / avec état interne
  qui peut changer. *Ex. : `LoginScreen` est `StatefulWidget` car le champ
  mot de passe peut être masqué/affiché (`_obscure`).*
- **State (état)** — Données qui peuvent changer et redessinent l'écran.
  *Ex. : `_loading = true` affiche un spinner pendant la connexion.*
- **Hot reload** — Recharger le code instantanément sans tout relancer.
  *Ex. : on change une couleur du thème, l'app se met à jour en < 1 s.*
- **Package / dépendance** — Bibliothèque externe ajoutée au projet.
  *Ex. : `supabase_flutter` est un package listé dans `pubspec.yaml`.*
- **pubspec.yaml** — Fichier qui liste les dépendances et assets du projet.
  *Ex. : on y a déclaré `.env` comme asset et la dépendance `go_router`.*
- **Form / validation** — Regrouper des champs et vérifier leur saisie.
  *Ex. : le formulaire produit refuse un prix vide ou négatif.*
- **FloatingActionButton (FAB)** — Le bouton rond d'action principale.
  *Ex. : le bouton « + Ajouter » en bas de la liste des produits.*
- **Thème / ThemeData** — La charte visuelle centralisée (couleurs, police…).
  *Ex. : `AppTheme.light` et `AppTheme.dark` définissent tout le style.*
- **ColorScheme** — L'ensemble cohérent de couleurs d'un thème.
  *Ex. : `primary` = vert, `secondary` = orange.*
- **Mode sombre (dark mode) / ThemeMode** — Variante sombre de l'interface.
  *Ex. : `ThemeMode.dark` ; bascule via l'icône 🌙, choix gardé en mémoire.*
- **google_fonts** — Package pour utiliser des polices Google facilement.
  *Ex. : `GoogleFonts.poppins...` applique la police Poppins.*
- **shared_preferences** — Petit stockage clé/valeur local sur l'appareil.
  *Ex. : on y garde le mode de thème choisi (`theme_mode`).*
- **Dégradé (gradient)** — Transition douce entre plusieurs couleurs.
  *Ex. : le fond navy de l'écran d'accueil/onboarding (façon Rive).*
- **Onboarding** — Premier(s) écran(s) d'accueil avant de se connecter.
  *Ex. : `WelcomeScreen` avec « Se connecter » / « Créer un compte ».*
- **Barre de navigation basse (bottom nav)** — Les onglets en bas de l'écran.
  *Ex. : Accueil / Boutique / Profil (widget `NavigationBar`).*
- **IndexedStack** — Empile les écrans et n'en montre qu'un (garde leur état).
  *Ex. : changer d'onglet sans recharger la page précédente.*
- **Mode visiteur (guest)** — Explorer l'app sans compte (lecture seule).
  *Ex. : « Continuer en visiteur » ; Ma boutique/Profil restent verrouillés.*
- **Tutoriel par rôle** — Mini-guide d'accueil dont le contenu dépend du rôle.
  *Ex. : un Livreur et un Consommateur voient des étapes différentes.*
- **flutter_animate** — Package d'animations « en chaîne » (fondu, glissement,
  rebond, secousse…) sans gérer soi-même les contrôleurs.
  *Ex. : `widget.animate().fadeIn().slideY()` fait apparaître un widget en
  douceur.*
- **confetti** — Package qui projette des confettis à l'écran.
  *Ex. : explosion de confettis sur l'écran de succès après la 2FA.*
- **Lottie** — Format d'animations vectorielles (fichiers `.json`). Non utilisé
  ici (effets recréés en natif) mais possible plus tard. *Ex. : une coche
  animée téléchargée depuis LottieFiles.*
- **Transition de page** — Animation entre deux écrans (ici fondu + glissement).
  *Ex. : passer de `/login` à `/otp` se fait en fondu, pas d'un coup sec.*
- **Shake (secousse)** — Petite animation de tremblement signalant une erreur.
  *Ex. : le formulaire de connexion tremble si le mot de passe est faux.*
- **Hero (animation partagée) / heroTag** — Un même élément « vole » d'un écran à
  l'autre pendant la transition, identifié par un `tag` unique.
  *Ex. : la photo d'un produit s'agrandit de la carte vers la fiche produit
  (`Hero(tag: 'product-<id>')`).*
- **Sliver / SliverAppBar / CustomScrollView** — Des morceaux de liste défilante
  « avancés » : un `CustomScrollView` assemble des slivers, et une `SliverAppBar`
  est une barre d'app qui se replie en défilant. *Ex. : l'en-tête image de la fiche
  boutique se réduit quand on scrolle.*
- **FlexibleSpaceBar** — La zone d'une `SliverAppBar` qui contient l'image de fond
  et se déforme au défilement. *Ex. : la bannière de la boutique en couverture.*
- **Skeleton / shimmer** — Des rectangles gris animés (effet de brillance) affichés
  **pendant le chargement**, à la place du contenu. *Ex. : des cartes produit
  « fantômes » s'affichent le temps que la boutique charge.*
- **cached_network_image** — Affiche une image d'internet, la met en **cache** et
  montre une image de repli si le chargement échoue. *Ex. : les avatars et les
  bannières de boutique.*
- **image_picker** — Plugin qui ouvre la **galerie / l'appareil photo** pour choisir
  une image. *Ex. : changer sa photo de profil ou déposer une pièce KYC.*
- **fl_chart** — Bibliothèque de **graphiques** (camembert, barres). *Ex. : le
  diagramme des réservations et du chiffre d'affaires dans le tableau de bord.*
- **table_calendar** — Widget de **calendrier** pour choisir une date/un créneau.
  *Ex. : sélectionner le créneau de livraison d'une commande.*
- **flutter_launcher_icons** — Outil qui **génère l'icône de l'app** dans toutes les
  tailles (Android/iOS/web) depuis un seul logo. *Ex. : l'icône terracotta « D »
  produite depuis `assets/icon/app_icon.png`.*

### B. Architecture & gestion d'état
- **Architecture feature-first** — Organiser le code par fonctionnalité plutôt
  que par type. *Ex. : tout l'auth est dans `lib/features/auth/`.*
- **Riverpod** — Bibliothèque de gestion d'état (partager des données entre
  écrans). *Ex. : `currentProfileProvider` donne le profil partout dans l'app.*
- **Provider** — Objet Riverpod qui fournit une valeur.
  *Ex. : `authRepositoryProvider` fournit l'accès à l'auth Supabase.*
- **Notifier / AsyncNotifier** — Classe Riverpod qui contient une logique et un
  état modifiable (async = avec chargement/erreur).
  *Ex. : `AuthController extends AsyncNotifier` gère le login (loading→succès/erreur).*
- **ref.watch / ref.read** — Lire un provider en s'abonnant (watch) ou une seule
  fois (read). *Ex. : `ref.watch(currentProfileProvider)` redessine le home quand
  le profil change.*
- **Provider `.family`** — Provider paramétré (une instance par paramètre).
  *Ex. : `productsByShopProvider(shopId)` = les produits de CETTE boutique.*
- **ref.invalidate** — Forcer le rechargement d'un provider.
  *Ex. : après l'ajout d'un produit, on invalide la liste pour la rafraîchir.*
- **copyWith** — Créer une copie d'un objet en changeant quelques champs.
  *Ex. : `shop.copyWith(name: 'Nouveau nom')` lors de l'édition.*
- **ProviderScope** — Widget racine qui active Riverpod.
  *Ex. : `runApp(ProviderScope(child: DioulaApp()))` dans `main.dart`.*
- **go_router** — Bibliothèque de navigation par URL.
  *Ex. : `context.go('/otp')` envoie l'utilisateur vers l'écran 2FA.*
- **Route** — Une « page » identifiée par un chemin.
  *Ex. : `/login`, `/register`, `/otp`, `/` (home).*
- **Redirection (redirect)** — Renvoyer automatiquement vers une autre route
  selon une condition. *Ex. : non connecté → redirigé vers `/login`.*
- **Future / FutureProvider** — Un `Future` est une valeur **à venir** (résultat
  d'une opération async) ; un `FutureProvider` l'expose à l'UI. *Ex. :
  `allProductsProvider` charge les produits une fois.*
- **Stream / StreamProvider** — Un `Stream` est un **flux** de valeurs qui arrivent
  au fil du temps ; un `StreamProvider` le branche à l'UI. *Ex. :
  `offersForRequestProvider` reçoit les offres en **temps réel**.*
- **AsyncValue** — Le type renvoyé par ces providers : il représente les 3 états
  **chargement / donnée / erreur**. *Ex. : `async.when(loading:…, data:…, error:…)`
  affiche un squelette, la liste, ou un message.*

### C. Backend & base de données
- **Backend / Frontend** — Le serveur (données, logique) / l'app visible par
  l'utilisateur. *Ex. : Frontend = Flutter ; Backend = Supabase.*
- **Supabase** — Plateforme backend clé en main (base de données + auth +
  stockage + temps réel). *Ex. : nos tables et l'auth vivent dans Supabase.*
- **PostgreSQL** — Le moteur de base de données relationnelle utilisé par Supabase.
  *Ex. : `supabase/schema.sql` est du code PostgreSQL.*
- **Table** — Tableau de données (lignes/colonnes). *Ex. : la table `products`.*
- **Colonne** — Un champ d'une table. *Ex. : `products.price` (le prix).*
- **Clé primaire (primary key)** — Identifiant unique d'une ligne.
  *Ex. : `products.id` (un UUID unique par produit).*
- **Clé étrangère (foreign key)** — Colonne qui pointe vers une autre table.
  *Ex. : `products.shop_id` → `shops.id` (le produit appartient à une boutique).*
- **UUID** — Identifiant unique universel (long code aléatoire).
  *Ex. : `gen_random_uuid()` → `a1b2c3d4-…` pour l'id d'une boutique.*
- **Index** — Structure qui accélère les recherches.
  *Ex. : `idx_products_shop` accélère « tous les produits d'une boutique ».*
- **Trigger** — Code SQL exécuté automatiquement lors d'un événement.
  *Ex. : `handle_new_user` crée un profil dès qu'un compte est créé.*
- **Fonction SQL / RPC** — Procédure stockée appelable depuis l'app.
  *Ex. : `nearby_shops(lat,lng,10)` renvoie les boutiques à moins de 10 km.*
- **API** (*Application Programming Interface*) — Porte d'entrée pour parler au
  backend. *Ex. : Flutter appelle l'API Supabase pour lire `products`.*
- **CRUD** — Create / Read / Update / Delete (créer, lire, modifier, supprimer).
  *Ex. : un commerçant fait le CRUD de ses produits (étape 3).*
- **Realtime (temps réel)** — Recevoir les changements de la base en direct.
  *Ex. : un commerçant verra une nouvelle demande apparaître sans rafraîchir
  (étape 5).*
- **Storage / bucket** — Stockage de fichiers (images). Un **bucket public** est
  lisible par tous (avatars, images de boutique) ; un **bucket privé** est protégé
  (KYC). *Ex. : bucket public `avatars`, bucket privé `kyc-docs`.*
- **`.rpc()` (appel depuis Flutter)** — La méthode qui **exécute une fonction SQL**
  côté serveur depuis l'app. *Ex. : `supabase.rpc('advance_delivery', {…})` fait
  avancer la livraison d'une étape.*
- **security definer** — Une fonction SQL qui s'exécute avec les **droits de son
  créateur** (et non de l'appelant), pour agir de façon contrôlée malgré la RLS.
  *Ex. : `accept_offer` crée la commande et clôt la demande en une fois.*
- **GRANT (droits)** — Instruction SQL qui **autorise** un rôle à utiliser une table
  ou une fonction. *Ex. : donner à `authenticated` le droit d'exécuter une RPC.*
- **Journal d'audit (`activity_log`)** — Une table qui **enregistre les actions**
  importantes (qui a fait quoi, quand). *Ex. : « offre acceptée », « commande
  livrée » apparaissent dans l'écran Historique.*

### D. Sécurité & authentification
- **Authentification (Auth)** — Vérifier l'identité d'un utilisateur.
  *Ex. : email + mot de passe via Supabase Auth.*
- **Session** — État « connecté » d'un utilisateur, avec un jeton.
  *Ex. : après login, `currentSession` n'est pas `null`.*
- **Token / JWT** (*JSON Web Token*) — Jeton signé prouvant l'identité.
  *Ex. : la clé `anon` est un JWT ; la session en contient un aussi.*
- **Clé anon (anon key)** — Clé publique côté app, protégée par les RLS.
  *Ex. : `SUPABASE_ANON_KEY` dans `.env`, sans danger côté client.*
- **Clé service_role** — Clé secrète qui contourne toutes les sécurités.
  *Ex. : interdite dans l'app ; usage serveur uniquement.*
- **RLS (Row Level Security)** — Règles qui filtrent les lignes accessibles par
  utilisateur. *Ex. : un acheteur ne voit que SES réservations.*
- **Policy (politique RLS)** — Une règle RLS précise.
  *Ex. : `reviews_insert_author` : on ne peut créer un avis qu'en son nom.*
- **2FA (authentification à deux facteurs) / OTP (code à usage unique)** —
  2ᵉ preuve d'identité via un code temporaire.
  *Ex. : code à 6 chiffres « envoyé par SMS » (ici **simulé**, affiché à l'écran).*
- **Variable d'environnement / .env** — Réglage secret hors du code.
  *Ex. : `SUPABASE_URL` et `SUPABASE_ANON_KEY` dans `.env` (non commité).*
- **Passkeys / WebAuthn** — Connexion sans mot de passe (empreinte, visage,
  code de l'appareil). *Ex. : non utilisé ici, mais `supabase_flutter` charge son
  SDK sur le web → on inclut `web/bundle.js` pour éviter une erreur au démarrage.*

### E. Géolocalisation
- **Latitude / Longitude** — Coordonnées GPS d'un point.
  *Ex. : `shops.latitude` / `shops.longitude` situent une boutique.*
- **Haversine** — Formule de distance entre 2 points GPS.
  *Ex. : `distance_km(lat1,lng1,lat2,lng2)` calcule la distance en km.*
- **Rayon (radius)** — Distance maximale de recherche.
  *Ex. : une demande « oignons, rayon 10 km » cherche les boutiques ≤ 10 km.*
- **OpenStreetMap (OSM)** — Carte du monde libre et gratuite (sans clé API).
  *Ex. : les tuiles de la carte « Autour de moi » viennent d'OpenStreetMap.*
- **flutter_map** — Package Flutter qui affiche une carte interactive (zoom,
  déplacement) à partir de tuiles OSM. *Ex. : l'écran `NearbyMapScreen`.*
- **geolocator** — Package qui lit la **position GPS réelle** de l'appareil et
  gère les permissions. *Ex. : `LocationService.current()` renvoie ta position.*
- **Marqueur (marker)** — Épingle/pastille posée sur la carte à une position.
  *Ex. : un marqueur terracotta par boutique, un point bleu pour toi.*
- **Tuile (tile)** — Petite image carrée assemblée pour former la carte.
  *Ex. : `tile.openstreetmap.org/{z}/{x}/{y}.png`.*
- **Permission de localisation** — Autorisation demandée à l'utilisateur pour
  accéder au GPS. *Ex. : Android `ACCESS_FINE_LOCATION`, iOS
  `NSLocationWhenInUseUsageDescription`.*
- **`LatLng` (Position)** — Un couple (latitude, longitude) représentant un point
  précis, renvoyé par le GPS. *Ex. : `LocationService.current()` renvoie un `LatLng`
  qui sert à trier le flux.*
- **Tri par proximité** — Classer les articles/boutiques du **plus proche au plus
  loin** de l'utilisateur. *Ex. : sur l'accueil, les produits des vendeurs proches
  (ou de la même commune) passent en tête ; calcul via `distanceKm` (Haversine).*

### F. Spécifique au projet
- **Demande instantanée** — Un consommateur publie un besoin, les commerçants
  répondent. *Ex. : « 20 kg d'oignons, rayon 10 km » → table `requests`.*
- **Offre** — Réponse d'un commerçant à une demande (prix/quantité/délai).
  *Ex. : « 18 kg dispo à 8 000 FCFA, livré demain » → table `offers`.*
- **Acompte (simulé)** — Avance payée pour réserver un produit.
  *Ex. : 30 % du total réservé via un faux écran de paiement (étape 6).*
- **Notation croisée** — Les deux parties d'une transaction se notent
  mutuellement (5 étoiles). *Ex. : après un retrait, l'acheteur note la boutique
  et le vendeur note l'acheteur (étape 8) ; les moyennes sont recalculées par un
  trigger SQL.*
- **Commande (order)** — Achat créé quand un consommateur accepte une offre.
  *Ex. : table `orders` (+ `order_items`) ; statut `en_cours` → `en_livraison`
  → `livree`.*
- **Pool de livreurs** — File de commandes disponibles que n'importe quel
  livreur peut prendre en charge. *Ex. : kader voit les courses « Disponibles »,
  en prend une (verrou SQL anti-double-prise), puis la marque livrée (étape 10).*
- **Stock** — Quantité disponible d'un produit.
  *Ex. : `products.stock = 50` (50 kg d'oignons en stock).*
- **FCFA** — La monnaie (Franc CFA) utilisée pour les prix.
  *Ex. : un sac de riz affiché « 12 000 FCFA / sac ».*
- **Unité (de vente)** — Comment se vend un produit.
  *Ex. : `unit` = kg, sac, litre, régime, tas, carton, unité.*
- **Enum (énumération)** — Liste figée de valeurs possibles.
  *Ex. : `UserRole` = producteur / commercant / consommateur / livreur / admin.*
- **Vente en gros / en détail (`sale_mode`)** — Un produit se vend au **détail**
  (petites quantités), en **gros** (grosses quantités), ou **les deux**. Le
  consommateur filtre le flux avec des chips. *Ex. : un sac de riz en gros vs 1 kg de
  riz au détail.*
- **Promo (anti-gaspillage)** — Un **prix promo** temporaire, inférieur au prix
  normal, pour écouler un produit avant qu'il ne se perde. *Ex. : `promo_price` sur
  des tomates presque mûres → prix barré + badge « Promo ».*
- **Négociation / contre-offre** — Le client propose **un autre prix** sur une offre ;
  le vendeur accepte (l'offre repasse au nouveau prix) ou refuse. *Ex. : offre à
  8 000 FCFA → le client contre-propose 7 000 → statut `contre_proposee`.*
- **Suivi étape par étape (`delivery_step`)** — La livraison avance par **paliers**
  (récupéré → en route → presque là → livré) que le livreur fait progresser, visibles
  en temps réel. *Ex. : l'acheteur voit « Le livreur est presque là ».*
- **KYC / CNI (simulés)** — **Vérification d'identité** : dépôt d'une pièce (CNI) ou
  de documents pro, puis validation (ici **simulée**). *Ex. : un vendeur « vérifié »
  obtient un badge ; une grosse commande peut exiger la CNI.*
- **Avatar / bannière** — La **photo de profil** d'un utilisateur (`avatar_url`) et
  l'**image de couverture** d'une boutique (`banner_url`), stockées dans des buckets
  publics. *Ex. : la bannière s'affiche en haut de la fiche boutique.*

---

## 9. Pages clés (écrans les plus pertinents)

Description des écrans à montrer en priorité pour la soutenance (le fichier est
indiqué entre parenthèses).

| Écran | Rôle | Ce qu'on y fait |
|-------|------|-----------------|
| **Accueil** (`home_feed_page.dart`) | tous | Vitrine : recherche, services, carrousel, filtre **gros/détail**, sections vivantes triées par **proximité**, pull-to-refresh pour voir d'autres articles. |
| **Recherche** (`search_screen.dart`) | tous | Rechercher un produit/boutique + filtres par catégorie. |
| **Fiche produit** (`product_detail_screen.dart`) | tous | Détail d'un produit (image Hero, prix/promo, réserver — action gated). |
| **Fiche boutique** (`shop_detail_screen.dart`) | tous | Bannière de couverture, note, produits en grille, section **« Avis & commentaires »**. |
| **Ma boutique** (`my_shop_screen.dart`) | vendeur | Voir sa boutique en **vue client**, gérer produits, réservations reçues, éditer (logo/bannière/description). |
| **Formulaire produit** (`product_form_screen.dart`) | vendeur | Créer/éditer un produit : prix, stock, **promo**, **type de vente** (gros/détail). |
| **Demande & offres** (`request_detail_screen.dart`) | conso/vendeur | Offres en **temps réel** ; accepter ou **négocier** (contre-offre) ; le vendeur propose son prix. |
| **Créer une demande** (`create_request_screen.dart`) | conso | Publier un besoin (produit, quantité, rayon, position). |
| **Réservation** (`reserve_screen.dart`) | conso | Quantité, créneau, **acompte** (30 %, paiement simulé). |
| **Mes réservations** (`my_reservations_screen.dart`) | conso | Suivi + annulation + **noter la boutique** après retrait. |
| **Mes commandes** (`my_orders_screen.dart`) | conso | Suivi des livraisons + **noter la boutique** (commentaire) après livraison. |
| **Suivi de commande** (`order_tracking_screen.dart`) | tous | **Feuille de route** du colis en temps réel (le livreur avance les étapes). |
| **Espace livreur** (`courier_courses_screen.dart`) | livreur | Pool de courses disponibles + mes courses + planning. |
| **Carte** (`nearby_map_screen.dart`) | tous | Boutiques proches sur OpenStreetMap, triées par distance. |
| **Tableau de bord** (`seller_dashboard_screen.dart`) | vendeur | Statistiques + **diagrammes** + accès historique. |
| **Historique** (`activity_screen.dart`) | tous | Journal d'audit des actions (offres, commandes, avis…). |
| **Profil / Éditer** (`profile_page.dart` / `profile_edit_screen.dart`) | tous | Infos, note, **photo de profil** (upload), vérification, thème, déconnexion. |
| **2FA** (`otp_screen.dart`) | tous | Saisie du **code à usage unique** (affiché pour la démo) à chaque connexion. |
| **Vérification (KYC)** (`kyc_screen.dart`) | pros/conso | Dépôt de pièces d'identité (validation **simulée**). |

---

## 10. 🔐 Sécurité & 2FA — comment ça marche

La sécurité de Dioula Market est **en couches** (défense en profondeur) :

1. **Authentification Supabase** — email + mot de passe vérifiés par Supabase Auth ;
   mots de passe **hachés** (jamais en clair). Succès → une **session** = un jeton
   **JWT** signé + un *refresh token* (rester connecté).
2. **2FA (2ᵉ facteur)** — une étape de plus après le mot de passe (voir ci-dessous).
3. **RLS (Row Level Security)** — la vraie protection des **données** : chaque requête
   SQL est filtrée en base selon `auth.uid()` (un acheteur ne lit que **ses**
   commandes ; on n'écrit un avis qu'en son nom…).
4. **Secrets** — seule la clé **anon** (publique, protégée par les RLS) est dans
   `.env` (non commité). La clé `service_role` (qui contourne tout) n'est **jamais**
   embarquée.

**Déroulé concret de la 2FA (ici simulée) :**

| Étape | Ce qui se passe | Fichier |
|-------|-----------------|---------|
| 1 | `signIn` authentifie via Supabase, puis met `otpPendingProvider = true` (toute connexion) | `auth_controller.dart` |
| 2 | `generate()` tire un **code à 6 chiffres** aléatoire et l'« envoie » (ici : affiché + loggé) | `otp_controller.dart` |
| 3 | Tant que `otpPending` est vrai, le routeur **force** l'écran `/otp` | `app_router.dart` |
| 4 | L'utilisateur saisit le code ; `verify(input)` le compare | `otp_screen.dart` |
| 5 | Si correct → `otpPending = false` → succès → accueil (sinon secousse d'erreur) | `otp_screen.dart` |

> **Pourquoi simulée ?** Éviter un fournisseur SMS payant pour la soutenance tout en
> démontrant **le mécanisme** (un 2ᵉ facteur qui bloque l'accès jusqu'à validation).
> **Comment la rendre réelle ?** Remplacer l'étape « envoi » de `generate()` par un
> appel à un fournisseur (Twilio / Orange SMS API) — ou utiliser la **MFA native de
> Supabase** (TOTP) ; le reste du flux (drapeau + redirection + écran) ne change pas.

---

## 11. 🗄️ Supabase — usage, pourquoi, comment

**Usage (services utilisés) :**

| Service | Utilisation concrète | Accès dans le code |
|---------|----------------------|--------------------|
| **Auth** | Inscription / connexion, session JWT | `client.auth` |
| **PostgreSQL** | Toutes les tables métier | `client.from('table').select/insert/update` |
| **RLS** | Sécurité par ligne | `supabase/rls.sql` |
| **Realtime** | Offres, notifications, suivi en direct | `client.from('t').stream(primaryKey:['id'])` |
| **Storage** | Images (avatars, boutique, KYC) | `client.storage.from(bucket)` |
| **RPC** | Logique métier atomique | `client.rpc('nom', params:{…})` |

**Pourquoi ce choix :**
- **Zéro backend à coder/héberger** → tout le temps va à l'app Flutter (projet d'école).
- **PostgreSQL** : vraie base relationnelle (contraintes, jointures, **triggers**),
  pas une base « jouet ».
- **Auth + RLS intégrés** : multi-utilisateurs sécurisé **sans** écrire un serveur d'auth.
- **Realtime natif** : la fonctionnalité cœur (« demande instantanée ») fonctionne
  sans coder de websocket.
- **Gratuit + dashboard** pour la démo ; **open-source** (moins de verrou que Firebase).

**Comment c'est branché :**
- `main.dart` : `Supabase.initialize(url, anonKey)` (depuis `.env` via `env.dart`),
  **uniquement si** `Env.isConfigured` (l'app démarre quand même sinon, en mode démo).
- `supabase_provider.dart` : `supabaseProvider` (le client) + `authStateProvider`
  (flux d'auth) qui **pilote le routeur** (redirections selon la session/2FA).
- Les **scripts `supabase/*.sql`** (schema → rls → seed → step5…step21) créent tables,
  RLS, triggers, fonctions et **buckets**, à exécuter dans le **SQL Editor**.
- Chaque feature a un **repository** qui encapsule le client (`.from`, `.stream`,
  `.rpc`, `.storage`) — ex. `CatalogRepository`, `OrdersRepository`,
  `ReviewsRepository`.

---

## 12. 📍 Géolocalisation — usage, pourquoi, comment

**Usage :**
- **Carte de proximité** (`nearby_map_screen.dart`) : boutiques proches sur une carte,
  triées par distance, avec un filtre de rayon (5/10/25 km, « Tout voir »).
- **Priorité proximité** de l'accueil : les articles des vendeurs proches d'abord.

**Pourquoi :** le commerce local est une affaire de **proximité** ; trier/cartographier
par distance est l'expérience attendue par l'acheteur.

**Comment c'est fait :**
- **Position réelle** : `geolocator` via `LocationService.current()` → `LatLng`
  (`latlong2`), avec **permission** + **timeout 20 s**. Permissions : Android
  `ACCESS_FINE/COARSE_LOCATION`, iOS `NSLocationWhenInUseUsageDescription`.
- **Distance**, deux implémentations cohérentes :
  - **Serveur (SQL)** : `distance_km(...)` (Haversine) + `nearby_shops(lat,lng,radius)`
    (renvoie déjà **trié** par distance) — `map_repository.dart`.
  - **Client (Dart)** : `distanceKm(...)` (`core/utils/geo.dart`, miroir de la formule)
    pour trier l'accueil **sans requête serveur**.
- **Carte** : `flutter_map` + tuiles **OpenStreetMap** (libres, sans clé) + marqueurs.
- **Repli** : GPS refusé/indispo → tri par **commune** (robuste, marche sur le web).
- **Providers** : `currentPositionProvider` (GPS), `selectedRadiusProvider` (rayon),
  `nearbyShopsProvider` (position × rayon) ; côté accueil `feedPositionProvider`.

---

## 13. ▶️ Lancer depuis Android Studio

1. **Android Studio** + **plugin Flutter** (installe Dart) : *Settings → Plugins*.
2. *File → Open…* → ouvrir le dossier `projet_final/`.
3. Vérifier le **SDK Flutter** : *Settings → Languages & Frameworks → Flutter*
   (`flutter doctor` au besoin).
4. Créer **`.env`** (copie de `.env.example`) et le remplir (URL + clé anon).
5. **Pub get** (bandeau en haut) ou `flutter pub get`.
6. **Appareil** : *Tools → Device Manager → Create Device* (émulateur) **ou** un
   téléphone réel (*Options développeur* + *Débogage USB*).
7. Choisir l'appareil dans la barre du haut → **Run ▶** (`Shift+F10`).

> 1ʳᵉ build Android plus longue (Gradle). Autoriser la **localisation** à la demande.
> Sans `.env`, l'app démarre en mode démo (« Supabase non configuré »).

---

## 14. 🔌 API & fonctions (RPC)

Pas de backend REST maison : l'app consomme des **API managées Supabase** + des
**API externes**.

**API Supabase** (SDK `supabase_flutter`) : **Auth**, **Data (PostgREST)** — REST
auto-généré sur les tables (`.from()`), **Realtime** (`.stream()`), **Storage**
(`.storage`). Chaque requête porte le **JWT** ; la **RLS** décide de l'autorisé.

**Fonctions RPC (PostgreSQL)** — `client.rpc(nom, params)`, logique atomique côté
serveur (certaines `security definer`) :

| Fonction | Rôle |
|----------|------|
| `nearby_shops(lat,lng,radius_km)` | Boutiques dans le rayon, triées par distance. |
| `distance_km(...)` | Distance Haversine (interne). |
| `accept_offer(p_offer_id)` | Accepte une offre : crée la commande, clôt la demande, refuse les autres. |
| `counter_offer / accept_counter / decline_counter` | Négociation (contre-offre ↔ réponse vendeur). |
| `reserve_product(id, qty, slot_start, slot_end)` | Réservation : acompte + créneau + stock (prix promo inclus). |
| `complete_reservation / cancel_reservation / expire_reservations` | Cycle de la réservation. |
| `claim_order(...)` | Prise de course par un livreur (verrou anti-double-prise). |
| `mark_order_delivered / advance_delivery(p_order_id)` | Progression de la livraison. |
| `submit_kyc / submit_cni / simulate_verify_kyc` | Vérification d'identité (simulée). |
| `push_notif(...)` | Crée une notification (appelée par les triggers). |

**API externes :** **OpenStreetMap Tile API** (`tile.openstreetmap.org/{z}/{x}/{y}.png`,
fond de carte libre) ; **Unsplash** (images du carrousel) ; **GPS de l'OS** (via
`geolocator`).

---

## 15. 💼 Modèle économique (business model)

> Modèle pensé pour un lancement réaliste à Abidjan puis en Côte d'Ivoire.

**Proposition de valeur.** Dioula Market **connecte** l'offre locale (commerçants,
producteurs) et la demande (consommateurs), avec **logistique** (livreurs) et
**confiance** (notation, KYC). On réduit le temps de recherche, on met en concurrence
les vendeurs (offres/négociation) et on limite le **gaspillage** (promos).

### Sources de revenus
| # | Source | Principe | Ordre de grandeur |
|---|--------|----------|-------------------|
| 1 | **Commission sur transaction** (*take rate*) | % prélevé sur chaque commande/réservation payée via la plateforme | **5–8 %** du panier |
| 2 | **Marge sur la livraison** | Part gardée sur les frais de course (le reste au livreur) | 200–500 FCFA / course |
| 3 | **Abonnement vendeur « Boutique Pro »** | Mise en avant, stats avancées, badge, plus de photos | 3 000–10 000 FCFA / mois |
| 4 | **Mise en avant / publicité** | Produits/boutiques « sponsorisés » dans l'accueil & la recherche | au placement / à l'enchère |
| 5 | **Services financiers** (plus tard) | Commission mobile money, micro-avance de trésorerie vendeurs, assurance livraison | variable |

### Structure de coûts
- **Infrastructure** : Supabase / hébergement (croît avec l'usage).
- **Transactionnel** : **SMS** (2FA + notifications), **passerelle mobile money**
  (Orange / MTN / Wave / Moov ≈ 1,5–2,5 % par paiement).
- **Opérations** : support & modération, éventuel encadrement des livreurs.
- **Acquisition** : marketing local (terrain, radio, réseaux), parrainage.
- **Équipe** : développement & maintenance.

### Segments clients
- **Consommateurs** urbains (Abidjan) : proximité, prix, gain de temps.
- **Commerçants & producteurs** : nouveau canal de vente + visibilité.
- **Livreurs** indépendants (*gig economy*) : revenus flexibles.

### Stratégie de lancement (effet réseau **local**)
1. **Démarrer sur 1–2 communes denses** (ex. Cocody, Adjamé) pour atteindre vite une
   **masse critique** d'offre et de demande (un marché biface n'a de valeur que si les
   deux côtés sont présents).
2. **Amorçage à 0 commission** (gratuité) pour attirer vendeurs et acheteurs, puis
   introduction **progressive** du *take rate* une fois l'usage installé.
3. **Densifier** avant d'étendre commune par commune, ville par ville.

### Indicateurs clés (KPIs)
GMV (volume d'affaires), *take rate* effectif, commandes/jour, **rétention** vendeurs
& acheteurs, délai de livraison moyen, note moyenne, **CAC** (coût d'acquisition) vs
**LTV** (valeur vie client).

### Exemple d'*unit economics* (simplifié, 1 commande)
- Panier moyen : **8 000 FCFA** → commission 6 % = **480 FCFA** + marge livraison
  **300 FCFA** = **780 FCFA** de revenu brut.
- Coûts variables : mobile money ~2,5 % (**200 FCFA**) + SMS (**~30 FCFA**) ≈ **230 FCFA**.
- **Marge de contribution ≈ 550 FCFA / commande** → à ~**1 000 commandes/jour**, ce
  sont ~**550 000 FCFA/jour** pour couvrir coûts fixes et croissance.

> ⚠️ Modèle **prospectif** : dans l'app actuelle, paiement, SMS et KYC sont **simulés**.
> Le modèle économique décrit ici correspond à une **mise en production** future.

---

## 16. 🏗️ Schémas (architecture + base de données)

> Rendu **Mermaid** (s'affiche sur GitHub ; dans VS Code, extension *Markdown
> Preview Mermaid Support*).

### 16.1 Architecture applicative
```mermaid
flowchart TD
    subgraph App["📱 Application Flutter (Dart)"]
        UI["Presentation<br/>écrans + widgets"]
        RP["Riverpod<br/>providers / état"]
        REPO["Data<br/>repositories"]
        DOM["Domain<br/>modèles"]
        UI --> RP --> REPO --> DOM
    end
    subgraph SB["☁️ Supabase (backend managé)"]
        AUTH["Auth · JWT"]
        DB[("PostgreSQL + RLS")]
        RT["Realtime"]
        ST["Storage · buckets"]
        RPC["Fonctions RPC"]
    end
    REPO -->|"client.auth"| AUTH
    REPO -->|"client.from()"| DB
    REPO -->|"client.stream()"| RT
    REPO -->|"client.storage"| ST
    REPO -->|"client.rpc()"| RPC
    RPC --> DB
    RT -.->|"push temps réel"| RP
    UI -->|"tuiles carte"| OSM["🗺️ OpenStreetMap"]
    REPO -->|"position GPS"| GEO["📍 geolocator (OS)"]
```

### 16.2 Modèle de données (principales tables)
```mermaid
erDiagram
    profiles ||--o{ shops : "possède"
    shops ||--o{ products : "propose"
    profiles ||--o{ requests : "publie"
    requests ||--o{ offers : "reçoit"
    shops ||--o{ offers : "émet"
    profiles ||--o{ reservations : "réserve"
    products ||--o{ reservations : "porte sur"
    profiles ||--o{ orders : "achète (buyer)"
    profiles ||--o{ orders : "livre (courier)"
    shops ||--o{ orders : "vend"
    orders ||--o{ order_items : "contient"
    orders ||--o{ reviews : "évalue"
    reservations ||--o{ reviews : "évalue"
    shops ||--o{ reviews : "reçoit"
    profiles ||--o{ notifications : "reçoit"
    profiles ||--o{ activity_log : "trace"
```

---

## 17. 👑 Rôle admin — back-office complet

Le rôle **`admin`** est le **superviseur/modérateur** de la plateforme (pas un
vendeur). Il dispose d'un back-office complet (`lib/features/admin/`), accessible
avec le compte de démo **`admin@demo.ci`** (créé par `step22.sql`). À la connexion,
la coquille lui montre des **onglets dédiés** : Accueil · **Supervision** ·
**Modération** · Profil.

### Écrans
| Écran (`lib/features/admin/presentation/`) | Rôle |
|--------------------------------------------|------|
| `admin_dashboard_screen.dart` | **Supervision** : compteurs globaux (users, boutiques, produits, commandes, **GMV**, réservations, demandes), camembert commandes par statut, barres users par rôle, alerte KYC. |
| `admin_hub_screen.dart` | **Hub Modération** : porte d'entrée vers les 7 outils. |
| `admin_users_screen.dart` | Bannir / réactiver un compte (motif ; suspend aussi ses boutiques ; déconnexion du banni). |
| `admin_shops_screen.dart` / `admin_products_screen.dart` | Suspendre / masquer une boutique ou un produit (retiré du catalogue). |
| `admin_kyc_screen.dart` | File des identités `en_attente` : voir les pièces (URL signée), **Approuver / Refuser**. |
| `admin_reviews_screen.dart` | **Masquer / rétablir** un avis (exclu de la note). |
| `admin_broadcast_screen.dart` | **Annonce** : notification à tous les comptes actifs. |
| `admin_audit_screen.dart` | **Journal d'audit global** (toutes les actions + acteur). |

### Sécurité (principe)
Les écrans admin **lisent** via les selects publics et **agissent** via des **RPC
`security definer`** gardées par le helper SQL **`is_admin()`** (steps 22-24) : un
non-admin est **refusé côté serveur**, quoi qu'il tente depuis le client. Chaque
action **notifie** la personne concernée (`push_notif`) et **trace** dans
`activity_log`. Seules exceptions en policy : la lecture **globale** du journal par
l'admin (`activity_admin_select`) et la lecture du bucket privé `kyc-docs`
(`kyc_select_admin`).

### Attribution du rôle
`admin` **n'est pas sélectionnable à l'inscription** (`register_screen.dart`
l'exclut) : il s'attribue par la base (le seed `step22.sql` crée `admin@demo.ci`, ou
`update profiles set role='admin'` dans le dashboard Supabase).
