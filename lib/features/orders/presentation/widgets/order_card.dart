import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../domain/order.dart';

Color orderStatusColor(String status) {
  switch (status) {
    case 'preparee':
      return AppColors.info;
    case 'en_livraison':
      return AppColors.clay;
    case 'livree':
      return AppColors.success;
    case 'annulee':
      return AppColors.body;
    default:
      return AppColors.warning; // en_cours (en attente de livreur)
  }
}

String orderStatusLabel(String status) {
  switch (status) {
    case 'preparee':
      return 'Préparée';
    case 'en_livraison':
      return 'En livraison';
    case 'livree':
      return 'Livrée';
    case 'annulee':
      return 'Annulée';
    default:
      return 'En attente de livreur';
  }
}

/// Carte d'une commande (boutique, articles, adresse, total, statut) + action.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.action,
    this.showBuyer = false,
    this.onTap,
  });

  final Order order;
  final Widget? action;

  /// Affiche le nom de l'acheteur (vue livreur).
  final bool showBuyer;

  /// Ouvre le suivi de la commande (optionnel).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final color = orderStatusColor(o.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.clay.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.clay),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (o.itemsLabel.isNotEmpty)
                        Text(o.itemsLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.body, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(orderStatusLabel(o.status),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
              ],
            ),
            const Divider(height: 18),
            if (showBuyer)
              _line(Icons.person_outline, o.buyerName),
            _line(Icons.location_on_outlined,
                o.deliveryAddress ?? 'Adresse non précisée'),
            if (o.slotLabel != null)
              _line(Icons.event_outlined, o.slotLabel!),
            _line(Icons.payments_outlined, formatFcfa(o.totalAmount)),
            if (action != null) ...[
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: action!),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.body),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
