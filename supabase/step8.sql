-- =====================================================================
--  DIOULA MARKET — ÉTAPE 8 : NOTATION CROISÉE (avis 5 étoiles)
--  Acheteur note la BOUTIQUE ; vendeur note l'ACHETEUR, après un retrait
--  confirmé (réservation « terminée »). Recalcul auto des moyennes.
--  À exécuter dans : SQL Editor (après schema/rls/seed/step5/step6).
--  Rejouable. Dépend de `push_notif` (défini dans step6.sql).
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Lier un avis à une réservation (notation après retrait) + anti-doublon
-- ---------------------------------------------------------------------
alter table public.reviews
  add column if not exists reservation_id uuid
  references public.reservations(id) on delete set null;

-- Un même auteur ne note qu'une seule fois une réservation donnée
-- (l'acheteur et le vendeur ont des author_id différents → les deux peuvent
--  noter la même réservation).
create unique index if not exists uq_reviews_author_reservation
  on public.reviews(author_id, reservation_id)
  where reservation_id is not null;

-- ---------------------------------------------------------------------
--  B) Recalcul des moyennes (boutique + profil) à chaque avis
-- ---------------------------------------------------------------------
create or replace function public.recompute_shop_rating(p_shop uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_shop is null then return; end if;
  update public.shops s set
    rating_avg = coalesce(
      (select round(avg(rating)::numeric, 2)
         from public.reviews where shop_id = p_shop), 0),
    rating_count = (select count(*) from public.reviews where shop_id = p_shop)
  where s.id = p_shop;
end; $$;

create or replace function public.recompute_profile_rating(p_profile uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_profile is null then return; end if;
  update public.profiles p set
    rating_avg = coalesce(
      (select round(avg(rating)::numeric, 2)
         from public.reviews where target_id = p_profile), 0),
    rating_count = (select count(*) from public.reviews where target_id = p_profile)
  where p.id = p_profile;
end; $$;

-- Trigger : recalcule les cibles impactées (insert / update / delete)
-- et notifie le destinataire de l'avis (réutilise push_notif de step6).
create or replace function public.trg_review_changed()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    perform public.recompute_shop_rating(old.shop_id);
    perform public.recompute_profile_rating(old.target_id);
    return old;
  elsif tg_op = 'UPDATE' then
    perform public.recompute_shop_rating(new.shop_id);
    perform public.recompute_shop_rating(old.shop_id);
    perform public.recompute_profile_rating(new.target_id);
    perform public.recompute_profile_rating(old.target_id);
    return new;
  else -- INSERT
    perform public.recompute_shop_rating(new.shop_id);
    perform public.recompute_profile_rating(new.target_id);
    if new.shop_id is not null then
      perform public.push_notif(
        (select owner_id from public.shops where id = new.shop_id),
        'avis', 'Nouvel avis ⭐',
        'Un client a noté ta boutique ' || new.rating || '/5.');
    end if;
    if new.target_id is not null then
      perform public.push_notif(new.target_id, 'avis', 'Nouvel avis ⭐',
        'Un vendeur t''a noté ' || new.rating || '/5.');
    end if;
    return new;
  end if;
end; $$;

drop trigger if exists trg_reviews_recompute on public.reviews;
create trigger trg_reviews_recompute
  after insert or update or delete on public.reviews
  for each row execute function public.trg_review_changed();

-- ---------------------------------------------------------------------
--  C) Recalcul initial (avis déjà présents : seed, etc.)
-- ---------------------------------------------------------------------
do $$
declare r record;
begin
  for r in select distinct shop_id from public.reviews where shop_id is not null
  loop
    perform public.recompute_shop_rating(r.shop_id);
  end loop;
  for r in select distinct target_id from public.reviews where target_id is not null
  loop
    perform public.recompute_profile_rating(r.target_id);
  end loop;
end $$;

-- =====================================================================
--  FIN step8.sql
-- =====================================================================
