import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/review.dart';

/// Accès aux avis (table `reviews`). Lecture publique (RLS) ; on n'écrit que
/// ses propres avis. Les moyennes (`rating_avg`/`rating_count`) sont recalculées
/// côté SQL par un trigger (`step8.sql`).
class ReviewsRepository {
  ReviewsRepository(this._client);
  final SupabaseClient _client;

  // Jointure vers le profil auteur. reviews a 2 FK vers profiles
  // (author_id, target_id) → on désambiguïse par la colonne `author_id`.
  static const _select =
      '*, author:profiles!author_id(full_name, avatar_url)';

  /// Avis reçus par une boutique (les plus récents d'abord).
  /// Les avis **masqués** par la modération sont exclus (`is_hidden`).
  Future<List<Review>> fetchForShop(String shopId) async {
    final data = await _client
        .from('reviews')
        .select(_select)
        .eq('shop_id', shopId)
        .eq('is_hidden', false)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Review.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Réservations déjà notées par l'utilisateur courant (pour masquer le bouton
  /// « Noter » une fois l'avis donné).
  Future<Set<String>> fetchMyReviewedReservationIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final data = await _client
        .from('reviews')
        .select('reservation_id')
        .eq('author_id', uid)
        .not('reservation_id', 'is', null);
    return (data as List)
        .map((e) => (e as Map<String, dynamic>)['reservation_id'] as String)
        .toSet();
  }

  /// L'acheteur note la boutique après le retrait.
  Future<void> reviewShop({
    required String shopId,
    required String reservationId,
    required int rating,
    String? comment,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('reviews').insert({
      'author_id': uid,
      'shop_id': shopId,
      'reservation_id': reservationId,
      'rating': rating,
      'comment': comment,
    });
  }

  /// Réservations **et commandes** déjà notées : ids de commandes notées par
  /// l'utilisateur (pour masquer le bouton « Noter » une fois l'avis donné).
  Future<Set<String>> fetchMyReviewedOrderIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final data = await _client
        .from('reviews')
        .select('order_id')
        .eq('author_id', uid)
        .not('order_id', 'is', null);
    return (data as List)
        .map((e) => (e as Map<String, dynamic>)['order_id'] as String)
        .toSet();
  }

  /// L'acheteur note la boutique après la **livraison d'une commande**
  /// (commentaire optionnel). Recalcul de la note via le trigger de step8.
  Future<void> reviewShopForOrder({
    required String shopId,
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('reviews').insert({
      'author_id': uid,
      'shop_id': shopId,
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
    });
  }

  /// Le vendeur note l'acheteur après le retrait.
  Future<void> reviewBuyer({
    required String buyerId,
    required String reservationId,
    required int rating,
    String? comment,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('reviews').insert({
      'author_id': uid,
      'target_id': buyerId,
      'reservation_id': reservationId,
      'rating': rating,
      'comment': comment,
    });
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(supabaseProvider));
});

/// Avis d'une boutique (fiche boutique).
final shopReviewsProvider = FutureProvider.autoDispose
    .family<List<Review>, String>((ref, shopId) {
  return ref.watch(reviewsRepositoryProvider).fetchForShop(shopId);
});

/// Ensemble des réservations déjà notées par l'utilisateur courant.
final myReviewedReservationIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) {
  return ref.watch(reviewsRepositoryProvider).fetchMyReviewedReservationIds();
});

/// Ensemble des commandes déjà notées par l'utilisateur courant.
final myReviewedOrderIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) {
  return ref.watch(reviewsRepositoryProvider).fetchMyReviewedOrderIds();
});
