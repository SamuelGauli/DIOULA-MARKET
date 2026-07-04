import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/guest_gate.dart';
import '../../auth/presentation/guest_provider.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';
import '../../profile/data/profile_repository.dart';
import '../../reservations/data/reservations_repository.dart';
import '../../reviews/presentation/widgets/star_rating.dart';
import '../../shops/data/shop_repository.dart';
import '../../shops/domain/shop.dart';
import 'widgets/dashboard_charts.dart';

/// Tableau de bord commerçant : synthèse de SA boutique (produits, stock,
/// réservations, chiffre d'affaires simulé). Agrège les données déjà
/// disponibles (aucune nouvelle table). Réservé aux vendeurs.
class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tableau de bord')),
        body: const GuestGate(
          icon: Icons.bar_chart,
          title: 'Réservé aux membres',
          message:
              'Connecte-toi avec un compte Commerçant ou Producteur pour suivre ton activité.',
        ),
      );
    }

    final role = ref.watch(currentProfileProvider).value?.role;
    if (role != null && !role.isSeller) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tableau de bord')),
        body: const EmptyState(
          icon: Icons.bar_chart,
          title: 'Réservé aux vendeurs',
          message:
              'Seuls les comptes Commerçant ou Producteur disposent d\'un tableau de bord.',
        ),
      );
    }

    final shopAsync = ref.watch(myShopProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (shop) {
          if (shop == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Pas encore de boutique',
                      message:
                          'Crée ta boutique pour voir tes statistiques ici.',
                    ),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.shopForm),
                      icon: const Icon(Icons.add_business),
                      label: const Text('Créer ma boutique'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _DashboardBody(shop: shop);
        },
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByShopProvider(shop.id));
    final reservationsAsync = ref.watch(shopReservationsProvider(shop.id));

    if (productsAsync.hasError) {
      return Center(child: Text('Erreur : ${productsAsync.error}'));
    }
    if (reservationsAsync.hasError) {
      return Center(child: Text('Erreur : ${reservationsAsync.error}'));
    }
    final products = productsAsync.value;
    final reservations = reservationsAsync.value;
    if (products == null || reservations == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // ---- Agrégats ----
    final lowStock =
        products.where((p) => p.stock < kLowStockThreshold).toList();
    final active = reservations.where((r) => r.status == 'payee').toList();
    final done = reservations.where((r) => r.status == 'terminee').toList();
    final lost = reservations
        .where((r) => r.status == 'expiree' || r.status == 'annulee')
        .toList();

    final caConfirmed =
        done.fold<double>(0, (s, r) => s + r.totalAmount);
    final acomptesPending =
        active.fold<double>(0, (s, r) => s + r.depositAmount);
    final refunded =
        reservations.fold<double>(0, (s, r) => s + r.refundAmount);

    return RefreshIndicator(
      color: AppColors.clay,
      onRefresh: () async {
        ref.invalidate(productsByShopProvider(shop.id));
        ref.invalidate(shopReservationsProvider(shop.id));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ShopHeader(shop: shop),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.history),
            icon: const Icon(Icons.history),
            label: const Text('Historique de mon activité'),
          ),
          const SizedBox(height: 18),

          // ---- Aperçu (4 tuiles) ----
          const _SectionTitle('Aperçu'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Produits',
                  value: '${products.length}',
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.warning_amber_rounded,
                  label: 'Stock bas',
                  value: '${lowStock.length}',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.event_available_outlined,
                  label: 'Réservations actives',
                  value: '${active.length}',
                  color: AppColors.clay,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_outline,
                  label: 'Retraits confirmés',
                  value: '${done.length}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),

          // ---- Réservations par statut (camembert) ----
          const SizedBox(height: 18),
          const _SectionTitle('Réservations par statut'),
          const SizedBox(height: 10),
          AppCard(
            child: ReservationsPieChart(
              active: active.length,
              done: done.length,
              lost: lost.length,
            ),
          ),

          // ---- Chiffre d'affaires (simulé) ----
          const SizedBox(height: 18),
          const _SectionTitle('Chiffre d\'affaires (simulé)'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                RevenueBarChart(
                  caConfirmed: caConfirmed,
                  acomptes: acomptesPending,
                  refunded: refunded,
                ),
                const SizedBox(height: 12),
                _MoneyRow('CA confirmé (retraits)', formatFcfa(caConfirmed),
                    color: AppColors.success),
                const Divider(height: 18),
                _MoneyRow('Acomptes en attente', formatFcfa(acomptesPending),
                    color: AppColors.clay),
                const Divider(height: 18),
                _MoneyRow('Remboursé (annulé/expiré)', formatFcfa(refunded),
                    muted: true),
              ],
            ),
          ),

          // ---- Stock bas ----
          const SizedBox(height: 18),
          const _SectionTitle('Stock bas'),
          const SizedBox(height: 10),
          if (lowStock.isEmpty)
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 10),
                  Expanded(child: Text('Tout est bien approvisionné.')),
                ],
              ),
            )
          else
            ...lowStock.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LowStockRow(
                    product: p,
                    onTap: () => context.push(AppRoutes.shopProducts),
                  ),
                )),

          // ---- Raccourcis ----
          const SizedBox(height: 18),
          if (lost.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${lost.length} réservation(s) annulée(s)/expirée(s).',
                style: const TextStyle(color: AppColors.body, fontSize: 12),
              ),
            ),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.shopProducts),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Gérer mes produits'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                context.push(AppRoutes.shopReservations, extra: shop.id),
            icon: const Icon(Icons.event_note_outlined),
            label: const Text('Réservations reçues'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                context.push(AppRoutes.shopOrders, extra: shop.id),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Commandes & livraisons'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  En-tête boutique
// ---------------------------------------------------------------------------
class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.clay,
            child: Text(
              shop.name.characters.first.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (shop.commune != null)
                  Text(shop.commune!,
                      style: const TextStyle(
                          color: AppColors.body, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StarsDisplay(rating: shop.ratingAvg, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      shop.ratingCount > 0
                          ? '${shop.ratingAvg.toStringAsFixed(1)} (${shop.ratingCount})'
                          : 'Pas encore d\'avis',
                      style:
                          const TextStyle(color: AppColors.body, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Tuile statistique
// ---------------------------------------------------------------------------
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.body, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.value, {this.color, this.muted = false});
  final String label;
  final String value;
  final Color? color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: muted ? AppColors.body : null, fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: color ?? (muted ? AppColors.body : null))),
      ],
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.product, this.onTap});
  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text('${formatQty(product.stock)} ${product.unit}',
              style: const TextStyle(
                  color: AppColors.warning, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
