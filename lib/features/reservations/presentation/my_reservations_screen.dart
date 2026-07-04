import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/guest_gate.dart';
import '../../auth/presentation/guest_provider.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../reviews/data/reviews_repository.dart';
import '../../reviews/presentation/rating_sheet.dart';
import '../data/reservations_repository.dart';
import '../domain/reservation.dart';
import 'widgets/reservation_card.dart';

/// « Mes réservations » (acheteur) : liste + annulation (jusqu'à 12 h avant).
class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(reservationsRepositoryProvider).cancelReservation(id);
      ref.invalidate(myReservationsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation annulée — acompte remboursé.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes réservations')),
        body: const GuestGate(
          icon: Icons.event_available,
          title: 'Réservations',
          message: 'Crée un compte pour réserver un produit avec acompte.',
        ),
      );
    }

    final async = ref.watch(myReservationsProvider);
    final reviewed =
        ref.watch(myReviewedReservationIdsProvider).value ?? const <String>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Mes réservations')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async {
          ref.invalidate(myReservationsProvider);
          ref.invalidate(myReviewedReservationIdsProvider);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.event_available,
                    title: 'Aucune réservation',
                    message:
                        'Réserve un produit depuis sa fiche pour le retrouver ici.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final r = list[i];
                return ReservationCard(
                  reservation: r,
                  action: _actionFor(context, ref, r, reviewed),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _rateShop(
      BuildContext context, WidgetRef ref, Reservation r) async {
    final ok = await showRatingSheet(
      context,
      title: 'Noter ${r.shopName}',
      subtitle: 'Ton avis sur cette boutique après le retrait.',
      onSubmit: (rating, comment) =>
          ref.read(reviewsRepositoryProvider).reviewShop(
                shopId: r.shopId,
                reservationId: r.id,
                rating: rating,
                comment: comment,
              ),
    );
    if (ok != true) return;
    ref.invalidate(myReviewedReservationIdsProvider);
    ref.invalidate(shopReviewsProvider(r.shopId));
    ref.invalidate(allShopsProvider); // rafraîchit la note moyenne affichée
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci pour ton avis ⭐')),
    );
  }

  Widget? _actionFor(
      BuildContext context, WidgetRef ref, Reservation r, Set<String> reviewed) {
    // Réservation terminée → proposer de noter la boutique.
    if (r.status == 'terminee') {
      if (reviewed.contains(r.id)) {
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 16, color: AppColors.success),
            SizedBox(width: 6),
            Text('Boutique notée', style: TextStyle(color: AppColors.body)),
          ],
        );
      }
      return FilledButton.tonalIcon(
        onPressed: () => _rateShop(context, ref, r),
        icon: const Icon(Icons.star_rounded, size: 18),
        label: const Text('Noter la boutique'),
      );
    }

    if (!r.isActive) return null;
    if (r.cancellable) {
      return OutlinedButton.icon(
        onPressed: () => _cancel(context, ref, r.id),
        icon: const Icon(Icons.close, size: 18),
        label: const Text('Annuler'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
      );
    }
    return const Text(
      'Annulation fermée (moins de 12 h avant l\'échéance).',
      style: TextStyle(color: AppColors.body, fontSize: 12),
    );
  }
}
