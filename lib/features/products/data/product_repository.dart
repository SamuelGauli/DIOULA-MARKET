import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/product.dart';

class ProductRepository {
  ProductRepository(this._db);
  final AppDatabase _db;

  static String _uuid() {
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${(10000 + (DateTime.now().microsecond % 90000))}';
  }

  Future<List<Product>> fetchByShop(String shopId) async {
    final db = await _db.database;
    final data = await db.query(
      'products',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: 'created_at DESC',
    );
    return data.map((e) => Product.fromMap(e)).toList();
  }

  Future<Product> create(Product product) async {
    final db = await _db.database;
    final map = product.toWriteMap();
    map['id'] = product.id.isNotEmpty ? product.id : _uuid();
    map['created_at'] = DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();
    await db.insert('products', map);
    return product;
  }

  Future<Product> update(Product product) async {
    final db = await _db.database;
    final map = product.toWriteMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    await db.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    return product;
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPromo(String id, double? promoPrice) async {
    final db = await _db.database;
    await db.update(
      'products',
      {
        'promo_price': promoPrice,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(databaseProvider));
});

final productsByShopProvider =
    FutureProvider.family<List<Product>, String>((ref, shopId) async {
  return ref.watch(productRepositoryProvider).fetchByShop(shopId);
});
