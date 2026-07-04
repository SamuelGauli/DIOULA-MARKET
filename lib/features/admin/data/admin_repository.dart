import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../activity/domain/activity_entry.dart';
import '../../products/domain/product.dart';
import '../../profile/domain/profile.dart';
import '../../reviews/domain/review.dart';
import '../../shops/domain/shop.dart';
import '../domain/admin_stats.dart';

/// Accès back-office : lectures globales + actions d'administration.
/// Toutes les opérations passent par SQLite local.
class AdminRepository {
  AdminRepository(this._db);
  final AppDatabase _db;

  // ── Statistiques globales (tableau de bord) ──

  Future<AdminStats> fetchStats() async {
    final db = await _db.database;

    final usersTotal =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM profiles')) ?? 0;

    final rolesRows = await db.rawQuery(
        'SELECT role, COUNT(*) as cnt FROM profiles GROUP BY role');
    final usersByRole = <String, int>{
      for (final r in rolesRows) r['role'] as String: r['cnt'] as int,
    };

    final kycPending = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM profiles WHERE verification_status = 'en_attente'")) ??
        0;

    final shopsTotal =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM shops')) ?? 0;
    final shopsActive =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM shops WHERE is_active = 1')) ?? 0;

    final productsTotal =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products')) ?? 0;
    final productsActive =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products WHERE is_active = 1')) ?? 0;

    final ordersTotal =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM orders')) ?? 0;

    final orderStatusRows = await db.rawQuery(
        'SELECT status, COUNT(*) as cnt FROM orders GROUP BY status');
    final ordersByStatus = <String, int>{
      for (final r in orderStatusRows) r['status'] as String: r['cnt'] as int,
    };

    final gmvRow = await db.rawQuery(
        "SELECT COALESCE(SUM(total_amount), 0) as gmv FROM orders WHERE status = 'livree'");
    final gmv = (gmvRow.first['gmv'] as num?)?.toDouble() ?? 0;

    final reservationsTotal = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM reservations')) ??
        0;

    final requestsOpen = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM requests WHERE status = 'ouverte'")) ??
        0;

    final reviewsTotal =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reviews')) ?? 0;

    return AdminStats(
      usersTotal: usersTotal,
      usersByRole: usersByRole,
      kycPending: kycPending,
      shopsTotal: shopsTotal,
      shopsActive: shopsActive,
      productsTotal: productsTotal,
      productsActive: productsActive,
      ordersTotal: ordersTotal,
      ordersByStatus: ordersByStatus,
      gmv: gmv,
      reservationsTotal: reservationsTotal,
      requestsOpen: requestsOpen,
      reviewsTotal: reviewsTotal,
    );
  }

  // ── Listes de modération ──

  Future<List<Profile>> fetchAllProfiles() async {
    final db = await _db.database;
    final rows = await db.query('profiles', orderBy: 'created_at DESC');
    return rows.map((e) => Profile.fromMap(e)).toList();
  }

  Future<List<Shop>> fetchAllShops() async {
    final db = await _db.database;
    final rows = await db.query('shops', orderBy: 'name ASC');
    return rows.map((e) => Shop.fromMap(e)).toList();
  }

