import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/market_request.dart';
import '../domain/offer.dart';

/// Accès aux **demandes instantanées** et aux **offres**, avec flux temps réel
/// via SQLite local + StreamController.
class RequestsRepository {
  RequestsRepository(this._db, this._auth);
  final AppDatabase _db;
  final LocalAuthService _auth;

  String? get _uid => _auth.currentUserId;

  // ── Stream controllers ──

  final _myRequestsControllers =
      <String, StreamController<List<MarketRequest>>>{};
  final _openRequestsController =
      StreamController<List<MarketRequest>>.broadcast();
  final _offersControllers =
      <String, StreamController<List<Offer>>>{};

  /// Récupère ou crée un stream controller pour les demandes d'un consommateur.
  StreamController<List<MarketRequest>> _myRequestsCtrl(String consumerId) {
    return _myRequestsControllers.putIfAbsent(
      consumerId,
      () => StreamController<List<MarketRequest>>.broadcast(),
    );
  }

  /// Récupère ou crée un stream controller pour les offres d'une demande.
  StreamController<List<Offer>> _offersCtrl(String requestId) {
    return _offersControllers.putIfAbsent(
      requestId,
      () => StreamController<List<Offer>>.broadcast(),
    );
  }

  /// Re-demande les données et pousse sur le stream.
  Future<void> _refreshMyRequests(String consumerId) async {
    final db = await _db.database;
    final rows = await db.query(
      'requests',
      where: 'consumer_id = ?',
      whereArgs: [consumerId],
      orderBy: 'created_at ASC',
    );
    final requests = rows.map(MarketRequest.fromMap).toList();
    _myRequestsCtrl(consumerId).add(requests);
  }

  Future<void> _refreshOpenRequests() async {
    final db = await _db.database;
    final rows = await db.query(
      'requests',
      where: 'status = ?',
      whereArgs: ['ouverte'],
      orderBy: 'created_at ASC',
    );
    _openRequestsController.add(rows.map(MarketRequest.fromMap).toList());
  }

  Future<void> _refreshOffers(String requestId) async {
    final db = await _db.database;
    final rows = await db.query(
      'offers',
      where: 'request_id = ?',
      whereArgs: [requestId],
      orderBy: 'created_at ASC',
    );
    _offersCtrl(requestId).add(rows.map(Offer.fromMap).toList());
  }

  // ── CRUD Requests ──

  /// Publie une demande (consommateur courant).
  Future<void> createRequest({
    required String title,
    required String productName,
    double? quantity,
    String? unit,
    String? description,
    required double radiusKm,
    double? latitude,
    double? longitude,
    DateTime? expiresAt,
  }) async {
    final id = _uuid();
    final db = await _db.database;
    await db.insert('requests', {
      'id': id,
      'consumer_id': _uid,
      'title': title,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'description': description,
      'radius_km': radiusKm,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'ouverte',
      'expires_at': expiresAt?.toIso8601String(),
    });

    await _db.logActivity(_uid!, 'request_created', 'Demande "$title" créée',
        entity: 'request', entityId: id);

    if (_uid != null) await _refreshMyRequests(_uid!);
    await _refreshOpenRequests();
  }

