import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../activity/domain/activity_entry.dart';
import '../../products/domain/product.dart';
import '../../profile/domain/profile.dart';
import '../../reviews/domain/review.dart';
import '../../shops/domain/shop.dart';
import '../domain/admin_stats.dart';

/// Accès back-office : lectures globales + actions d'administration.
/// Les actions passent par des RPC `security definer` gardées par `is_admin()`
/// côté SQL — un non-admin reçoit une erreur, quoi qu'il tente côté client.
class AdminRepository {
  AdminRepository(this._client);
  final SupabaseClient _client;

  /// Statistiques globales (tableau de bord).
  Future<AdminStats> fetchStats() async {
    final data = await _client.rpc('admin_stats');
    return AdminStats.fromMap(Map<String, dynamic>.from(data as Map));
  }

  // ---- Listes de modération (lecture via les selects publics) ----

  /// Tous les profils (les plus récents d'abord).
  Future<List<Profile>> fetchAllProfiles() async {
    final data = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Profile.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Toutes les boutiques (actives ET suspendues).
  Future<List<Shop>> fetchAllShops() async {
    final data = await _client.from('shops').select().order('name');
    return (data as List)
        .map((e) => Shop.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Tous les produits (actifs ET masqués), avec le nom de leur boutique.
  /// Renvoie (produit, nom de boutique).
  Future<List<(Product, String)>> fetchAllProducts() async {
    final data = await _client
        .from('products')
        .select('*, shops(name)')
        .order('created_at', ascending: false);
    return (data as List).map((e) {
      final map = e as Map<String, dynamic>;
      final shopName =
          (map['shops'] as Map<String, dynamic>?)?['name'] as String? ?? '?';
      return (Product.fromMap(map), shopName);
    }).toList();
  }

  /// Profils en attente de vérification d'identité (les plus anciens d'abord).
  Future<List<Profile>> fetchPendingKyc() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('verification_status', 'en_attente')
        .order('created_at');
    return (data as List)
        .map((e) => Profile.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// URL signée (1 h) d'une pièce du bucket privé `kyc-docs`
  /// (lecture admin autorisée par la policy `kyc_select_admin`, step23).
  Future<String> signedKycUrl(String path) =>
      _client.storage.from('kyc-docs').createSignedUrl(path, 3600);

  // ---- Actions (RPC security definer, gardées par is_admin()) ----

  /// Bannit (`active=false`, avec motif) ou réactive un compte ;
  /// le bannissement suspend aussi ses boutiques.
  Future<void> setUserActive(String userId, bool active, {String? reason}) =>
      _client.rpc('admin_set_user_active', params: {
        'p_user': userId,
        'p_active': active,
        'p_reason': reason,
      });

  /// Suspend ou réactive une boutique.
  Future<void> setShopActive(String shopId, bool active) =>
      _client.rpc('admin_set_shop_active',
          params: {'p_shop': shopId, 'p_active': active});

  /// Masque ou republie un produit.
  Future<void> setProductActive(String productId, bool active) =>
      _client.rpc('admin_set_product_active',
          params: {'p_product': productId, 'p_active': active});

  /// Approuve ou refuse une vérification d'identité en attente.
  Future<void> reviewKyc(String userId, {required bool approve}) =>
      _client.rpc('admin_review_kyc',
          params: {'p_user': userId, 'p_approve': approve});

  // ---- Avis / annonces / audit (commit admin 3) ----

  /// Tous les avis (masqués compris), auteur joint, les plus récents d'abord.
  Future<List<Review>> fetchAllReviews() async {
    final data = await _client
        .from('reviews')
        .select('*, author:profiles!author_id(full_name, avatar_url)')
        .order('created_at', ascending: false)
        .limit(200);
    return (data as List)
        .map((e) => Review.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Masque ou rétablit un avis (recalcul de la note côté SQL).
  Future<void> setReviewHidden(String reviewId, bool hidden) =>
      _client.rpc('admin_set_review_hidden',
          params: {'p_review': reviewId, 'p_hidden': hidden});

  /// Diffuse une annonce (notification) à tous les comptes actifs.
  /// Renvoie le nombre de destinataires.
  Future<int> broadcast(String title, String? body) async {
    final n = await _client.rpc('admin_broadcast',
        params: {'p_title': title, 'p_body': body});
    return (n as num?)?.toInt() ?? 0;
  }

  /// Journal d'audit **global** (toutes les actions), avec le nom de l'acteur.
  /// Nécessite la policy `activity_admin_select` (step24).
  Future<List<(ActivityEntry, String)>> fetchAudit() async {
    final data = await _client
        .from('activity_log')
        .select('*, actor:profiles!actor_id(full_name)')
        .order('created_at', ascending: false)
        .limit(200);
    return (data as List).map((e) {
      final map = e as Map<String, dynamic>;
      final actor =
          (map['actor'] as Map<String, dynamic>?)?['full_name'] as String? ??
              'Utilisateur';
      return (ActivityEntry.fromMap(map), actor);
    }).toList();
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseProvider));
});

/// Statistiques globales de la plateforme (rafraîchies par invalidation).
final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  return ref.watch(adminRepositoryProvider).fetchStats();
});

/// Tous les profils (modération des comptes).
final adminProfilesProvider =
    FutureProvider.autoDispose<List<Profile>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchAllProfiles();
});

/// Toutes les boutiques (modération).
final adminShopsProvider = FutureProvider.autoDispose<List<Shop>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchAllShops();
});

/// Tous les produits + nom de boutique (modération).
final adminProductsProvider =
    FutureProvider.autoDispose<List<(Product, String)>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchAllProducts();
});

/// File des vérifications d'identité en attente.
final adminPendingKycProvider =
    FutureProvider.autoDispose<List<Profile>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchPendingKyc();
});

/// Tous les avis (modération).
final adminReviewsProvider = FutureProvider.autoDispose<List<Review>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchAllReviews();
});

/// Journal d'audit global (entrée + nom de l'acteur).
final adminAuditProvider =
    FutureProvider.autoDispose<List<(ActivityEntry, String)>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchAudit();
});
