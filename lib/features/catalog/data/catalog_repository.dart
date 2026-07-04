import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../shops/domain/shop.dart';
import '../domain/catalog_product.dart';
import '../domain/instant_request.dart';

/// Accès en **lecture** au catalogue public (produits, boutiques, demandes).
/// Lisible par tout le monde, y compris les visiteurs.
/// Utilise SQLite local au lieu de Supabase.
class CatalogRepository {
  CatalogRepository(this._db);
  final AppDatabase _db;

  /// Tous les produits actifs, avec les infos de leur boutique (jointure).
  /// Les produits d'une boutique **suspendue** disparaissent du catalogue.
  Future<List<CatalogProduct>> fetchProducts() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT
        p.id, p.shop_id, p.name, p.description, p.category, p.unit,
        p.price, p.stock, p.image_url, p.is_active, p.promo_price,
        p.sale_mode,
        s.name        AS shop_name,
        s.commune     AS shop_commune,
        s.rating_avg  AS shop_rating_avg,
        s.rating_count AS shop_rating_count,
        s.latitude    AS shop_lat,
        s.longitude   AS shop_lng
      FROM products p
      INNER JOIN shops s ON s.id = p.shop_id
      WHERE p.is_active = 1
        AND s.is_active = 1
      ORDER BY p.created_at DESC
    ''');
    return rows.map((r) => CatalogProduct.fromMap({
      'id': r['id'],
      'shop_id': r['shop_id'],
      'name': r['name'],
      'description': r['description'],
      'category': r['category'],
      'unit': r['unit'],
      'price': r['price'],
      'stock': r['stock'],
      'image_url': r['image_url'],
      'is_active': r['is_active'],
      'promo_price': r['promo_price'],
      'sale_mode': r['sale_mode'],
      'shops': {
        'name': r['shop_name'],
        'commune': r['shop_commune'],
        'rating_avg': r['shop_rating_avg'],
        'rating_count': r['shop_rating_count'],
        'latitude': r['shop_lat'],
        'longitude': r['shop_lng'],
      },
    })).toList();
  }

  /// Toutes les boutiques actives, triées par meilleure note.
  Future<List<Shop>> fetchShops() async {
    final db = await _db.database;
    final rows = await db.query(
      'shops',
      where: 'is_active = 1',
      orderBy: 'rating_avg DESC',
    );
    return rows.map((r) => Shop.fromMap(r)).toList();
  }

  /// Demandes instantanées ouvertes (avec l'auteur).
  Future<List<InstantRequest>> fetchOpenRequests() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT
        r.id, r.title, r.product_name, r.quantity, r.unit,
        r.radius_km, r.expires_at,
        p.full_name  AS author_name,
        p.commune    AS author_commune
      FROM requests r
      LEFT JOIN profiles p ON p.id = r.consumer_id
      WHERE r.status = 'ouverte'
      ORDER BY r.created_at DESC
      LIMIT 10
    ''');
    return rows.map((r) => InstantRequest.fromMap({
      'id': r['id'],
      'title': r['title'],
      'product_name': r['product_name'],
      'quantity': r['quantity'],
      'unit': r['unit'],
      'radius_km': r['radius_km'],
      'expires_at': r['expires_at'],
      'profiles': {
        'full_name': r['author_name'],
        'commune': r['author_commune'],
      },
    })).toList();
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(databaseProvider));
});

/// Tous les produits du catalogue (sert à l'accueil + à la recherche).
final allProductsProvider = FutureProvider<List<CatalogProduct>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchProducts();
});

/// Toutes les boutiques (triées par note).
final allShopsProvider = FutureProvider<List<Shop>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchShops();
});

/// Boutiques « producteurs » (catégorie = Producteur).
final producerShopsProvider = FutureProvider<List<Shop>>((ref) async {
  final shops = await ref.watch(allShopsProvider.future);
  return shops.where((s) => s.category == 'Producteur').toList();
});

/// Demandes instantanées ouvertes.
final openRequestsProvider = FutureProvider<List<InstantRequest>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchOpenRequests();
});

/// Produits d'une boutique donnée (pour l'écran détail boutique).
final shopProductsProvider =
    FutureProvider.family<List<CatalogProduct>, String>((ref, shopId) async {
  final all = await ref.watch(allProductsProvider.future);
  return all.where((p) => p.shopId == shopId).toList();
});

/// Le propriétaire d'une boutique est-il vérifié (KYC) ? Lecture **tolérante** :
/// renvoie `false` si la colonne n'existe pas encore ou en cas d'erreur.
final shopOwnerVerifiedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, ownerId) async {
  try {
    final db = await ref.watch(databaseProvider).database;
    final rows = await db.query(
      'profiles',
      columns: ['verification_status'],
      where: 'id = ?',
      whereArgs: [ownerId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final status = rows.first['verification_status'] as String?;
    return status == 'verifie';
  } catch (_) {
    return false;
  }
});
