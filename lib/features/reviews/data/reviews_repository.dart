import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/review.dart';

/// Accès aux avis (table `reviews`). Lecture publique ; on n'écrit que
/// ses propres avis. Les moyennes sont recalculées après chaque insertion.
class ReviewsRepository {
  ReviewsRepository(this._db, this._auth);
  final AppDatabase _db;
  final LocalAuthService _auth;

  Future<Database> get _database async => _db.database;

  String? get _currentUserId => _auth.currentUserId;

  /// Avis reçus par une boutique (les plus récents d'abord).
  /// Les avis **masqués** par la modération sont exclus (`is_hidden`).
  Future<List<Review>> fetchForShop(String shopId) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT r.*, p.full_name AS author_full_name, p.avatar_url AS author_avatar_url
      FROM reviews r
      LEFT JOIN profiles p ON p.id = r.author_id
      WHERE r.shop_id = ? AND COALESCE(r.is_hidden, 0) = 0
      ORDER BY r.created_at DESC
    ''', [shopId]);
    return rows.map(_reviewFromRow).toList();
  }

  /// Réservations déjà notées par l'utilisateur courant (pour masquer le bouton
  /// « Noter » une fois l'avis donné).
  Future<Set<String>> fetchMyReviewedReservationIds() async {
    final uid = _currentUserId;
    if (uid == null) return {};
    final db = await _database;
    final rows = await db.query(
      'reviews',
      columns: ['reservation_id'],
      where: 'author_id = ? AND reservation_id IS NOT NULL',
      whereArgs: [uid],
    );
    return rows
        .map((e) => e['reservation_id'] as String)
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  /// Réservations **et commandes** déjà notées : ids de commandes notées par
  /// l'utilisateur (pour masquer le bouton « Noter » une fois l'avis donné).
  Future<Set<String>> fetchMyReviewedOrderIds() async {
    final uid = _currentUserId;
    if (uid == null) return {};
    final db = await _database;
    final rows = await db.query(
      'reviews',
      columns: ['order_id'],
      where: 'author_id = ? AND order_id IS NOT NULL',
      whereArgs: [uid],
    );
    return rows
        .map((e) => e['order_id'] as String)
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  /// L'acheteur note la boutique après le retrait.
  Future<void> reviewShop({
    required String shopId,
    required String reservationId,
    required int rating,
    String? comment,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Non connecté');

    final db = await _database;
    final reviewId = 'rev_${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('reviews', {
      'id': reviewId,
      'author_id': uid,
      'shop_id': shopId,
      'reservation_id': reservationId,
      'rating': rating,
      'comment': comment,
    });

    await _db.recomputeShopRating(shopId);

    // Notifier le propriétaire de la boutique.
    final shopRows = await db.query(
      'shops',
      columns: ['owner_id', 'name'],
      where: 'id = ?',
      whereArgs: [shopId],
      limit: 1,
    );
    if (shopRows.isNotEmpty) {
      final ownerId = shopRows.first['owner_id'] as String;
      final shopName = shopRows.first['name'] as String;
      await _db.pushNotif(
        ownerId,
        'review',
        'Nouvel avis sur $shopName',
        'Un client a laissé $rating étoile(s) sur votre boutique.',
      );
    }
  }

  /// L'acheteur note la boutique après la **livraison d'une commande**
  /// (commentaire optionnel). Recalcul de la note.
  Future<void> reviewShopForOrder({
    required String shopId,
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Non connecté');

    final db = await _database;
    final reviewId = 'rev_${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('reviews', {
      'id': reviewId,
      'author_id': uid,
      'shop_id': shopId,
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
    });

    await _db.recomputeShopRating(shopId);

    final shopRows = await db.query(
      'shops',
      columns: ['owner_id', 'name'],
      where: 'id = ?',
      whereArgs: [shopId],
      limit: 1,
    );
    if (shopRows.isNotEmpty) {
      final ownerId = shopRows.first['owner_id'] as String;
      final shopName = shopRows.first['name'] as String;
      await _db.pushNotif(
        ownerId,
        'review',
        'Nouvel avis sur $shopName',
        'Un client a laissé $rating étoile(s) sur votre boutique.',
      );
    }
  }

  /// Le vendeur note l'acheteur après le retrait.
  Future<void> reviewBuyer({
    required String buyerId,
    required String reservationId,
    required int rating,
    String? comment,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Non connecté');

    final db = await _database;
    final reviewId = 'rev_${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('reviews', {
      'id': reviewId,
      'author_id': uid,
      'target_id': buyerId,
      'reservation_id': reservationId,
      'rating': rating,
      'comment': comment,
    });

    await _db.recomputeProfileRating(buyerId);

    await _db.pushNotif(
      buyerId,
      'review',
      'Nouvel avis sur votre profil',
      'Un vendeur vous a laissé $rating étoile(s).',
    );
  }

  // ── Helpers ──

  static Review _reviewFromRow(Map<String, dynamic> row) {
    return Review(
      id: row['id'] as String,
      authorId: row['author_id'] as String,
      rating: (row['rating'] as num).toInt(),
      shopId: row['shop_id'] as String?,
      targetId: row['target_id'] as String?,
      reservationId: row['reservation_id'] as String?,
      comment: row['comment'] as String?,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.tryParse(row['created_at'] as String),
      authorName: row['author_full_name'] as String? ?? 'Client',
      authorAvatar: row['author_avatar_url'] as String?,
      isHidden: (row['is_hidden'] as int? ?? 0) == 1,
    );
  }
}

// ── Providers ──

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(
    ref.watch(databaseProvider),
    ref.watch(localAuthProvider),
  );
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
