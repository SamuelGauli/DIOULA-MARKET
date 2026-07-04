import 'package:sqflite/sqflite.dart';

/// Données de démonstration pré-chargées au premier lancement.
/// Remplace `supabase/seed.sql` + `step22.sql` (admin).
class SeedData {
  SeedData._();

  static Future<void> seed(Database db) async {
    await _seedUsers(db);
    await _seedProfiles(db);
    await _seedShops(db);
    await _seedProducts(db);
    await _seedReviews(db);
    await _seedRequests(db);
    await _seedDemoOrders(db);
  }

  // ── IDs fixes pour la cohérence des FK ──
  static const _uidSamira = '00000000-0000-0000-0000-000000000001';
  static const _uidRaoul = '00000000-0000-0000-0000-000000000002';
  static const _uidJacob = '00000000-0000-0000-0000-000000000003';
  static const _uidKader = '00000000-0000-0000-0000-000000000004';
  static const _uidAnais = '00000000-0000-0000-0000-000000000005';
  static const _uidAdmin = '00000000-0000-0000-0000-000000000006';

  static const _shopBrou = '10000000-0000-0000-0000-000000000001';
  static const _shopFatim = '10000000-0000-0000-0000-000000000002';
  static const _shopKouame = '10000000-0000-0000-0000-000000000003';

  static Future<void> _seedUsers(Database db) async {
    // Mot de passe "demo1234" en clair pour la démo locale (pas de hash sécurisé nécessaire).
    const passwordHash = 'demo1234';
    final now = DateTime.now().toIso8601String();

    for (final entry in {
      _uidSamira: 'samira@demo.ci',
      _uidRaoul: 'raoul@demo.ci',
      _uidJacob: 'jacob@demo.ci',
      _uidKader: 'kader@demo.ci',
      _uidAnais: 'anais@demo.ci',
      _uidAdmin: 'admin@demo.ci',
    }.entries) {
      await db.insert('users', {
        'id': entry.key,
        'email': entry.value,
        'password_hash': passwordHash,
        'created_at': now,
      });
    }
  }

  static Future<void> _seedProfiles(Database db) async {
    final now = DateTime.now().toIso8601String();

    final profiles = <Map<String, dynamic>>[
      {
        'id': _uidSamira, 'full_name': 'Traoré Samira', 'phone': '0707000001',
        'role': 'consommateur', 'commune': 'Cocody',
        'latitude': 5.3599, 'longitude': -3.9876,
        'avatar_url': 'https://i.pravatar.cc/150?img=47',
        'created_at': now, 'updated_at': now,
      },
      {
        'id': _uidRaoul, 'full_name': 'Brou Raoul', 'phone': '0707000002',
        'role': 'commercant', 'commune': 'Adjamé',
        'latitude': 5.3604, 'longitude': -4.0241,
        'avatar_url': 'https://i.pravatar.cc/150?img=12',
        'created_at': now, 'updated_at': now,
      },
      {
        'id': _uidJacob, 'full_name': 'Kouamé Jacob', 'phone': '0707000003',
        'role': 'producteur', 'commune': 'Agboville',
        'latitude': 5.9280, 'longitude': -4.2130,
        'avatar_url': 'https://i.pravatar.cc/150?img=33',
        'created_at': now, 'updated_at': now,
      },
      {
        'id': _uidKader, 'full_name': 'Yameogo Kader', 'phone': '0707000004',
        'role': 'livreur', 'commune': 'Yopougon',
        'latitude': 5.3450, 'longitude': -4.0890,
        'avatar_url': 'https://i.pravatar.cc/150?img=15',
        'created_at': now, 'updated_at': now,
      },
      {
        'id': _uidAnais, 'full_name': 'Coulibaly Anaïs', 'phone': '0707000005',
        'role': 'commercant', 'commune': 'Treichville',
        'latitude': 5.2920, 'longitude': -4.0050,
        'avatar_url': 'https://i.pravatar.cc/150?img=5',
        'created_at': now, 'updated_at': now,
      },
      {
        'id': _uidAdmin, 'full_name': 'Admin Dioula', 'phone': '0707000006',
        'role': 'admin', 'commune': 'Plateau',
        'created_at': now, 'updated_at': now,
      },
    ];

    for (final p in profiles) {
      await db.insert('profiles', p);
    }
  }

