import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/reservation.dart';

class ReservationsRepository {
  ReservationsRepository(this._db, this._auth);
  final AppDatabase _db;
  final LocalAuthService _auth;

  static String _uuid() {
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${(10000 + (DateTime.now().microsecond % 90000))}';
  }

  String? get _userId => _auth.currentUserId;

  Future<List<Reservation>> fetchMine() async {
    final uid = _userId;
    if (uid == null) return [];
    final database = await _db.database;
    final rows = await database.rawQuery('''
      SELECT r.*,
             p.name   AS product_name,
             p.image_url AS product_image_url,
             p.unit   AS product_unit,
             s.name   AS shop_name
      FROM reservations r
      LEFT JOIN products p ON p.id = r.product_id
      LEFT JOIN shops   s ON s.id = r.shop_id
      WHERE r.buyer_id = ?
      ORDER BY r.created_at DESC
    ''', [uid]);
    return rows.map((e) => Reservation.fromMap(e)).toList();
  }

  Future<List<Reservation>> fetchForShop(String shopId) async {
    final database = await _db.database;
    final rows = await database.rawQuery('''
      SELECT r.*,
             p.name   AS product_name,
             p.image_url AS product_image_url,
             p.unit   AS product_unit,
             s.name   AS shop_name
      FROM reservations r
      LEFT JOIN products p ON p.id = r.product_id
      LEFT JOIN shops   s ON s.id = r.shop_id
      WHERE r.shop_id = ?
      ORDER BY r.created_at DESC
    ''', [shopId]);
    return rows.map((e) => Reservation.fromMap(e)).toList();
  }

