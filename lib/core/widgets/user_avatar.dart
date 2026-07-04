import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Avatar circulaire robuste : affiche la photo réseau si disponible, sinon
/// (absence **ou échec de chargement/décodage**) un repli sur l'initiale du
/// nom — sans laisser remonter d'exception (cf. images pravatar sur le web).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 22,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String name;
  final String? url;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.clay.withValues(alpha: 0.15);
    final fg = foregroundColor ?? AppColors.clay;
    final initial =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    final letter = CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        initial,
        style: TextStyle(
            color: fg, fontWeight: FontWeight.bold, fontSize: radius * 0.8),
      ),
    );

    if (url == null || url!.isEmpty) return letter;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, __) => letter,
        errorWidget: (_, __, ___) => letter,
      ),
    );
  }
}
