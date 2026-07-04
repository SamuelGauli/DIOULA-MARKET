import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../profile/data/profile_repository.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import 'widgets/delivery_timeline.dart';
import 'widgets/order_card.dart';
import 'widgets/slot_picker.dart';

/// Suivi d'une commande en **temps réel** : statut live + roadmap du colis +
/// action contextuelle (le livreur peut prendre / livrer depuis cet écran).
class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.order});

  final Order order;

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final slot = await showSlotPicker(context);
    if (slot == null || !context.mounted) return;
    try {
      await ref
          .read(ordersRepositoryProvider)
          .claimOrder(order.id, slot.$1, slot.$2);
      ref.invalidate(availableCoursesProvider);
      ref.invalidate(myCoursesProvider);
      ref.invalidate(myScheduleProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course acceptée 🛵 — ajoutée à ton planning.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _advance(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(ordersRepositoryProvider).advanceDelivery(order.id);
      ref.invalidate(myCoursesProvider);
      ref.invalidate(myScheduleProvider);
      ref.invalidate(myOrdersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Étape mise à jour ✅')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(orderLiveProvider(order.id));
    final row = live.value;
    final status = (row?['status'] as String?) ?? order.status;
    final courierId = (row?['courier_id'] as String?) ?? order.courierId;
    final deliveryStep = (row?['delivery_step'] as int?) ?? order.deliveryStep;

    // Créneau (live si dispo, sinon celui de la commande passée à l'écran).
    final liveStart = row?['slot_start'] == null
        ? null
        : DateTime.tryParse(row!['slot_start'] as String);
    final liveEnd = row?['slot_end'] == null
        ? null
        : DateTime.tryParse(row!['slot_end'] as String);
    final slotLabel = (liveStart != null && liveEnd != null)
        ? formatSlot(liveStart, liveEnd)
        : order.slotLabel;

    final uid = ref.watch(currentUserIdProvider);
    final role = ref.watch(currentProfileProvider).value?.role;
    final isCourier = role?.isCourier ?? false;
    final sellerView = role?.isSeller ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi de la commande')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Récap commande ----
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(order.shopName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: orderStatusColor(status).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(orderStatusLabel(status),
                          style: TextStyle(
                              color: orderStatusColor(status),
                              fontWeight: FontWeight.w600,
                              fontSize: 11)),
                    ),
                  ],
                ),
                if (order.itemsLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(order.itemsLabel,
                      style: const TextStyle(color: AppColors.body)),
                ],
                const Divider(height: 18),
                _row(Icons.person_outline, order.buyerName),
                _row(Icons.location_on_outlined,
                    order.deliveryAddress ?? 'Adresse non précisée'),
                if (slotLabel != null)
                  _row(Icons.event_outlined, slotLabel),
                _row(Icons.payments_outlined, formatFcfa(order.totalAmount)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---- Roadmap de suivi (temps réel) ----
          Row(
            children: [
              Text('Suivi du colis',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              if (live.isLoading)
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.wifi_tethering,
                    size: 16, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 14),
          DeliveryTimeline(
            status: status,
            deliveryStep: deliveryStep,
            sellerView: sellerView,
          ),

          // ---- Action livreur ----
          if (isCourier && status != 'livree' && status != 'annulee') ...[
            const SizedBox(height: 24),
            if (courierId == null)
              FilledButton.icon(
                onPressed: () => _claim(context, ref),
                icon: const Icon(Icons.two_wheeler, size: 18),
                label: const Text('Prendre la course'),
              )
            else if (courierId == uid && status == 'en_livraison')
              FilledButton.icon(
                onPressed: () => _advance(context, ref),
                icon: const Icon(Icons.navigate_next, size: 18),
                label: Text(courierNextActionLabel(deliveryStep)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.body),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