  static Future<void> _seedShops(Database db) async {
    final now = DateTime.now().toIso8601String();

    final shops = <Map<String, dynamic>>[
      {
        'id': _shopBrou, 'owner_id': _uidRaoul, 'name': 'Chez Brou',
        'description': 'Épicerie & vivriers frais au marché Gouro.',
        'category': 'Épicerie', 'commune': 'Adjamé',
        'address': 'Marché Gouro, Adjamé', 'phone': '0707000002',
        'latitude': 5.3604, 'longitude': -4.0241,
        'rating_avg': 4.6, 'rating_count': 23,
        'created_at': now, 'updated_at': now,
      },
      {
        'id': _shopFatim, 'owner_id': _uidAnais, 'name': 'Maquis Fatim',
        'description': 'Plats préparés ivoiriens : alloco, attiéké, garba.',
        'category': 'Plats préparés', 'commune': 'Treichville',
        'address': 'Rue 12, Treichville', 'phone': '0707000005',
        'latitude': 5.2920, 'longitude': -4.0050,
        'rating_avg': 4.8, 'rating_count': 41,
        'created_at': now, 'updated_at': now,
      },
      {
        'id': _shopKouame, 'owner_id': _uidJacob, 'name': 'Ferme Kouamé',
        'description': 'Production locale : céréales, tubercules et légumes frais.',
        'category': 'Producteur', 'commune': 'Agboville',
        'address': 'Route d\'Agboville', 'phone': '0707000003',
        'latitude': 5.9280, 'longitude': -4.2130,
        'rating_avg': 4.7, 'rating_count': 12,
        'created_at': now, 'updated_at': now,
      },
    ];

    for (final s in shops) {
      await db.insert('shops', s);
    }
  }

