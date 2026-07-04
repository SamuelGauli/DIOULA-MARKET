import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/guest_gate.dart';
import '../../auth/presentation/guest_provider.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../reviews/data/reviews_repository.dart';
import '../../reviews/presentation/rating_sheet.dart';
import '../domain/order.dart';
import '../data/orders_repository.dart';
import 'widgets/order_card.dart';

/// « Mes commandes » (acheteur) : suivi du statut de livraison.
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  /// Note la boutique après la livraison de la commande (commentaire optionnel).
  Future<void> _rateShop(BuildContext context, WidgetRef ref, Order o) async {
    final ok = await showRatingSheet(
      context,
      title: 'Noter ${o.shopName}',
      subtitle: 'Ton avis (et un commentaire) après la livraison.',
      onSubmit: (rating, comment) =>
          ref.read(reviewsRepositoryProvider).reviewShopForOrder(
                shopId: o.shopId,
                orderId: o.id,
                rating: rating,
                comment: comment,
              ),
    );
    if (ok != true) return;
    ref.invalidate(myReviewedOrderIdsProvider);
    ref.invalidate(shopReviewsProvider(o.shopId));
    ref.invalidate(allShopsProvider); // rafraîchit la note moyenne affichée
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci pour ton avis ⭐')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes commandes')),
        body: const GuestGate(
          icon: Icons.receipt_long,
          title: 'Mes commandes',
          message:
              'Crée un compte pour passer commande et suivre tes livraisons.',
        ),
      );
    }

    final async = ref.watch(myOrdersProvider);
    final reviewed = ref.watch(myReviewedOrderIdsProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async {
          ref.invalidate(myOrdersProvider);
          ref.invalidate(myReviewedOrderIdsProvider);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.receipt_long,
                    title: 'Aucune commande',
                    message:
                        'Accepte une offre sur une demande pour créer ta première commande.',
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OrderCard(
                      order: o,
                      onTap: () =>
                          context.push(AppRoutes.orderTracking, extra: o),
                    ),
                    // Commande livrée → noter la boutique (+ commentaire).
                    if (o.isDelivered) ...[
                      const SizedBox(height: 6),
                      if (reviewed.contains(o.id))
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: AppColors.success),
                            SizedBox(width: 6),
                            Text('Boutique notée',
                                style: TextStyle(color: AppColors.body)),
                          ],
                        )
                      else
                        FilledButton.tonalIcon(
                          onPressed: () => _rateShop(context, ref, o),
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text('Noter la boutique'),
                        ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
