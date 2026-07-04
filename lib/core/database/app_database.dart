import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'seed_data.dart';

/// Base de données locale SQLite (remplace Supabase).
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Future<Database>? _future;

  Future<Database> get database async => _future ??= _initDb();

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'dioula_market.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await SeedData.seed(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        full_name TEXT,
        phone TEXT,
        role TEXT NOT NULL DEFAULT 'consommateur',
        avatar_url TEXT,
        commune TEXT,
        latitude REAL,
        longitude REAL,
        rating_avg REAL NOT NULL DEFAULT 0,
        rating_count INTEGER NOT NULL DEFAULT 0,
        verification_status TEXT NOT NULL DEFAULT 'non_soumis',
        id_doc_path TEXT,
        residence_doc_path TEXT,
        verified_at TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        ban_reason TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE shops (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        logo_url TEXT,
        banner_url TEXT,
        address TEXT,
        commune TEXT,
        phone TEXT,
        latitude REAL,
        longitude REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        rating_avg REAL NOT NULL DEFAULT 0,
        rating_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('CREATE INDEX idx_shops_owner ON shops(owner_id)');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        unit TEXT NOT NULL DEFAULT 'unité',
        price REAL NOT NULL DEFAULT 0,
        stock REAL NOT NULL DEFAULT 0,
        image_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        promo_price REAL,
        sale_mode TEXT NOT NULL DEFAULT 'detail',
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('CREATE INDEX idx_products_shop ON products(shop_id)');
    await db
        .execute('CREATE INDEX idx_products_category ON products(category)');

    await db.execute('''
      CREATE TABLE requests (
        id TEXT PRIMARY KEY,
        consumer_id TEXT NOT NULL,
        title TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL,
        unit TEXT DEFAULT 'unité',
        description TEXT,
        radius_km REAL NOT NULL DEFAULT 10,
        latitude REAL,
        longitude REAL,
        status TEXT NOT NULL DEFAULT 'ouverte',
        expires_at TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_requests_consumer ON requests(consumer_id)');
    await db.execute('CREATE INDEX idx_requests_status ON requests(status)');

    await db.execute('''
      CREATE TABLE offers (
        id TEXT PRIMARY KEY,
        request_id TEXT NOT NULL,
        merchant_id TEXT NOT NULL,
        shop_id TEXT,
        price REAL NOT NULL,
        quantity REAL,
        unit TEXT DEFAULT 'unité',
        delivery_delay TEXT,
        message TEXT,
        status TEXT NOT NULL DEFAULT 'proposee',
        counter_price REAL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db
        .execute('CREATE INDEX idx_offers_request ON offers(request_id)');
    await db
        .execute('CREATE INDEX idx_offers_merchant ON offers(merchant_id)');

    await db.execute('''
      CREATE TABLE reservations (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        shop_id TEXT NOT NULL,
        buyer_id TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0,
        deposit_amount REAL NOT NULL DEFAULT 0,
        deposit_paid INTEGER NOT NULL DEFAULT 0,
        refund_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'en_attente',
        deadline TEXT,
        slot_start TEXT,
        slot_end TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_reservations_buyer ON reservations(buyer_id)');
    await db.execute(
        'CREATE INDEX idx_reservations_shop ON reservations(shop_id)');
    await db.execute(
        'CREATE INDEX idx_reservations_status ON reservations(status)');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        buyer_id TEXT NOT NULL,
        shop_id TEXT NOT NULL,
        courier_id TEXT,
        status TEXT NOT NULL DEFAULT 'en_cours',
        total_amount REAL NOT NULL DEFAULT 0,
        delivery_address TEXT,
        latitude REAL,
        longitude REAL,
        delivery_step INTEGER NOT NULL DEFAULT 0,
        slot_start TEXT,
        slot_end TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('CREATE INDEX idx_orders_buyer ON orders(buyer_id)');
    await db.execute('CREATE INDEX idx_orders_shop ON orders(shop_id)');
    await db
        .execute('CREATE INDEX idx_orders_courier ON orders(courier_id)');

    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_order_items_order ON order_items(order_id)');

    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        author_id TEXT NOT NULL,
        target_id TEXT,
        shop_id TEXT,
        order_id TEXT,
        reservation_id TEXT,
        rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comment TEXT,
        is_hidden INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db
        .execute('CREATE INDEX idx_reviews_target ON reviews(target_id)');
    await db.execute('CREATE INDEX idx_reviews_shop ON reviews(shop_id)');
    await db.execute(
        'CREATE UNIQUE INDEX idx_reviews_unique_order ON reviews(author_id, order_id) WHERE order_id IS NOT NULL');
    await db.execute(
        'CREATE UNIQUE INDEX idx_reviews_unique_reservation ON reviews(author_id, reservation_id) WHERE reservation_id IS NOT NULL');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        payer_id TEXT NOT NULL,
        reservation_id TEXT,
        order_id TEXT,
        amount REAL NOT NULL,
        kind TEXT NOT NULL DEFAULT 'acompte',
        status TEXT NOT NULL DEFAULT 'simule',
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db
        .execute('CREATE INDEX idx_payments_payer ON payments(payer_id)');

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'info',
        title TEXT NOT NULL,
        body TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_notifications_user ON notifications(user_id, is_read)');

    await db.execute('''
      CREATE TABLE activity_log (
        id TEXT PRIMARY KEY,
        actor_id TEXT NOT NULL,
        action TEXT NOT NULL,
        detail TEXT NOT NULL,
        entity TEXT,
        entity_id TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_activity_actor ON activity_log(actor_id, created_at DESC)');
  }

  // ── Helpers ──

  Future<void> close() async {
    final db = await database;
    await db.close();
    _future = null;
  }

  Future<void> reset() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'dioula_market.db');
    await deleteDatabase(path);
    _future = null;
  }

  // ── Notification helpers (remplace push_notif SQL) ──

  Future<void> pushNotif(
      String userId, String type, String title, String body) async {
    final db = await database;
    await db.insert('notifications', {
      'id': _uuid(),
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
    });
  }

  // ── Activity log helpers ──

  Future<void> logActivity(String actorId, String action, String detail,
      {String? entity, String? entityId}) async {
    final db = await database;
    await db.insert('activity_log', {
      'id': _uuid(),
      'actor_id': actorId,
      'action': action,
      'detail': detail,
      'entity': entity,
      'entity_id': entityId,
    });
  }

  // ── Rating recomputation ──

  Future<void> recomputeShopRating(String shopId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT AVG(rating) as avg_rating, COUNT(*) as cnt
      FROM reviews WHERE shop_id = ? AND COALESCE(is_hidden, 0) = 0
    ''', [shopId]);
    final avg = (result.first['avg_rating'] as num?)?.toDouble() ?? 0;
    final cnt = (result.first['cnt'] as int?) ?? 0;
    await db.update(
      'shops',
      {
        'rating_avg': avg,
        'rating_count': cnt,
        'updated_at': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [shopId],
    );
  }

  Future<void> recomputeProfileRating(String profileId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT AVG(rating) as avg_rating, COUNT(*) as cnt
      FROM reviews WHERE target_id = ? AND COALESCE(is_hidden, 0) = 0
    ''', [profileId]);
    final avg = (result.first['avg_rating'] as num?)?.toDouble() ?? 0;
    final cnt = (result.first['cnt'] as int?) ?? 0;
    await db.update(
      'profiles',
      {
        'rating_avg': avg,
        'rating_count': cnt,
        'updated_at': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [profileId],
    );
  }

  // ── Haversine distance ──

  static double distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * asin(min(1.0, sqrt(a)));
    return earthRadius * c;
  }

  static double _deg2rad(double deg) => deg * pi / 180;

  // Simple UUID generator for local use.
  static String _uuid() {
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${(10000 + (DateTime.now().microsecond % 90000))}';
  }
}