  Future<List<(Product, String)>> fetchAllProducts() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.*, s.name as shop_name
      FROM products p
      JOIN shops s ON s.id = p.shop_id
      ORDER BY p.created_at DESC
    ''');
    return rows.map((e) {
      final shopName = e['shop_name'] as String? ?? '?';
      final productMap = Map<String, dynamic>.from(e)..remove('shop_name');
      return (Product.fromMap(productMap), shopName);
    }).toList();
  }

  Future<List<Profile>> fetchPendingKyc() async {
    final db = await _db.database;
    final rows = await db.query(
      'profiles',
      where: "verification_status = 'en_attente'",
      orderBy: 'created_at ASC',
    );
    return rows.map((e) => Profile.fromMap(e)).toList();
  }

  /// En local, les chemins KYC sont déjà des chemins de fichiers locaux.
  /// On retourne le chemin tel quel (pas de signature requise).
  Future<String> signedKycUrl(String path) async => path;

  // ── Actions d'administration ──

  /// Bannit (`active=false`, avec motif) ou réactive un compte.
  /// Le bannissement suspend aussi ses boutiques.
  Future<void> setUserActive(String userId, bool active,
      {String? reason, String? adminId}) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'profiles',
      {
        'is_active': active ? 1 : 0,
        'ban_reason': active ? null : reason,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    // Si bannissement, suspendre toutes ses boutiques.
    if (!active) {
      await db.update(
        'shops',
        {'is_active': 0, 'updated_at': now},
        where: 'owner_id = ?',
        whereArgs: [userId],
      );
    }

    // Notification à l'utilisateur.
    await _db.pushNotif(
      userId,
      'admin',
      active ? 'Compte réactivé' : 'Compte suspendu',
      active
          ? 'Votre compte a été réactivé par un administrateur.'
          : 'Votre compte a été suspendu${reason != null ? ' : $reason' : ''}.',
    );

    // Journal d'audit.
    if (adminId != null) {
      await _db.logActivity(
        adminId,
        active ? 'admin_user_reactivated' : 'admin_user_banned',
        active
            ? 'Compte $userId réactivé'
            : 'Compte $userId suspendu${reason != null ? ' ($reason)' : ''}',
        entity: 'profile',
        entityId: userId,
      );
    }
  }

  /// Suspend ou réactive une boutique.
  Future<void> setShopActive(String shopId, bool active,
      {String? adminId}) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'shops',
      {'is_active': active ? 1 : 0, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [shopId],
    );

    // Notification au propriétaire.
    final shopRow = await db.query('shops', where: 'id = ?', whereArgs: [shopId], limit: 1);
    if (shopRow.isNotEmpty) {
      final ownerId = shopRow.first['owner_id'] as String;
      await _db.pushNotif(
        ownerId,
        'admin',
        active ? 'Boutique réactivée' : 'Boutique suspendue',
        active
            ? 'Votre boutique a été réactivée par un administrateur.'
            : 'Votre boutique a été suspendue par un administrateur.',
      );
    }

    if (adminId != null) {
      await _db.logActivity(
        adminId,
        active ? 'admin_shop_reactivated' : 'admin_shop_suspended',
        active
            ? 'Boutique $shopId réactivée'
            : 'Boutique $shopId suspendue',
        entity: 'shop',
        entityId: shopId,
      );
    }
  }

  /// Masque ou republie un produit.
  Future<void> setProductActive(String productId, bool active,
      {String? adminId}) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'products',
      {'is_active': active ? 1 : 0, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (adminId != null) {
      await _db.logActivity(
        adminId,
        active ? 'admin_product_revealed' : 'admin_product_hidden',
        active
            ? 'Produit $productId rendu visible'
            : 'Produit $productId masqué',
        entity: 'product',
        entityId: productId,
      );
    }
  }

  /// Approuve ou refuse une vérification d'identité en attente.
  Future<void> reviewKyc(String userId,
      {required bool approve, String? adminId}) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'profiles',
      {
        'verification_status': approve ? 'verifie' : 'refuse',
        'verified_at': approve ? now : null,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    await _db.pushNotif(
      userId,
      'admin',
      approve ? 'Identité vérifiée' : 'Identité refusée',
      approve
          ? 'Votre identité a été vérifiée avec succès.'
          : 'Votre vérification d\'identité a été refusée. Vous pouvez soumettre de nouveaux documents.',
    );

    if (adminId != null) {
      await _db.logActivity(
        adminId,
        approve ? 'admin_kyc_approved' : 'admin_kyc_rejected',
        approve
            ? 'KYC de $userId approuvé'
            : 'KYC de $userId refusé',
        entity: 'profile',
        entityId: userId,
      );
    }
  }

  // ── Avis ──

  Future<List<Review>> fetchAllReviews() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT r.*, p.full_name as author_name, p.avatar_url as author_avatar
      FROM reviews r
      LEFT JOIN profiles p ON p.id = r.author_id
      ORDER BY r.created_at DESC
      LIMIT 200
    ''');
    return rows.map((e) {
      final map = Map<String, dynamic>.from(e);
      map['author'] = {
        'full_name': e['author_name'],
        'avatar_url': e['author_avatar'],
      };
      return Review.fromMap(map);
    }).toList();
  }

  /// Masque ou rétablit un avis, puis recalcule les notes de la boutique
  /// et du profil ciblé.
  Future<void> setReviewHidden(String reviewId, bool hidden,
      {String? adminId}) async {
    final db = await _db.database;

    await db.update(
      'reviews',
      {'is_hidden': hidden ? 1 : 0},
      where: 'id = ?',
      whereArgs: [reviewId],
    );

    // Recomputer les notes de la boutique concernée.
    final reviewRow = await db.query('reviews',
        where: 'id = ?', whereArgs: [reviewId], limit: 1);
    if (reviewRow.isNotEmpty) {
      final shopId = reviewRow.first['shop_id'] as String?;
      final targetId = reviewRow.first['target_id'] as String?;
      if (shopId != null) await _db.recomputeShopRating(shopId);
      if (targetId != null) await _db.recomputeProfileRating(targetId);
    }

    if (adminId != null) {
      await _db.logActivity(
        adminId,
        hidden ? 'admin_review_hidden' : 'admin_review_revealed',
        hidden
            ? 'Avis $reviewId masqué'
            : 'Avis $reviewId rétabli',
        entity: 'review',
        entityId: reviewId,
      );
    }
  }

  // ── Annonces / broadcast ──

  /// Diffuse une annonce (notification) à tous les comptes actifs.
  /// Renvoie le nombre de destinataires.
  Future<int> broadcast(String title, String? body,
      {String? adminId}) async {
    final db = await _db.database;
    final rows = await db.query('profiles', where: 'is_active = 1');
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();
    for (final row in rows) {
      batch.insert('notifications', {
        'id': '${DateTime.now().microsecondsSinceEpoch}-${row['id']}',
        'user_id': row['id'],
        'type': 'broadcast',
        'title': title,
        'body': body,
        'is_read': 0,
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);

    if (adminId != null) {
      await _db.logActivity(
        adminId,
        'admin_broadcast',
        'Diffusion "$title" envoyée à ${rows.length} utilisateurs',
      );
    }

    return rows.length;
  }

  // ── Journal d'audit ──

  Future<List<(ActivityEntry, String)>> fetchAudit() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT a.*, p.full_name as actor_name
      FROM activity_log a
      LEFT JOIN profiles p ON p.id = a.actor_id
      ORDER BY a.created_at DESC
      LIMIT 200
    ''');
    return rows.map((e) {
      final actor = e['actor_name'] as String? ?? 'Utilisateur';
      final entry = ActivityEntry.fromMap(e);
      return (entry, actor);
    }).toList();
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(databaseProvider));
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
