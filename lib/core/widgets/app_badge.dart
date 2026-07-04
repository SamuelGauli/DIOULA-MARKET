import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Badge « pilule » coloré : Promo, Halal, Frais, Nouveau, etc.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.color = AppColors.clay,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  /// Raccourcis prêts à l'emploi pour les cartes produits.
  factory AppBadge.promo() =>
      const AppBadge(label: 'Promo', color: AppColors.promo, icon: Icons.local_offer);
  factory AppBadge.halal() =>
      const AppBadge(label: 'Halal', color: AppColors.halal, icon: Icons.verified);
  factory AppBadge.fresh() =>
      const AppBadge(label: 'Frais', color: AppColors.fresh, icon: Icons.eco);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cloche de notifications avec pastille de compteur (en-tête d'accueil).
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.count = 0, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