  /// Réserve sur un créneau + paie l'acompte + décrémente le stock (transaction atomique).
  /// Renvoie l'ID de la réservation créée.
  Future<String?> reserveProduct({
    required String productId,
    required double quantity,
    required DateTime slotStart,
    required DateTime slotEnd,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    final database = await _db.database;
    String? reservationId;
    String? productName;
    String? shopOwnerId;

    await database.transaction((txn) async {
      final productRows = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (productRows.isEmpty) return;
      final product = productRows.first;
      final stock = (product['stock'] as num?)?.toDouble() ?? 0;
      if (stock < quantity) return;

      final unitPrice =
          (product['promo_price'] as num?)?.toDouble() ??
          (product['price'] as num?)?.toDouble() ??
          0;
      final totalAmount = unitPrice * quantity;
      final depositAmount = totalAmount * 0.3;
      final shopId = product['shop_id'] as String;

      reservationId = 'res_${DateTime.now().microsecondsSinceEpoch}';
      final now = DateTime.now().toIso8601String();
      await txn.insert('reservations', {
        'id': reservationId,
        'product_id': productId,
        'shop_id': shopId,
        'buyer_id': uid,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_amount': totalAmount,
        'deposit_amount': depositAmount,
        'deposit_paid': 1,
        'refund_amount': 0,
        'status': 'payee',
        'deadline': slotEnd.toIso8601String(),
        'slot_start': slotStart.toIso8601String(),
        'slot_end': slotEnd.toIso8601String(),
        'created_at': now,
        'updated_at': now,
      });

      await txn.rawUpdate(
        'UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?',
        [quantity, now, productId],
      );

      await txn.insert('payments', {
        'id': _uuid(),
        'payer_id': uid,
        'reservation_id': reservationId,
        'amount': depositAmount,
        'kind': 'acompte',
        'status': 'simule',
        'created_at': now,
      });

      productName = product['name'] as String?;

      final shopRows = await txn.query(
        'shops',
        where: 'id = ?',
        whereArgs: [shopId],
        limit: 1,
      );
      if (shopRows.isNotEmpty) {
        shopOwnerId = shopRows.first['owner_id'] as String?;
      }
    });

    if (reservationId != null) {
      final name = productName ?? 'produit';
      await _db.pushNotif(uid, 'reservation', 'Réservation créée',
          'Votre réservation pour $name a été confirmée.');
      if (shopOwnerId != null && shopOwnerId != uid) {
        await _db.pushNotif(
          shopOwnerId!,
          'reservation',
          'Nouvelle réservation',
          'Un client a réservé $name.',
        );
      }
      await _db.logActivity(uid, 'reserve_product',
          'Réservation $reservationId pour ${quantity}x $name',
          entity: 'reservation', entityId: reservationId);
    }

    return reservationId;
  }

  /// Termine une réservation : met le statut à 'terminee' + crée le paiement du solde.
  Future<void> completeReservation(String id) async {
    final database = await _db.database;
    String? buyerId;
    String? shopOwnerId;

    await database.transaction((txn) async {
      final rows = await txn.query(
        'reservations',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final r = rows.first;
      final status = r['status'] as String?;
      if (status != 'payee') return;

      final totalAmount = (r['total_amount'] as num?)?.toDouble() ?? 0;
      final depositAmount = (r['deposit_amount'] as num?)?.toDouble() ?? 0;
      final balance = totalAmount - depositAmount;
      final now = DateTime.now().toIso8601String();
      buyerId = r['buyer_id'] as String;

      await txn.rawUpdate(
        'UPDATE reservations SET status = ?, updated_at = ? WHERE id = ?',
        ['terminee', now, id],
      );

      if (balance > 0) {
        await txn.insert('payments', {
          'id': _uuid(),
          'payer_id': buyerId,
          'reservation_id': id,
          'amount': balance,
          'kind': 'solde',
          'status': 'simule',
          'created_at': now,
        });
      }

      final shopId = r['shop_id'] as String;
      final shopRows = await txn.query(
        'shops',
        where: 'id = ?',
        whereArgs: [shopId],
        limit: 1,
      );
      if (shopRows.isNotEmpty) {
        shopOwnerId = shopRows.first['owner_id'] as String?;
      }
    });

    if (buyerId != null) {
      await _db.pushNotif(buyerId!, 'reservation', 'Réservation terminée',
          'Votre réservation a été marquée comme terminée.');
      if (shopOwnerId != null) {
        await _db.pushNotif(shopOwnerId!, 'reservation', 'Réservation terminée',
            'La réservation $id est terminée.');
      }
      await _db.logActivity(buyerId!, 'complete_reservation',
          'Réservation $id terminée',
          entity: 'reservation', entityId: id);
    }
  }

  /// Annule une réservation : rembourse l'acompte + ré-incrémente le stock.
  Future<void> cancelReservation(String id) async {
    final database = await _db.database;
    String? buyerId;
    String? shopOwnerId;

    await database.transaction((txn) async {
      final rows = await txn.query(
        'reservations',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final r = rows.first;
      final status = r['status'] as String?;
      if (status != 'payee') return;

      final depositAmount = (r['deposit_amount'] as num?)?.toDouble() ?? 0;
      final quantity = (r['quantity'] as num?)?.toDouble() ?? 0;
      final productId = r['product_id'] as String;
      final now = DateTime.now().toIso8601String();
      buyerId = r['buyer_id'] as String;

      await txn.rawUpdate(
        'UPDATE reservations SET status = ?, refund_amount = ?, updated_at = ? WHERE id = ?',
        ['annulee', depositAmount, now, id],
      );

      await txn.rawUpdate(
        'UPDATE products SET stock = stock + ?, updated_at = ? WHERE id = ?',
        [quantity, now, productId],
      );

      if (depositAmount > 0) {
        await txn.insert('payments', {
          'id': _uuid(),
          'payer_id': buyerId,
          'reservation_id': id,
          'amount': depositAmount,
          'kind': 'remboursement',
          'status': 'simule',
          'created_at': now,
        });
      }

      final shopId = r['shop_id'] as String;
      final shopRows = await txn.query(
        'shops',
        where: 'id = ?',
        whereArgs: [shopId],
        limit: 1,
      );
      if (shopRows.isNotEmpty) {
        shopOwnerId = shopRows.first['owner_id'] as String?;
      }
    });

    if (buyerId != null) {
      await _db.pushNotif(buyerId!, 'reservation', 'Réservation annulée',
          'Votre réservation a été annulée. L\'acompte a été remboursé.');
      if (shopOwnerId != null) {
        await _db.pushNotif(shopOwnerId!, 'reservation', 'Réservation annulée',
            'La réservation $id a été annulée.');
      }
      await _db.logActivity(buyerId!, 'cancel_reservation',
          'Réservation $id annulée',
          entity: 'reservation', entityId: id);
    }
  }

  /// Passe en « expirée » les réservations échues. Rembourse partiellement + ré-incrémente le stock.
  Future<int> expireReservations() async {
    final database = await _db.database;
    int count = 0;

    final notifs = <({String userId, String title, String body})>[];
    final activities = <({String actorId, String detail, String? entityId})>[];

    await database.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final expiredRows = await txn.query(
        'reservations',
        where: "status = 'payee' AND slot_end < ?",
        whereArgs: [now],
      );

      for (final r in expiredRows) {
        final id = r['id'] as String;
        final depositAmount =
            (r['deposit_amount'] as num?)?.toDouble() ?? 0;
        final quantity = (r['quantity'] as num?)?.toDouble() ?? 0;
        final productId = r['product_id'] as String;
        final buyerId = r['buyer_id'] as String;

        final partialRefund = depositAmount * 0.5;

        await txn.rawUpdate(
          'UPDATE reservations SET status = ?, refund_amount = ?, updated_at = ? WHERE id = ?',
          ['expiree', partialRefund, now, id],
        );

        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ?, updated_at = ? WHERE id = ?',
          [quantity, now, productId],
        );

        if (partialRefund > 0) {
          await txn.insert('payments', {
            'id': _uuid(),
            'payer_id': buyerId,
            'reservation_id': id,
            'amount': partialRefund,
            'kind': 'remboursement_partiel',
            'status': 'simule',
            'created_at': now,
          });
        }

        notifs.add((
          userId: buyerId,
          title: 'Réservation expirée',
          body: 'Votre réservation a expiré. Un remboursement partiel a été effectué.',
        ));

        final shopRows = await txn.query(
          'shops',
          where: 'id = ?',
          whereArgs: [r['shop_id']],
          limit: 1,
        );
        if (shopRows.isNotEmpty) {
          final ownerId = shopRows.first['owner_id'] as String?;
          if (ownerId != null) {
            notifs.add((
              userId: ownerId,
              title: 'Réservation expirée',
              body: 'La réservation $id a expiré.',
            ));
          }
        }

        activities.add((
          actorId: buyerId,
          detail: 'Réservation $id expirée',
          entityId: id,
        ));

        count++;
      }
    });

    for (final n in notifs) {
      await _db.pushNotif(n.userId, 'reservation', n.title, n.body);
    }
    for (final a in activities) {
      await _db.logActivity(a.actorId, 'expire_reservation', a.detail,
          entity: 'reservation', entityId: a.entityId);
    }

    return count;
  }
}

// ── Providers ──

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(localAuthProvider);
  return ReservationsRepository(db, auth);
});

/// Mes réservations (acheteur) — expire d'abord les échues, puis charge.
final myReservationsProvider =
    FutureProvider.autoDispose<List<Reservation>>((ref) async {
  final repo = ref.watch(reservationsRepositoryProvider);
  await repo.expireReservations();
  return repo.fetchMine();
});

/// Réservations reçues sur une boutique (vendeur).
final shopReservationsProvider = FutureProvider.autoDispose
    .family<List<Reservation>, String>((ref, shopId) async {
  final repo = ref.watch(reservationsRepositoryProvider);
  await repo.expireReservations();
  return repo.fetchForShop(shopId);
});
