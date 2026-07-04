import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/reservation.dart';

/// Accès aux réservations + acompte simulé (table `reservations`).
/// Les automatisations (stock, remboursement) sont côté SQL (`step6.sql`).
class ReservationsRepository {
  ReservationsRepository(this._client);
  final SupabaseClient _client;

  static const _select = '*, products(name, image_url, unit), shops(name)';

  Future<List<Reservation>> fetchMine() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client
        .from('reservations')
        .select(_select)
        .eq('buyer_id', uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Reservation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reservation>> fetchForShop(String shopId) async {
    final data = await _client
        .from('reservations')
        .select(_select)
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Reservation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Réserve sur un **créneau** (jour + plage) + paie l'acompte (simulé)
  /// + décrémente le stock (RPC atomique). `deadline` = fin du créneau.
  Future<String?> reserveProduct({
    required String productId,
    required double quantity,
    required DateTime slotStart,
    required DateTime slotEnd,
  }) async {
    final res = await _client.rpc('reserve_product', params: {
      'p_product_id': productId,
      'p_quantity': quantity,
      'p_slot_start': slotStart.toIso8601String(),
      'p_slot_end': slotEnd.toIso8601String(),
    });
    return res as String?;
  }

  Future<void> completeReservation(String id) =>
      _client.rpc('complete_reservation', params: {'p_id': id});

  Future<void> cancelReservation(String id) =>
      _client.rpc('cancel_reservation', params: {'p_id': id});

  /// Passe en « expirée » les réservations échues (sweep). Renvoie le nombre.
  Future<int> expireReservations() async {
    final res = await _client.rpc('expire_reservations');
    return (res as int?) ?? 0;
  }
}

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository(ref.watch(supabaseProvider));
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
