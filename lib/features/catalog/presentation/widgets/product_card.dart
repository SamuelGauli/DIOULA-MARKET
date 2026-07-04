import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../domain/catalog_product.dart';

/// Carte produit **riche** (style food app) : image (Hero), badge,
/// nom, boutique, note + avis, prix FCFA et bouton « + ».
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAdd,
    this.heroTag,
  });

  final CatalogProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  /// Tag du Hero de l'image. Par défaut `product-<id>` (transition vers la
  /// fiche). À surcharger quand un même produit peut apparaître **plusieurs
  /// fois sur le même écran** (ex. rails « En vedette » + « Meilleures notes »)
  /// pour éviter des tags de Hero en double.
  final Object? heroTag;

  bool get _isFresh => const {
        'Légumes',
        'Poissons',
        'Plats préparés',
      }.contains(product.category);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: heroTag ?? 'product-${product.id}',
                  child: ProductImage(
                    url: product.imageUrl,
                    height: 116,
                    category: product.category,
                  ),
                ),
                if (product.hasPromo)
                  Positioned(top: 8, left: 8, child: AppBadge.promo())
                else if (_isFresh)
                  Positioned(top: 8, left: 8, child: AppBadge.fresh()),
                if (!product.inStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AppBadge(
                      label: 'Épuisé',
                      color: AppColors.body,
                      icon: Icons.block,
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: _AddButton(onTap: onAdd),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.storefront,
                          size: 12, color: AppColors.body),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.body, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 15, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(
                        product.shopRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ' (${product.shopRatingCount})',
                        style:
                            const TextStyle(fontSize: 11, color: AppColors.body),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (product.hasPromo)
                    Text(
                      product.originalPriceLabel,
                      style: const TextStyle(
                          color: AppColors.body,
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          product.priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.clay,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '/${product.unit}',
                        style: const TextStyle(
                            color: AppColors.body, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton rond « + » (ajouter / réserver).
class _AddButton extends StatelessWidget {
  const _AddButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.clay,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Image produit avec placeholder coloré + repli sur une icône de catégorie.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    required this.height,
    this.category,
    this.width = double.infinity,
  });

  final String? url;
  final double height;
  final double width;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      width: width,
      color: AppColors.beige.withValues(alpha: 0.18),
      child: const Icon(Icons.image_outlined, color: AppColors.beigeDeep, size: 40),
    );

    if (url == null || url!.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: url!,
      height: height,
      width: width,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        height: height,
        width: width,
        color: AppColors.beige.withValues(alpha: 0.12),
      ),
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
