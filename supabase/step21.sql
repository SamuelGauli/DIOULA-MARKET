-- =====================================================================
--  DIOULA MARKET — COMMIT G : NOTATION + COMMENTAIRE APRÈS UNE COMMANDE
--  L'acheteur note la boutique (avec commentaire optionnel) après la
--  livraison d'une COMMANDE (en plus de la notation des réservations).
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
--  Réutilise le trigger de recalcul des moyennes de step8.
-- =====================================================================

-- Lier un avis à une commande + anti-doublon (1 avis par auteur & commande).
alter table public.reviews
  add column if not exists order_id uuid
  references public.orders(id) on delete set null;

create unique index if not exists uq_reviews_author_order
  on public.reviews(author_id, order_id)
  where order_id is not null;

-- =====================================================================
--  FIN step21.sql
-- =====================================================================
