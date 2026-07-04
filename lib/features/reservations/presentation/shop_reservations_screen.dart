import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../reviews/data/reviews_repository.dart';
import '../../reviews/presentation/rating_sheet.dart';
import '../data/reservations_repository.dart';
import '../domain/reservation.dart';
import 'widgets/reservation_card.dart';

/// « Réservations reçues » (vendeur) : confirme le retrait (solde réglé).
class ShopReservationsScreen extends ConsumerWidget {
  const ShopReservationsScreen({super.key, required this.shopId});
  final String shopId;

  Future<void> _complete(
      BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(reservationsRepositoryProvider).completeReservation(id);
      ref.invalidate(shopReservationsProvider(shopId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retrait confirmé ✅ Réservation terminée.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _rateBuyer(
      BuildContext context, WidgetRef ref, Reservation r) async {
    final ok = await showRatingSheet(
      context,
      title: 'Noter le client',
      subtitle: 'Ton avis sur cet acheteur après le retrait.',
      onSubmit: (rating, comment) =>
          ref.read(reviewsRepositoryProvider).reviewBuyer(
                buyerId: r.buyerId,
                reservationId: r.id,
                rating: rating,
                comment: comment,
              ),
    );
    if (ok != true) return;
    ref.invalidate(myReviewedReservationIdsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci, le client a été noté ⭐')),
    );
  }

  Widget? _actionFor(
      BuildContext context, WidgetRef ref, Reservation r, Set<String> reviewed) {
    if (r.isActive) {
      return FilledButton.icon(
        onPressed: () => _complete(context, ref, r.id),
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Confirmer le retrait'),
      );
    }
    if (r.status == 'terminee') {
      if (reviewed.contains(r.id)) {
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 16, color: AppColors.success),
            SizedBox(width: 6),
            Text('Client noté', style: TextStyle(color: AppColors.body)),
          ],
        );
      }
      return FilledButton.tonalIcon(
        onPressed: () => _rateBuyer(context, ref, r),
        icon: const Icon(Icons.star_rounded, size: 18),
        label: const Text('Noter le client'),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopReservationsProvider(shopId));
    final reviewed =
        ref.watch(myReviewedReservationIdsProvider).value ?? const <String>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Réservations reçues')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async {
          ref.invalidate(shopReservationsProvider(shopId));
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
                    icon: Icons.event_note_outlined,
                    title: 'Aucune réservation',
                    message:
                        'Les réservations de tes clients apparaîtront ici.',
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
}
