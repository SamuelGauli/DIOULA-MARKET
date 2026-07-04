import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shops/domain/shop.dart';
import '../../domain/categories.dart';

/// Carte boutique horizontale : bandeau dégradé + logo, nom, commune,
/// note et catégorie. Utilisée dans « Près de vous » / « Producteurs ».
class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, this.onTap});

  final Shop shop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = colorForCategory(shop.category);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandeau coloré + pastille logo.
            Container(
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.9), accent],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(iconForCategory(shop.category),
                  color: Colors.white, size: 30),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.body),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          shop.commune ?? 'Côte d\'Ivoire',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.body, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(
                        shop.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(' (${shop.ratingCount})',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.body)),
                      const Spacer(),
                      if (shop.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            shop.category!,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accent),
                          ),
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
