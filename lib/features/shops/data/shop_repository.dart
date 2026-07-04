import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/shop.dart';

class ShopRepository {
  ShopRepository(this._db);
  final AppDatabase _db;

  Future<Shop?> fetchByOwner(String ownerId) async {
    final db = await _db.database;
    final rows = await db.query(
      'shops',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'created_at ASC',
      limit: 1,
    );
    return rows.isEmpty ? null : Shop.fromMap(rows.first);
  }

  Future<Shop> create(Shop shop) async {
    final db = await _db.database;
    final data = shop.toWriteMap();
    data['id'] = _uuid();
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.insert('shops', data);
    return Shop.fromMap(data);
  }

  Future<Shop> update(Shop shop) async {
    final db = await _db.database;
    final data = shop.toWriteMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update(
      'shops',
      data,
      where: 'id = ?',
      whereArgs: [shop.id],
    );
    final rows = await db.query(
      'shops',
      where: 'id = ?',
      whereArgs: [shop.id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return shop;
    }
    return Shop.fromMap(rows.first);
  }

  Future<String> uploadShopImage({
    required String kind,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (kIsWeb) {
      return 'data:image/jpeg;base64,${_bytesToBase64(bytes)}';
    }
    final dir = await getApplicationDocumentsDirectory();
    final shopImagesDir = Directory(p.join(dir.path, 'shop_images'));
    if (!await shopImagesDir.exists()) {
      await shopImagesDir.create(recursive: true);
    }
    final filename = '${kind}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(p.join(shopImagesDir.path, filename));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static String _bytesToBase64(Uint8List bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    String result = '';
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result += chars[(b0 >> 2) & 0x3F];
      result += chars[((b0 << 4) | (b1 >> 4)) & 0x3F];
      result += i + 1 < bytes.length ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F] : '=';
      result += i + 2 < bytes.length ? chars[b2 & 0x3F] : '=';
    }
    return result;
  }

  static String _uuid() {
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${(10000 + (DateTime.now().microsecond % 90000))}';
  }
}

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.watch(databaseProvider));
});

final myShopProvider = FutureProvider<Shop?>((ref) async {
  ref.watch(authStateProvider);
  final uid = ref.watch(localAuthProvider).currentUserId;
  if (uid == null) return null;
  return ref.watch(shopRepositoryProvider).fetchByOwner(uid);
});
