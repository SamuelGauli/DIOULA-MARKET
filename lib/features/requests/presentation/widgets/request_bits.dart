import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../domain/market_request.dart';

/// Couleur associée au statut d'une demande.
Color requestStatusColor(String status) {
  switch (status) {
    case 'ouverte':
      return AppColors.success;
    case 'pourvue':
      return AppColors.info;
    case 'expiree':
      return AppColors.body;
    case 'annulee':
      return AppColors.danger;
    default:
      return AppColors.body;
  }
}

/// Petite pastille de statut (Ouverte / Pourvue / …).
class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({super.key, required this.request});
  final MarketRequest request;

  @override
  Widget build(BuildContext context) {
    final color = requestStatusColor(request.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        request.statusEnum.label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

/// Libellé « expire dans … » (ou « expirée »).
String expiresLabel(DateTime? expiresAt) {
  if (expiresAt == null) return 'sans échéance';
  final diff = expiresAt.difference(DateTime.now());
  if (diff.isNegative) return 'échéance dépassée';
  if (diff.inHours >= 24) return 'expire dans ${diff.inDays} j';
  if (diff.inHours >= 1) return 'expire dans ${diff.inHours} h';
  return 'expire dans ${diff.inMinutes} min';
}

/// Ligne résumé quantité + rayon d'une demande.
String requestSubtitle(MarketRequest r) {
  final qty = r.quantity == null
      ? ''
      : '${formatQty(r.quantity!)} ${r.unit ?? ''} · ';
  return '$qty${r.productName} · rayon ${formatQty(r.radiusKm)} km';
}
