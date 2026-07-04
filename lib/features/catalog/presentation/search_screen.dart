import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/widgets/guest_invite_sheet.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog_product.dart';
import '../domain/categories.dart';
import 'widgets/product_card.dart';

/// Recherche de produits (autorisée aux visiteurs) : champ + filtres par
/// catégorie + grille de résultats.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<CatalogProduct> _filter(List<CatalogProduct> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      final okCat = _category == null || p.category == _category;
      final okQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.shopName.toLowerCase().contains(q) ||
          (p.category?.toLowerCase().contains(q) ?? false);
      return okCat && okQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Produit, boutique, catégorie…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          // Filtres catégories
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kCategories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return CategoryChip(
                    icon: Icons.apps,
                    label: 'Tout',
                    color: AppColors.clay,
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  );
                }
                final c = kCategories[i - 1];
                return CategoryChip(
                  icon: c.icon,
                  label: c.label,
                  color: c.color,
                  selected: _category == c.label,
                  onTap: () => setState(() => _category = c.label),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (all) {
                final results = _filter(all);
                if (results.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'Aucun résultat',
                    message: 'Essaie un autre mot-clé ou une autre catégorie.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.66,
                  ),
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final p = results[i];
                    return ProductCard(
                      product: p,
                      onTap: () =>
                          context.push(AppRoutes.productDetail, extra: p),
                      onAdd: () => requireAccount(context, ref,
                          action: 'réserver ce produit'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
