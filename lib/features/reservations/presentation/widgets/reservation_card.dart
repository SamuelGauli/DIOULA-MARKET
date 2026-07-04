import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../../domain/reservation.dart';

Color reservationStatusColor(String status) {
  switch (status) {
    case 'payee':
    case 'confirmee':
      return AppColors.info;
    case 'terminee':
      return AppColors.success;
    case 'annulee':
      return AppColors.body;
    case 'expiree':
      return AppColors.danger;
    default:
      return AppColors.warning; // en_attente
  }
}

String reservationDeadlineLabel(DateTime? deadline) {
  if (deadline == null) return 'sans échéance';
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) return 'échéance dépassée';
  if (diff.inHours >= 24) return 'retrait dans ${diff.inDays} j';
  if (diff.inHours >= 1) return 'retrait dans ${diff.inHours} h';
  return 'retrait dans ${diff.inMinutes} min';
}

/// Carte d'une réservation (image, montants, statut) + zone d'action.
class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.reservation, this.action});

  final Reservation reservation;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final color = reservationStatusColor(r.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ProductImage(
                    url: r.productImage,
                    height: 64,
                    width: 64,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('${r.shopName} · ${formatQty(r.quantity)} ${r.productUnit}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.body, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 13, color: AppColors.body),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                                r.slotLabel ??
                                    reservationDeadlineLabel(r.deadline),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.body, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(r.statusEnum.label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
              ],
            ),
            const Divider(height: 20),
            _amountRow('Total', formatFcfa(r.totalAmount)),
            _amountRow('Acompte payé', formatFcfa(r.depositAmount)),
            if (r.status == 'payee')
              _amountRow('Solde au retrait', formatFcfa(r.balance),
                  muted: true),
            if (r.refundAmount > 0)
              _amountRow('Remboursé', formatFcfa(r.refundAmount),
                  color: AppColors.success),
            if (action != null) ...[
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: action!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, String value,
      {bool muted = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: muted ? AppColors.body : null, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color ?? (muted ? AppColors.body : null))),
        ],
      ),
    );
  }
}
