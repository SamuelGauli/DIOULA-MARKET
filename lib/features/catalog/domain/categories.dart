import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Catégorie du catalogue : libellé (= valeur stockée en base), icône et
/// couleur d'accent. Les libellés correspondent au seed SQL.
class MarketCategory {
  const MarketCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// Liste ordonnée des catégories affichées (chips + filtres de recherche).
const kCategories = <MarketCategory>[
  MarketCategory('Céréales & graines', Icons.grass, AppColors.ocre),
  MarketCategory('Légumes', Icons.local_florist, AppColors.success),
  MarketCategory('Plats préparés', Icons.restaurant, AppColors.clay),
  MarketCategory('Poissons', Icons.set_meal, AppColors.info),
  MarketCategory('Féculents', Icons.rice_bowl, AppColors.beigeDeep),
  MarketCategory('Épicerie', Icons.shopping_basket, AppColors.warning),
];

/// Icône associée à une catégorie (fallback générique si inconnue).
IconData iconForCategory(String? category) {
  for (final c in kCategories) {
    if (c.label == category) return c.icon;
  }
  return Icons.shopping_bag_outlined;
}

/// Couleur associée à une catégorie (fallback terracotta).
Color colorForCategory(String? category) {
  for (final c in kCategories) {
    if (c.label == category) return c.color;
  }
  return AppColors.clay;
}
