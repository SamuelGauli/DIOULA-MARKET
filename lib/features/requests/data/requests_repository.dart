import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/market_request.dart';
import '../domain/offer.dart';

/// Accès aux **demandes instantanées** et aux **offres**, avec flux temps réel
/// (Supabase Realtime via `.stream()`).
class RequestsRepository {
  RequestsRepository(this._client);
  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

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
    await _client.from('requests').insert({
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
  }

  Future<MarketRequest?> fetchById(String id) async {
    final data =
        await _client.from('requests').select().eq('id', id).maybeSingle();
    return data == null ? null : MarketRequest.fromMap(data);
  }

  /// Flux temps réel des demandes de l'utilisateur (consommateur).
  Stream<List<MarketRequest>> watchMine(String consumerId) {
    return _client
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('consumer_id', consumerId)
        .order('created_at')
        .map((rows) => rows.map(MarketRequest.fromMap).toList());
  }

  /// Flux temps réel des demandes **ouvertes** (vue vendeur).
  Stream<List<MarketRequest>> watchOpen() {
    return _client
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'ouverte')
        .order('created_at')
        .map((rows) => rows.map(MarketRequest.fromMap).toList());
  }

  /// Flux temps réel des offres d'une demande.
  Stream<List<Offer>> watchOffers(String requestId) {
    return _client
        .from('offers')
        .stream(primaryKey: ['id'])
        .eq('request_id', requestId)
        .order('created_at')
        .map((rows) => rows.map(Offer.fromMap).toList());
  }

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
    await _client.from('offers').insert({
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
  }

  /// Accepte une offre → crée la commande, clôt la demande et refuse les
  /// autres offres (fonction SQL atomique `accept_offer`). Renvoie l'id commande.
  Future<String?> acceptOffer(String offerId) async {
    final res =
        await _client.rpc('accept_offer', params: {'p_offer_id': offerId});
    return res as String?;
  }

  /// Le client contre-propose un prix sur une offre (négociation).
  Future<void> counterOffer(String offerId, double price, String? message) =>
      _client.rpc('counter_offer', params: {
        'p_offer_id': offerId,
        'p_price': price,
        'p_message': message,
      });

  /// Le vendeur accepte le prix proposé (l'offre repasse au nouveau prix).
  Future<void> acceptCounter(String offerId) =>
      _client.rpc('accept_counter', params: {'p_offer_id': offerId});

  /// Le vendeur refuse le prix proposé (prix initial maintenu).
  Future<void> declineCounter(String offerId) =>
      _client.rpc('decline_counter', params: {'p_offer_id': offerId});

  /// Annule sa propre demande.
  Future<void> cancelRequest(String id) async {
    await _client.from('requests').update({'status': 'annulee'}).eq('id', id);
  }
}

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  return RequestsRepository(ref.watch(supabaseProvider));
});

/// Mes demandes (consommateur) — temps réel.
final myRequestsStreamProvider =
    StreamProvider.autoDispose<List<MarketRequest>>((ref) {
  final uid = ref.watch(supabaseProvider).auth.currentUser?.id;
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
