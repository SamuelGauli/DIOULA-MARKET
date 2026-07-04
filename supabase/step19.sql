-- =====================================================================
--  DIOULA MARKET — COMMIT B : VENTE EN GROS / EN DÉTAIL
--  Le vendeur classe chaque produit : vente au détail, en gros, ou les
--  deux. Le consommateur filtre le flux (chips « En détail » / « En gros »).
--  À exécuter dans : SQL Editor (après les précédents). Rejouable.
-- =====================================================================

-- ---------------------------------------------------------------------
--  A) Colonne sale_mode (+ classement initial des produits existants)
--     Le bloc n'est joué qu'au 1er passage : il respecte ensuite les
--     réglages manuels du vendeur (rejouable sans rien réécraser).
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'products'
      and column_name = 'sale_mode'
  ) then
    alter table public.products
      add column sale_mode text not null default 'detail';

    -- Auto-classement d'après l'unité : un produit vendu au sac / carton /
    -- régime est typiquement de la vente en gros ; le reste, du détail.
    update public.products
       set sale_mode = 'gros'
     where unit in ('sac', 'carton', 'régime');
  end if;
end $$;

-- ---------------------------------------------------------------------
--  B) Valeurs autorisées
-- ---------------------------------------------------------------------
alter table public.products drop constraint if exists products_sale_mode_check;
alter table public.products add constraint products_sale_mode_check
  check (sale_mode in ('detail', 'gros', 'les_deux'));

-- =====================================================================
--  FIN step19.sql
-- =====================================================================
