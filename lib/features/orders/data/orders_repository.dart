import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/order.dart';

/// Accès aux commandes + livraison (table `orders`).
/// Utilise SQLite local au lieu de Supabase.
class OrdersRepository {
  OrdersRepository(this._db, this._auth);
  final AppDatabase _db;
  final LocalAuthService _auth;

  Future<Database> get _database async => _db.database;

  String? get _currentUserId => _auth.currentUserId;

  // ── Requêtes ──

  /// Pool des courses disponibles (non assignées) — visible par les livreurs.
  Future<List<Order>> fetchAvailable() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT o.*, s.name AS shop_name, p.full_name AS buyer_name
      FROM orders o
      LEFT JOIN shops s ON s.id = o.shop_id
      LEFT JOIN profiles p ON p.id = o.buyer_id
      WHERE o.courier_id IS NULL
        AND o.status IN ('en_cours', 'preparee')
      ORDER BY o.created_at ASC
    ''');
    return _hydrateOrders(db, rows);
  }

  /// Les courses du livreur connecté (en cours + historique).
  Future<List<Order>> fetchMyCourses() async {
    final uid = _currentUserId;
    if (uid == null) return [];
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT o.*, s.name AS shop_name, p.full_name AS buyer_name
      FROM orders o
      LEFT JOIN shops s ON s.id = o.shop_id
      LEFT JOIN profiles p ON p.id = o.buyer_id
      WHERE o.courier_id = ?
      ORDER BY o.created_at DESC
    ''', [uid]);
    return _hydrateOrders(db, rows);
  }

  /// Les commandes de l'acheteur connecté (suivi).
  Future<List<Order>> fetchMyOrders() async {
    final uid = _currentUserId;
    if (uid == null) return [];
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT o.*, s.name AS shop_name, p.full_name AS buyer_name
      FROM orders o
      LEFT JOIN shops s ON s.id = o.shop_id
      LEFT JOIN profiles p ON p.id = o.buyer_id
      WHERE o.buyer_id = ?
      ORDER BY o.created_at DESC
    ''', [uid]);
    return _hydrateOrders(db, rows);
  }

  /// Les commandes reçues par une boutique (suivi côté vendeur).
  Future<List<Order>> fetchForShop(String shopId) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT o.*, s.name AS shop_name, p.full_name AS buyer_name
      FROM orders o
      LEFT JOIN shops s ON s.id = o.shop_id
      LEFT JOIN profiles p ON p.id = o.buyer_id
      WHERE o.shop_id = ?
      ORDER BY o.created_at DESC
    ''', [shopId]);
    return _hydrateOrders(db, rows);
  }

  /// Planning du livreur : ses livraisons à venir (en cours), triées par créneau.
  Future<List<Order>> fetchMySchedule() async {
    final uid = _currentUserId;
    if (uid == null) return [];
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT o.*, s.name AS shop_name, p.full_name AS buyer_name
      FROM orders o
      LEFT JOIN shops s ON s.id = o.shop_id
      LEFT JOIN profiles p ON p.id = o.buyer_id
      WHERE o.courier_id = ? AND o.status = 'en_livraison'
      ORDER BY o.slot_start ASC
    ''', [uid]);
    return _hydrateOrders(db, rows);
  }

  // ── Actions (remplacent les RPCs) ──

  /// Le livreur prend la course sur un créneau.
  Future<void> claimOrder(
      String id, DateTime slotStart, DateTime slotEnd) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Non connecté');

    final db = await _database;
    await db.update(
      'orders',
      {
        'courier_id': uid,
        'status': 'en_livraison',
        'slot_start': slotStart.toIso8601String(),
        'slot_end': slotEnd.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Charger l'ordre pour la notif et le log.
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final order = rows.first;
      final shopId = order['shop_id'] as String;
      final buyerId = order['buyer_id'] as String;
      final shopName = (await db.query('shops',
              where: 'id = ?', whereArgs: [shopId], limit: 1))
          .firstOrNull?['name'] as String? ??
          'Boutique';

      await _db.pushNotif(buyerId, 'order', 'Commande prise en charge',
          'Votre commande chez $shopName est en cours de livraison.');
      await _db.logActivity(uid, 'claim_order',
          'Livreur a pris en charge la commande $id (créneau $slotStart → $slotEnd)',
          entity: 'order',
          entityId: id);
    }

    _notifyOrderUpdate(id);
  }

  /// Marquer une commande comme livrée.
  Future<void> markDelivered(String id) async {
    final db = await _database;
    await db.update(
      'orders',
      {
        'status': 'livree',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final rows = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final order = rows.first;
      final buyerId = order['buyer_id'] as String;
      final courierId = order['courier_id'] as String?;
      final shopId = order['shop_id'] as String;
      final shopName = (await db.query('shops',
              where: 'id = ?', whereArgs: [shopId], limit: 1))
          .firstOrNull?['name'] as String? ??
          'Boutique';

      await _db.pushNotif(buyerId, 'order', 'Commande livrée',
          'Votre commande chez $shopName a été livrée.');
      if (courierId != null) {
        await _db.logActivity(courierId, 'mark_delivered',
            'Commande $id marquée comme livrée',
            entity: 'order', entityId: id);
      }
    }

    _notifyOrderUpdate(id);
  }

  /// Le livreur fait avancer la livraison d'une étape (récupéré → … → livré).
  Future<void> advanceDelivery(String id) async {
    final db = await _database;
    final rows =
        await db.query('orders', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return;

    final currentStep = (rows.first['delivery_step'] as int?) ?? 0;
    final newStep = currentStep + 1;

    if (newStep >= 5) {
      await db.update(
        'orders',
        {
          'delivery_step': newStep,
          'status': 'livree',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      final buyerId = rows.first['buyer_id'] as String;
      final shopId = rows.first['shop_id'] as String;
      final shopName = (await db.query('shops',
              where: 'id = ?', whereArgs: [shopId], limit: 1))
          .firstOrNull?['name'] as String? ??
          'Boutique';
      await _db.pushNotif(buyerId, 'order', 'Commande livrée',
          'Votre commande chez $shopName a été livrée (étape $newStep).');
    } else {
      await db.update(
        'orders',
        {
          'delivery_step': newStep,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    final courierId = rows.first['courier_id'] as String?;
    if (courierId != null) {
      await _db.logActivity(courierId, 'advance_delivery',
          'Étape de livraison avancée à $newStep pour la commande $id',
          entity: 'order',
          entityId: id);
    }

    _notifyOrderUpdate(id);
  }

  // ── Realtime simulé (StreamController) ──

  /// Controllers par order ID pour le suivi en temps réel.
  final _liveControllers = <String, StreamController<Map<String, dynamic>?>>{};

  /// Souscrire aux mises à jour temps réel d'une commande.
  Stream<Map<String, dynamic>?> watchOrder(String orderId) {
    _liveControllers.putIfAbsent(
      orderId,
      () => StreamController<Map<String,dynamic>?>.broadcast(),
    );
    // Émettre l'état actuel immédiatement.
    _emitOrderState(orderId);
    return _liveControllers[orderId]!.stream;
  }

  /// Appelé après chaque mutation pour pousser la nouvelle valeur.
  void _notifyOrderUpdate(String orderId) {
    _emitOrderState(orderId);
  }

  Future<void> _emitOrderState(String orderId) async {
    final db = await _database;
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
    final controller = _liveControllers[orderId];
    if (controller != null && !controller.isClosed) {
      controller.add(rows.isEmpty ? null : rows.first);
    }
  }

  void disposeOrderStream(String orderId) {
    final controller = _liveControllers.remove(orderId);
    controller?.close();
  }

  // ── Helpers ──

  Future<List<Order>> _hydrateOrders(
      Database db, List<Map<String, dynamic>> rows) async {
    final orders = <Order>[];
    for (final row in rows) {
      final orderId = row['id'] as String;
      final items = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      final itemsLabel = items.map((item) {
        final qty = (item['quantity'] as num?) ?? 1;
        return '${item['product_name']} ×$qty';
      }).join(', ');

      orders.add(Order(
        id: row['id'] as String,
        buyerId: row['buyer_id'] as String,
        shopId: row['shop_id'] as String,
        courierId: row['courier_id'] as String?,
        status: row['status'] as String? ?? 'en_cours',
        totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0,
        deliveryAddress: row['delivery_address'] as String?,
        createdAt: row['created_at'] == null
            ? null
            : DateTime.tryParse(row['created_at'] as String),
        slotStart: row['slot_start'] == null
            ? null
            : DateTime.tryParse(row['slot_start'] as String),
        slotEnd: row['slot_end'] == null
            ? null
            : DateTime.tryParse(row['slot_end'] as String),
        deliveryStep: (row['delivery_step'] as num?)?.toInt() ?? 0,
        shopName: row['shop_name'] as String? ?? 'Boutique',
        buyerName: row['buyer_name'] as String? ?? 'Client',
        itemsLabel: itemsLabel,
      ));
    }
    return orders;
  }
}

// ── Providers ──

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(
    ref.watch(databaseProvider),
    ref.watch(localAuthProvider),
  );
});

final availableCoursesProvider =
    FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).fetchAvailable();
});

final myCoursesProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).fetchMyCourses();
});

final myScheduleProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).fetchMySchedule();
});

final myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).fetchMyOrders();
});

final shopOrdersProvider =
    FutureProvider.autoDispose.family<List<Order>, String>((ref, shopId) {
  return ref.watch(ordersRepositoryProvider).fetchForShop(shopId);
});

/// Ligne d'une commande en temps réel (suivi du colis).
/// Remplace le Realtime Supabase par un StreamController-based stream.
final orderLiveProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, orderId) {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.watchOrder(orderId);
});
