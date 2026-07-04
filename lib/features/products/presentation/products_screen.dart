import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../shops/data/shop_repository.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';
import 'product_controller.dart';

/// Liste des produits de MA boutique, avec ajout / édition / suppression.
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(myShopProvider);

    return shopAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Erreur : $e'))),
      data: (shop) {
        if (shop == null) {
          return const Scaffold(
            body: Center(child: Text('Crée d\'abord ta boutique.')),
          );
        }

        final productsAsync = ref.watch(productsByShopProvider(shop.id));

        return Scaffold(
          appBar: AppBar(title: const Text('Mes produits')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(
              AppRoutes.productForm,
              // On passe (shopId, produit-à-éditer=null) pour une création.
              extra: (shop.id, null),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
          body: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (products) {
              if (products.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucun produit pour le moment.\nAppuie sur « Ajouter ».',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) =>
                    _ProductTile(products[i], shop.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile(this.product, this.shopId);
  final Product product;
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStock = product.stock <= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Vignette produit (image si fournie, sinon icône).
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 64,
                width: 64,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const _Placeholder(),
                        placeholder: (_, __) => const _Placeholder(),
                      )
                    : const _Placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _SaleTag(product.saleMode),
                      if (product.category != null &&
                          product.category!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(product.category!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.body, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${product.effectivePrice.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                            color: AppColors.clay,
                            fontWeight: FontWeight.bold),
                      ),
                      if (product.hasPromo) ...[
                        const SizedBox(width: 4),
                        Text(
                          product.price.toStringAsFixed(0),
                          style: const TextStyle(
                              color: AppColors.body,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough),
                        ),
                      ],
                      Text(' / ${product.unit}',
                          style: const TextStyle(color: AppColors.body)),
                      const SizedBox(width: 8),
                      _StockBadge(stock: product.stock, low: lowStock),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: Icon(Icons.local_offer_outlined,
                  color: product.hasPromo ? AppColors.ocre : null),
              tooltip: 'Promo',
              onPressed: () => _setPromo(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () => context.push(
                AppRoutes.productForm,
                extra: (shopId, product),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'Supprimer',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text('« ${product.name} » sera définitivement supprimé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(productControllerProvider.notifier).delete(product);
    }
  }

  /// Met (ou retire) rapidement un prix promo (anti-gaspillage).
  Future<void> _setPromo(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
        text: product.promoPrice == null
            ? ''
            : product.promoPrice!.toStringAsFixed(0));
    final res = await showDialog<({bool remove, double? price})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prix promo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Prix normal : ${product.price.toStringAsFixed(0)} FCFA / ${product.unit}',
                style: const TextStyle(color: AppColors.body)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Prix promo (FCFA)',
                  prefixIcon: Icon(Icons.local_offer_outlined)),
            ),
          ],
        ),
        actions: [
          if (product.hasPromo)
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, (remove: true, price: null)),
              child: const Text('Retirer',
                  style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(
                ctx,
                (
                  remove: false,
                  price: double.tryParse(controller.text.replaceAll(',', '.'))
                )),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (res == null) return;

    double? newPromo;
    if (res.remove) {
      newPromo = null;
    } else {
      final v = res.price;
      if (v == null || v <= 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prix promo invalide.')));
        }
        return;
      }
      if (v >= product.price) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('La promo doit être inférieure au prix normal.')));
        }
        return;
      }
      newPromo = v;
    }

    try {
      await ref.read(productRepositoryProvider).setPromo(product.id, newPromo);
      ref.invalidate(productsByShopProvider(shopId));
      ref.invalidate(allProductsProvider); // catalogue côté client
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newPromo == null
              ? 'Promotion retirée.'
              : 'Produit mis en promo ✅')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }
}

/// Vignette par défaut quand le produit n'a pas d'image.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.green.withValues(alpha: 0.12),
      child: const Icon(Icons.shopping_basket_outlined,
          color: AppColors.green),
    );
  }
}

/// Petit badge du mode de vente (détail / gros / les deux).
class _SaleTag extends StatelessWidget {
  const _SaleTag(this.mode);
  final String mode;

  @override
  Widget build(BuildContext context) {
    final color = mode == 'gros'
        ? AppColors.ocre
        : (mode == 'les_deux' ? AppColors.info : AppColors.clay);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        saleModeLabel(mode),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Petit badge d'état du stock (disponible / épuisé).
class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock, required this.low});
  final double stock;
  final bool low;

  @override
  Widget build(BuildContext context) {
    final color = low ? AppColors.danger : AppColors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        low ? 'Épuisé' : 'Stock ${stock.toStringAsFixed(0)}',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
