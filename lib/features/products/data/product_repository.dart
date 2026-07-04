import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/product.dart';

/// Accès aux produits dans Supabase (table `products`).
class ProductRepository {
  ProductRepository(this._client);
  final SupabaseClient _client;

  /// Tous les produits d'une boutique (récents en premier).
  Future<List<Product>> fetchByShop(String shopId) async {
    final data = await _client
        .from('products')
        .select()
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Product.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> create(Product product) async {
    final data = await _client
        .from('products')
        .insert(product.toWriteMap())
        .select()
        .single();
    return Product.fromMap(data);
  }

  Future<Product> update(Product product) async {
    final data = await _client
        .from('products')
        .update(product.toWriteMap())
        .eq('id', product.id)
        .select()
        .single();
    return Product.fromMap(data);
  }

  Future<void> delete(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  /// Met (ou retire, si `null`) un prix promo sur un produit (anti-gaspillage).
  Future<void> setPromo(String id, double? promoPrice) async {
    await _client
        .from('products')
        .update({'promo_price': promoPrice}).eq('id', id);
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(supabaseProvider));
});

/// Liste des produits d'une boutique donnée (paramètre = shopId).
/// On l'invalide après ajout/édition/suppression pour rafraîchir.
final productsByShopProvider =
    FutureProvider.family<List<Product>, String>((ref, shopId) async {
  return ref.watch(productRepositoryProvider).fetchByShop(shopId);
});
