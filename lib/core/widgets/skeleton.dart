import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

/// Bloc « squelette » animé (effet *shimmer*) pour les états de chargement,
/// à composer pour préfigurer les listes/cartes pendant le fetch.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? AppColors.surfaceDark : const Color(0xFFEDE4D6);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: dark ? Colors.white10 : Colors.white,
        );
  }
}

/// Squelette d'une carte produit (vignette + 2 lignes de texte).
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Skeleton(height: 110, radius: 16),
        SizedBox(height: 10),
        Skeleton(width: 120, height: 12),
        SizedBox(height: 6),
        Skeleton(width: 80, height: 12),
      ],
    );
  }
}
