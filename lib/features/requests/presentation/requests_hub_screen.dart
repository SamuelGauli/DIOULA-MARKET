import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/guest_gate.dart';
import '../../auth/presentation/guest_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../data/requests_repository.dart';
import '../domain/market_request.dart';
import 'widgets/request_bits.dart';

/// Hub des demandes instantanées, **adapté au rôle** :
/// - consommateur → ses demandes (+ bouton « Nouvelle demande ») ;
/// - vendeur (commerçant/producteur) → demandes ouvertes à pourvoir.
class RequestsHubScreen extends ConsumerWidget {
  const RequestsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Demandes')),
        body: const GuestGate(
          icon: Icons.bolt,
          title: 'Demandes instantanées',
          message:
              'Crée un compte pour publier une demande ou y répondre en direct.',
        ),
      );
    }

    final role =
        ref.watch(currentProfileProvider).value?.role ?? UserRole.consommateur;

    // Consommateur : ses demandes. Vendeur : demandes à pourvoir.
    if (role.isConsumer) return const _MyRequestsView();
    if (role.isSeller) return const _OpenRequestsView();

    // Livreur / admin : non concernés par les demandes de produits.
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes')),
      body: const EmptyState(
        icon: Icons.bolt_outlined,
        title: 'Non concerné',
        message:
            'Les demandes instantanées relient consommateurs et vendeurs. '
            'Ton rôle n\'intervient pas ici.',
      ),
    );
  }
}

// ----------------------- VUE CONSOMMATEUR -----------------------
class _MyRequestsView extends ConsumerWidget {
  const _MyRequestsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRequestsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes demandes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.requestNew),
        backgroundColor: AppColors.clay,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle demande'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (requests) {
          if (requests.isEmpty) {
            return EmptyState(
              icon: Icons.bolt,
              title: 'Aucune demande',
              message:
                  'Publie ton premier besoin : les vendeurs proches répondront en direct.',
              actionLabel: 'Nouvelle demande',
              onAction: () => context.push(AppRoutes.requestNew),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _RequestTile(request: requests[i]),
          );
        },
      ),
    );
  }
}

// ----------------------- VUE VENDEUR -----------------------
class _OpenRequestsView extends ConsumerWidget {
  const _OpenRequestsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(openRequestsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes près de vous')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (requests) {
          if (requests.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Aucune demande ouverte',
              message:
                  'Les nouvelles demandes des consommateurs apparaîtront ici en direct.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) =>
                _RequestTile(request: requests[i], merchantView: true),
          );
        },
      ),
    );
  }
}

// ----------------------- CARTE DEMANDE -----------------------
class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, this.merchantView = false});
  final MarketRequest request;
  final bool merchantView;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () =>
          context.push(AppRoutes.requestDetail, extra: request.id),
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
                child: const Icon(Icons.bolt, color: AppColors.clay),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  request.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              RequestStatusChip(request: request),
            ],
          ),
          const SizedBox(height: 10),
          Text(requestSubtitle(request),
              style: const TextStyle(color: AppColors.body, fontSize: 12.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.body),
              const SizedBox(width: 4),
              Text(expiresLabel(request.expiresAt),
                  style: const TextStyle(color: AppColors.body, fontSize: 12)),
              const Spacer(),
              Text(
                merchantView ? 'Répondre →' : 'Voir les offres →',
                style: const TextStyle(
                    color: AppColors.clay,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
