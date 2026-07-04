import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/orders_repository.dart';
import 'widgets/order_card.dart';

/// « Commandes de la boutique » (vendeur) : suivi des livraisons de ses ventes.
class ShopOrdersScreen extends ConsumerWidget {
  const ShopOrdersScreen({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopOrdersProvider(shopId));
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes de la boutique')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async => ref.invalidate(shopOrdersProvider(shopId)),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Aucune commande',
                    message:
                        'Les commandes de tes clients (offres acceptées) apparaîtront ici.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => OrderCard(
                order: orders[i],
                showBuyer: true,
                onTap: () => context.push(AppRoutes.orderTracking,
                    extra: orders[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}