  static Future<void> _seedProducts(Database db) async {
    final now = DateTime.now().toIso8601String();

    final products = <Map<String, dynamic>>[
      // Ferme Kouamé
      {'shop_id': _shopKouame, 'name': 'Maïs en grain', 'description': 'Maïs séché local, sac de 50 kg.', 'category': 'Céréales & graines', 'unit': 'sac', 'price': 18000.0, 'stock': 25.0, 'image_url': 'https://picsum.photos/seed/mais/600/400', 'sale_mode': 'gros'},
      {'shop_id': _shopKouame, 'name': 'Riz local', 'description': 'Riz blanc de Côte d\'Ivoire.', 'category': 'Céréales & graines', 'unit': 'sac', 'price': 22000.0, 'stock': 18.0, 'image_url': 'https://picsum.photos/seed/riz/600/400', 'sale_mode': 'gros'},
      {'shop_id': _shopKouame, 'name': 'Semences potagères', 'description': 'Lot de semences (tomate, piment, gombo).', 'category': 'Céréales & graines', 'unit': 'sachet', 'price': 1500.0, 'stock': 60.0, 'image_url': 'https://picsum.photos/seed/semences/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopKouame, 'name': 'Igname', 'description': 'Igname fraîche (variété Kponan).', 'category': 'Féculents', 'unit': 'tas', 'price': 3000.0, 'stock': 40.0, 'image_url': 'https://picsum.photos/seed/igname/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopKouame, 'name': 'Manioc', 'description': 'Manioc frais, récolté du jour.', 'category': 'Féculents', 'unit': 'tas', 'price': 2000.0, 'stock': 35.0, 'image_url': 'https://picsum.photos/seed/manioc/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopKouame, 'name': 'Banane plantain', 'description': 'Régime de plantain bien mûr.', 'category': 'Féculents', 'unit': 'régime', 'price': 4000.0, 'stock': 22.0, 'image_url': 'https://picsum.photos/seed/plantain/600/400', 'sale_mode': 'gros'},
      {'shop_id': _shopKouame, 'name': 'Aubergine gnagnan', 'description': 'Aubergine locale amère (gnagnan).', 'category': 'Légumes', 'unit': 'tas', 'price': 1000.0, 'stock': 50.0, 'image_url': 'https://picsum.photos/seed/gnagnan/600/400', 'sale_mode': 'detail'},
      // Chez Brou
      {'shop_id': _shopBrou, 'name': 'Tomate fraîche', 'description': 'Tomates mûres, idéales pour la sauce.', 'category': 'Légumes', 'unit': 'kg', 'price': 1200.0, 'stock': 30.0, 'image_url': 'https://picsum.photos/seed/tomate/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopBrou, 'name': 'Oignon', 'description': 'Oignon violet, qualité marché.', 'category': 'Légumes', 'unit': 'kg', 'price': 1000.0, 'stock': 45.0, 'image_url': 'https://picsum.photos/seed/oignon/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopBrou, 'name': 'Piment frais', 'description': 'Piment fort local.', 'category': 'Légumes', 'unit': 'kg', 'price': 1500.0, 'stock': 20.0, 'image_url': 'https://picsum.photos/seed/piment/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopBrou, 'name': 'Gombo', 'description': 'Gombo frais pour sauce.', 'category': 'Légumes', 'unit': 'kg', 'price': 1300.0, 'stock': 25.0, 'image_url': 'https://picsum.photos/seed/gombo/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopBrou, 'name': 'Huile rouge', 'description': 'Huile de palme rouge artisanale.', 'category': 'Épicerie', 'unit': 'litre', 'price': 1500.0, 'stock': 40.0, 'image_url': 'https://picsum.photos/seed/huilerouge/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopBrou, 'name': 'Poisson fumé', 'description': 'Poisson fumé (machoiron).', 'category': 'Poissons', 'unit': 'kg', 'price': 3500.0, 'stock': 15.0, 'image_url': 'https://picsum.photos/seed/poissonfume/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopBrou, 'name': 'Poisson frais', 'description': 'Carpe / machoiron du jour.', 'category': 'Poissons', 'unit': 'kg', 'price': 2500.0, 'stock': 18.0, 'image_url': 'https://picsum.photos/seed/poissonfrais/600/400', 'sale_mode': 'detail'},
      // Maquis Fatim
      {'shop_id': _shopFatim, 'name': 'Alloco', 'description': 'Banane plantain frite, portion.', 'category': 'Plats préparés', 'unit': 'portion', 'price': 1000.0, 'stock': 100.0, 'image_url': 'https://picsum.photos/seed/alloco/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopFatim, 'name': 'Attiéké', 'description': 'Boules d\'attiéké (semoule de manioc).', 'category': 'Plats préparés', 'unit': 'portion', 'price': 500.0, 'stock': 100.0, 'image_url': 'https://picsum.photos/seed/attieke/600/400', 'sale_mode': 'detail'},
      {'shop_id': _shopFatim, 'name': 'Garba', 'description': 'Attiéké + thon frit, la portion.', 'category': 'Plats préparés', 'unit': 'portion', 'price': 1500.0, 'stock': 80.0, 'image_url': 'https://picsum.photos/seed/garba/600/400', 'sale_mode': 'detail'},
    ];

    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      await db.insert('products', {
        'id': '20000000-0000-0000-0000-${(i + 1).toString().padLeft(12, '0')}',
        ...p,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  static Future<void> _seedReviews(Database db) async {
    final now = DateTime.now().toIso8601String();

    final reviews = <Map<String, dynamic>>[
      {'author_id': _uidSamira, 'shop_id': _shopBrou, 'rating': 5, 'comment': 'Produits toujours frais, je recommande !'},
      {'author_id': _uidSamira, 'shop_id': _shopFatim, 'rating': 5, 'comment': 'Le meilleur garba de Treichville'},
      {'author_id': _uidJacob, 'shop_id': _shopBrou, 'rating': 4, 'comment': 'Bon accueil au marché Gouro.'},
      {'author_id': _uidKader, 'shop_id': _shopFatim, 'rating': 4, 'comment': 'Service rapide, parfait pour les livraisons.'},
    ];

    for (int i = 0; i < reviews.length; i++) {
      final r = reviews[i];
      await db.insert('reviews', {
        'id': '30000000-0000-0000-0000-${(i + 1).toString().padLeft(12, '0')}',
        ...r,
        'created_at': now,
      });
    }
  }

  static Future<void> _seedRequests(Database db) async {
    final now = DateTime.now().toIso8601String();
    final expires1 = DateTime.now().add(const Duration(days: 2)).toIso8601String();
    final expires2 = DateTime.now().add(const Duration(hours: 6)).toIso8601String();

    final requests = <Map<String, dynamic>>[
      {
        'id': '40000000-0000-0000-0000-000000000001',
        'consumer_id': _uidSamira,
        'title': '20 kg d\'oignons',
        'product_name': 'Oignon',
        'quantity': 20.0,
        'unit': 'kg',
        'radius_km': 10.0,
        'latitude': 5.3599,
        'longitude': -3.9876,
        'status': 'ouverte',
        'expires_at': expires1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': '40000000-0000-0000-0000-000000000002',
        'consumer_id': _uidSamira,
        'title': 'Attiéké pour 10 personnes',
        'product_name': 'Attiéké',
        'quantity': 10.0,
        'unit': 'portion',
        'radius_km': 5.0,
        'latitude': 5.3599,
        'longitude': -3.9876,
        'status': 'ouverte',
        'expires_at': expires2,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final r in requests) {
      await db.insert('requests', r);
    }
  }

  static Future<void> _seedDemoOrders(Database db) async {
    final now = DateTime.now().toIso8601String();

    // 2 commandes de démo pour que le livreur Kader ait des courses disponibles.
    final orderId1 = '50000000-0000-0000-0000-000000000001';
    final orderId2 = '50000000-0000-0000-0000-000000000002';

    await db.insert('orders', {
      'id': orderId1,
      'buyer_id': _uidSamira,
      'shop_id': _shopBrou,
      'status': 'en_cours',
      'total_amount': 12000.0,
      'delivery_address': 'Cocody, Rue des Jardins',
      'delivery_step': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('order_items', {
      'id': '60000000-0000-0000-0000-000000000001', 'order_id': orderId1,
      'product_name': 'Tomate fraîche', 'quantity': 5.0, 'unit_price': 1200.0,
    });
    await db.insert('order_items', {
      'id': '60000000-0000-0000-0000-000000000002', 'order_id': orderId1,
      'product_name': 'Oignon', 'quantity': 6.0, 'unit_price': 1000.0,
    });

    await db.insert('orders', {
      'id': orderId2,
      'buyer_id': _uidSamira,
      'shop_id': _shopFatim,
      'status': 'en_cours',
      'total_amount': 4500.0,
      'delivery_address': 'Cocody, Angré 7e tranche',
      'delivery_step': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('order_items', {
      'id': '60000000-0000-0000-0000-000000000003',
      'order_id': orderId2,
      'product_name': 'Garba',
      'quantity': 3.0,
      'unit_price': 1500.0,
    });
  }
}
