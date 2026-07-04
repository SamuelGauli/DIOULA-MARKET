import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/order.dart';

/// Accès aux commandes + livraison (table `orders`).
/// Les transitions (prise en charge, livraison) sont des RPC atomiques
/// côté SQL (`step10.sql`).
class OrdersRepository {
  OrdersRepository(this._client);
  final SupabaseClient _client;

  // Jointures : boutique, acheteur (FK buyer_id), lignes de commande.
  static const _select =
      '*, shops(name), buyer:profiles!buyer_id(full_name), '
      'order_items(product_name, quantity)';

  /// Pool des courses disponibles (non assignées) — visible par les livreurs.
  Future<List<Order>> fetchAvailable() async {
    final data = await _client
        .from('orders')
        .select(_select)
        .isFilter('courier_id', null)
        .inFilter('status', ['en_cours', 'preparee']).order('created_at');
    return (data as List)
        .map((e) => Order.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Les courses du livreur connecté (en cours + historique).
  Future<List<Order>> fetchMyCourses() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client
        .from('orders')
        .select(_select)
        .eq('courier_id', uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Order.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Les commandes de l'acheteur connecté (suivi).
  Future<List<Order>> fetchMyOrders() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client
        .from('orders')
        .select(_select)
        .eq('buyer_id', uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Order.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Les commandes reçues par une boutique (suivi côté vendeur).
  Future<List<Order>> fetchForShop(String shopId) async {
    final data = await _client
        .from('orders')
        .select(_select)
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Order.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Le livreur prend la course sur un **créneau** (réservé dans son agenda).
  Future<void> claimOrder(String id, DateTime slotStart, DateTime slotEnd) =>
      _client.rpc('claim_order', params: {
        'p_order_id': id,
        'p_slot_start': slotStart.toIso8601String(),
        'p_slot_end': slotEnd.toIso8601String(),
      });

  /// Planning du livreur : ses livraisons à venir (en cours), triées par créneau.
  Future<List<Order>> fetchMySchedule() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client
        .from('orders')
        .select(_select)
        .eq('courier_id', uid)
        .eq('status', 'en_livraison')
        .order('slot_start', ascending: true, nullsFirst: false);
    return (data as List)
        .map((e) => Order.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markDelivered(String id) =>
      _client.rpc('mark_order_delivered', params: {'p_order_id': id});

  /// Le livreur fait avancer la livraison d'une étape (récupéré → … → livré).
  Future<void> advanceDelivery(String id) =>
      _client.rpc('advance_delivery', params: {'p_order_id': id});
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(supabaseProvider));
});

/// Pool des courses disponibles (livreur).
final availableCoursesProvider =
    FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).fetchAvailable();
});

/// Courses prises en charge par le livreur connecté.
final myCoursesProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).fetchMyCourses();
});

/// Planning du livreur (livraisons à venir, triées par créneau).
final myScheduleProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).fetchMySchedule();
});

/// Commandes de l'acheteur connecté (suivi).
final myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).fetchMyOrders();
});

/// Commandes reçues par une boutique (suivi côté vendeur).
final shopOrdersProvider =
    FutureProvider.autoDispose.family<List<Order>, String>((ref, shopId) {
  return ref.watch(ordersRepositoryProvider).fetchForShop(shopId);
});

/// Ligne d'**une** commande en **temps réel** (suivi du colis).
/// `orders` est publié en Realtime (`step10.sql`). Pas de jointure (le reste
/// vient de l'objet `Order` passé à l'écran) : on récupère ici `status` et
/// `courier_id` en direct. `null` si la ligne n'est pas (encore) visible.
final orderLiveProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, orderId) {
  final client = ref.watch(supabaseProvider);
  return client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('id', orderId)
      .map((rows) => rows.isEmpty ? null : rows.first);
});
