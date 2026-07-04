import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import 'widgets/delivery_timeline.dart';
import 'widgets/order_card.dart';
import 'widgets/slot_picker.dart';

/// Espace livreur : **pool de courses disponibles** + **mes courses**.
/// Un livreur prend une course (→ en livraison) puis la marque livrée.
class CourierCoursesScreen extends StatelessWidget {
  const CourierCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Courses'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Disponibles'),
              Tab(text: 'Mes courses'),
              Tab(text: 'Planning'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_AvailableTab(), _MyCoursesTab(), _PlanningTab()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Onglet « Disponibles » (pool)
// ---------------------------------------------------------------------------
class _AvailableTab extends ConsumerWidget {
  const _AvailableTab();

  Future<void> _claim(BuildContext context, WidgetRef ref, String id) async {
    final slot = await showSlotPicker(context);
    if (slot == null || !context.mounted) return;
    try {
      await ref
          .read(ordersRepositoryProvider)
          .claimOrder(id, slot.$1, slot.$2);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(availableCoursesProvider);
    return RefreshIndicator(
      color: AppColors.clay,
      onRefresh: () async => ref.invalidate(availableCoursesProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: 'Aucune course disponible',
                  message:
                      'Les commandes à livrer apparaîtront ici dès qu\'elles sont prêtes.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final o = orders[i];
              return OrderCard(
                order: o,
                showBuyer: true,
                onTap: () =>
                    context.push(AppRoutes.orderTracking, extra: o),
                action: FilledButton.icon(
                  onPressed: () => _claim(context, ref, o.id),
                  icon: const Icon(Icons.two_wheeler, size: 18),
                  label: const Text('Prendre la course'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Onglet « Mes courses »
// ---------------------------------------------------------------------------
class _MyCoursesTab extends ConsumerWidget {
  const _MyCoursesTab();

  Future<void> _advance(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(ordersRepositoryProvider).advanceDelivery(id);
      ref.invalidate(myCoursesProvider);
      ref.invalidate(myScheduleProvider);
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
    final async = ref.watch(myCoursesProvider);
    return RefreshIndicator(
      color: AppColors.clay,
      onRefresh: () async => ref.invalidate(myCoursesProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.two_wheeler,
                  title: 'Aucune course en cours',
                  message:
                      'Prends une course dans l\'onglet « Disponibles » pour commencer.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final o = orders[i];
              return OrderCard(
                order: o,
                showBuyer: true,
                onTap: () =>
                    context.push(AppRoutes.orderTracking, extra: o),
                action: o.isDelivering
                    ? FilledButton.icon(
                        onPressed: () => _advance(context, ref, o.id),
                        icon: const Icon(Icons.navigate_next, size: 18),
                        label: Text(courierNextActionLabel(o.deliveryStep)),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: AppColors.success),
                          SizedBox(width: 6),
                          Text('Livrée',
                              style: TextStyle(color: AppColors.body)),
                        ],
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Onglet « Planning » (agenda du livreur, groupé par jour)
// ---------------------------------------------------------------------------
class _PlanningTab extends ConsumerWidget {
  const _PlanningTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myScheduleProvider);
    return RefreshIndicator(
      color: AppColors.clay,
      onRefresh: () async => ref.invalidate(myScheduleProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: 'Planning vide',
                  message:
                      'Prends une course : son créneau apparaîtra ici, jour par jour.',
                ),
              ],
            );
          }
          // Regroupe par jour (créneau).
          final groups = <String, List<Order>>{};
          for (final o in orders) {
            final key =
                o.slotStart == null ? 'Sans créneau' : formatDay(o.slotStart!);
            groups.putIfAbsent(key, () => []).add(o);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(entry.key,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                for (final o in entry.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PlanningRow(order: o),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PlanningRow extends StatelessWidget {
  const _PlanningRow({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final time = (order.slotStart != null && order.slotEnd != null)
        ? formatSlotTime(order.slotStart!, order.slotEnd!)
        : '—';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push(AppRoutes.orderTracking, extra: order),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.clay.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(time,
              style: const TextStyle(
                  color: AppColors.clay,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
        title:
            Text(order.shopName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(order.deliveryAddress ?? 'Adresse non précisée',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('À faire : ${courierNextActionLabel(order.deliveryStep)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.clay,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