  Future<MarketRequest?> fetchById(String id) async {
    final db = await _db.database;
    final rows = await db.query('requests', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return MarketRequest.fromMap(rows.first);
  }

  /// Flux des demandes de l'utilisateur (consommateur).
  Stream<List<MarketRequest>> watchMine(String consumerId) {
    _refreshMyRequests(consumerId);
    return _myRequestsCtrl(consumerId).stream;
  }

  /// Flux des demandes **ouvertes** (vue vendeur).
  Stream<List<MarketRequest>> watchOpen() {
    _refreshOpenRequests();
    return _openRequestsController.stream;
  }

  /// Flux des offres d'une demande.
  Stream<List<Offer>> watchOffers(String requestId) {
    _refreshOffers(requestId);
    return _offersCtrl(requestId).stream;
  }

  // ── CRUD Offers ──

  /// Soumet une offre (vendeur courant) en réponse à une demande.
  Future<void> submitOffer({
    required String requestId,
    String? shopId,
    required double price,
    double? quantity,
    String? unit,
    String? deliveryDelay,
    String? message,
  }) async {
    final id = _uuid();
    final db = await _db.database;
    await db.insert('offers', {
      'id': id,
      'request_id': requestId,
      'merchant_id': _uid,
      'shop_id': shopId,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'delivery_delay': deliveryDelay,
      'message': message,
      'status': 'proposee',
    });

    await _db.logActivity(_uid!, 'offer_submitted', 'Offre soumise',
        entity: 'offer', entityId: id);

    await _refreshOffers(requestId);
  }

  // ── RPCs remplacées par des méthodes Dart ──

  /// Accepte une offre → crée la commande, clôt la demande et refuse les
  /// autres offres. Renvoie l'id de la commande créée.
  Future<String?> acceptOffer(String offerId) async {
    final db = await _db.database;
    String? orderId;
    String? requestId;
    String? consumerId;
    String? merchantId;
    String? productName;

    await db.transaction((txn) async {
      // 1. Récupérer l'offre acceptée.
      final offerRows = await txn.query(
        'offers',
        where: 'id = ?',
        whereArgs: [offerId],
      );
      if (offerRows.isEmpty) return;
      final offer = offerRows.first;
      requestId = offer['request_id'] as String;
      merchantId = offer['merchant_id'] as String;
      final shopId = offer['shop_id'] as String?;
      final price = (offer['price'] as num).toDouble();
      final quantity = (offer['quantity'] as num?)?.toDouble() ?? 1;

      // 2. Récupérer la demande pour le consumer_id + product_name.
      final requestRows = await txn.query(
        'requests',
        where: 'id = ?',
        whereArgs: [requestId],
      );
      if (requestRows.isEmpty) return;
      consumerId = requestRows.first['consumer_id'] as String;
      productName = requestRows.first['product_name'] as String? ?? 'Produit';

      // 3. Créer la commande.
      orderId = _uuid();
      await txn.insert('orders', {
        'id': orderId,
        'buyer_id': consumerId,
        'shop_id': shopId ?? '',
        'status': 'en_cours',
        'total_amount': price * quantity,
      });

      // 4. Créer la ligne de commande.
      await txn.insert('order_items', {
        'id': _uuid(),
        'order_id': orderId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': price,
      });

      // 5. Mettre à jour l'offre acceptée.
      await txn.update(
        'offers',
        {'status': 'acceptee'},
        where: 'id = ?',
        whereArgs: [offerId],
      );

      // 6. Refuser les autres offres de la même demande.
      await txn.update(
        'offers',
        {'status': 'refusee'},
        where: 'request_id = ? AND id != ?',
        whereArgs: [requestId, offerId],
      );

      // 7. Clôturer la demande.
      await txn.update(
        'requests',
        {'status': 'pourvue', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [requestId],
      );
    });

    // Notifications et logs APRÈS la transaction (pas de deadlock).
    if (consumerId != null && orderId != null) {
      await _db.pushNotif(
        consumerId!,
        'order',
        'Commande créée',
        'Votre demande a été pourvue. Commande #$orderId créée.',
      );
    }
    if (merchantId != null && orderId != null) {
      await _db.pushNotif(
        merchantId!,
        'order',
        'Offre acceptée',
        'Votre offre a été acceptée. Commande #$orderId créée.',
      );
    }
    if (_uid != null && orderId != null) {
      await _db.logActivity(
        _uid!,
        'offer_accepted',
        'Offre $offerId acceptée → commande $orderId',
        entity: 'offer',
        entityId: offerId,
      );
    }

    // Rafraîchir les streams.
    if (_uid != null) await _refreshMyRequests(_uid!);
    await _refreshOpenRequests();
    if (requestId != null) await _refreshOffers(requestId!);

    return orderId;
  }

  /// Le client contre-propose un prix sur une offre (négociation).
  Future<void> counterOffer(String offerId, double price, String? message) async {
    final db = await _db.database;
    await db.update(
      'offers',
      {
        'counter_price': price,
        'status': 'contre_proposee',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [offerId],
    );

    // Notifier le vendeur.
    final offerRows = await db.query('offers', where: 'id = ?', whereArgs: [offerId]);
    if (offerRows.isNotEmpty) {
      final merchantId = offerRows.first['merchant_id'] as String;
      final requestId = offerRows.first['request_id'] as String;

      await _db.pushNotif(
        merchantId,
        'counter_offer',
        'Contre-proposition',
        'Un client a contre-proposé un prix de $price.',
      );

      await _db.logActivity(
        _uid!,
        'offer_countered',
        'Contre-proposition sur offre $offerId',
        entity: 'offer',
        entityId: offerId,
      );

      await _refreshOffers(requestId);
    }
  }

  /// Le vendeur accepte le prix proposé (l'offre repasse au nouveau prix).
  Future<void> acceptCounter(String offerId) async {
    final db = await _db.database;
    final offerRows = await db.query('offers', where: 'id = ?', whereArgs: [offerId]);
    if (offerRows.isEmpty) return;

    final counterPrice = (offerRows.first['counter_price'] as num?)?.toDouble();
    final requestId = offerRows.first['request_id'] as String;
    final consumerId = (await db.query('requests',
            where: 'id = ?', whereArgs: [requestId]))
        .first['consumer_id'] as String;

    await db.update(
      'offers',
      {
        'price': counterPrice,
        'counter_price': null,
        'status': 'proposee',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [offerId],
    );

    await _db.pushNotif(
      consumerId,
      'counter_accepted',
      'Contre-proposition acceptée',
      'Le vendeur a accepté votre contre-proposition.',
    );

    await _db.logActivity(
      _uid!,
      'counter_accepted',
      'Contre-proposition acceptée sur offre $offerId',
      entity: 'offer',
      entityId: offerId,
    );

    await _refreshOffers(requestId);
  }

  /// Le vendeur refuse le prix proposé (prix initial maintenu).
  Future<void> declineCounter(String offerId) async {
    final db = await _db.database;
    final offerRows = await db.query('offers', where: 'id = ?', whereArgs: [offerId]);
    if (offerRows.isEmpty) return;

    final requestId = offerRows.first['request_id'] as String;
    final consumerId = (await db.query('requests',
            where: 'id = ?', whereArgs: [requestId]))
        .first['consumer_id'] as String;

    await db.update(
      'offers',
      {
        'counter_price': null,
        'status': 'proposee',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [offerId],
    );

    await _db.pushNotif(
      consumerId,
      'counter_declined',
      'Contre-proposition refusée',
      'Le vendeur a refusé votre contre-proposition.',
    );

    await _db.logActivity(
      _uid!,
      'counter_declined',
      'Contre-proposition refusée sur offre $offerId',
      entity: 'offer',
      entityId: offerId,
    );

    await _refreshOffers(requestId);
  }

  /// Annule sa propre demande.
  Future<void> cancelRequest(String id) async {
    final db = await _db.database;
    await db.update(
      'requests',
      {'status': 'annulee', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );

    await _db.logActivity(_uid!, 'request_cancelled', 'Demande $id annulée',
        entity: 'request', entityId: id);

    if (_uid != null) await _refreshMyRequests(_uid!);
    await _refreshOpenRequests();
  }

  // ── Utils ──

  static String _uuid() {
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${(10000 + (DateTime.now().microsecond % 90000))}';
  }

  void dispose() {
    for (final ctrl in _myRequestsControllers.values) {
      ctrl.close();
    }
    for (final ctrl in _offersControllers.values) {
      ctrl.close();
    }
    _openRequestsController.close();
  }
}

// ── Providers ──

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  return RequestsRepository(
    ref.watch(databaseProvider),
    ref.watch(localAuthProvider),
  );
});

/// Mes demandes (consommateur) — temps réel.
final myRequestsStreamProvider =
    StreamProvider.autoDispose<List<MarketRequest>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(requestsRepositoryProvider).watchMine(uid);
});

/// Demandes ouvertes (vendeurs) — temps réel.
final openRequestsStreamProvider =
    StreamProvider.autoDispose<List<MarketRequest>>((ref) {
  return ref.watch(requestsRepositoryProvider).watchOpen();
});

/// Une demande par id (rafraîchie après acceptation).
final requestByIdProvider =
    FutureProvider.autoDispose.family<MarketRequest?, String>((ref, id) {
  return ref.watch(requestsRepositoryProvider).fetchById(id);
});

/// Offres d'une demande — temps réel.
final offersForRequestProvider =
    StreamProvider.autoDispose.family<List<Offer>, String>((ref, requestId) {
  return ref.watch(requestsRepositoryProvider).watchOffers(requestId);
});
