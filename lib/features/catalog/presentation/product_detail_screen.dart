import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/widgets/guest_invite_sheet.dart';
import '../domain/catalog_product.dart';
import 'widgets/product_card.dart';

/// Fiche détail d'un produit (image Hero, infos boutique, actions).
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.product});

  final CatalogProduct product;

  void _reserve(BuildContext context, WidgetRef ref) {
    if (!requireAccount(context, ref, action: 'réserver ce produit')) return;
    if (!product.inStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit épuisé.')),
      );
      return;
    }
    context.push(AppRoutes.reserve, extra: product);
  }

  void _request(BuildContext context, WidgetRef ref) {
    if (!requireAccount(context, ref, action: 'publier une demande')) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demande instantanée — bientôt ⚡')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.beige,
            leading: const _CircleBack(),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${product.id}',
                child: ProductImage(
                  url: product.imageUrl,
                  height: 280,
                  category: product.category,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _StockChip(inStock: product.inStock),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.priceLabel,
                        style: const TextStyle(
                          color: AppColors.clay,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      Text(' / ${product.unit}',
                          style: const TextStyle(color: AppColors.body)),
                      if (product.hasPromo) ...[
                        const SizedBox(width: 10),
                        Text(
                          product.originalPriceLabel,
                          style: const TextStyle(
                              color: AppColors.body,
                              decoration: TextDecoration.lineThrough),
                        ),
                        const SizedBox(width: 8),
                        AppBadge.promo(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Carte boutique (tappable).
                  Card(
                    child: ListTile(
                      onTap: () =>
                          context.push(AppRoutes.shopView, extra: product.shopId),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.clay.withValues(alpha: 0.15),
                        child: const Icon(Icons.storefront,
                            color: AppColors.clay),
                      ),
                      title: Text(product.shopName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(product.shopCommune ?? 'Côte d\'Ivoire'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 18, color: AppColors.warning),
                          Text(product.shopRating.toStringAsFixed(1)),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Description',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    product.description?.isNotEmpty == true
                        ? product.description!
                        : 'Aucune description fournie pour ce produit.',
                    style: const TextStyle(color: AppColors.body, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 18, color: AppColors.body),
                      const SizedBox(width: 6),
                      Text(
                        'Stock : ${formatQty(product.stock)} ${product.unit}',
                        style: const TextStyle(color: AppColors.body),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _request(context, ref),
                  icon: const Icon(Icons.bolt),
                  label: const Text('Demander'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Réserver',
                  icon: Icons.event_available,
                  gradient: true,
                  onPressed: () => _reserve(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.inStock});
  final bool inStock;
  @override
  Widget build(BuildContext context) {
    final color = inStock ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        inStock ? 'En stock' : 'Épuisé',
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
