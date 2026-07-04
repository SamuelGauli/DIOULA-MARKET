import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/shop.dart';

/// Accès aux boutiques dans Supabase (table `shops`).
class ShopRepository {
  ShopRepository(this._client);
  final SupabaseClient _client;

  /// Récupère la boutique du propriétaire (la 1ʳᵉ s'il en a plusieurs).
  /// Renvoie `null` s'il n'en a pas encore.
  Future<Shop?> fetchByOwner(String ownerId) async {
    final data = await _client
        .from('shops')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at')
        .limit(1)
        .maybeSingle();
    return data == null ? null : Shop.fromMap(data);
  }

  /// Crée une boutique et renvoie la version enregistrée (avec id généré).
  Future<Shop> create(Shop shop) async {
    final data =
        await _client.from('shops').insert(shop.toWriteMap()).select().single();
    return Shop.fromMap(data);
  }

  /// Met à jour une boutique existante.
  Future<Shop> update(Shop shop) async {
    final data = await _client
        .from('shops')
        .update(shop.toWriteMap())
        .eq('id', shop.id)
        .select()
        .single();
    return Shop.fromMap(data);
  }

  /// Téléverse une image de boutique (bucket public `shop-images`, dossier = uid).
  /// [kind] = 'logo' ou 'banner'. Renvoie l'URL publique (logo_url / banner_url).
  Future<String> uploadShopImage({
    required String kind,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${kind}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('shop-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    return _client.storage.from('shop-images').getPublicUrl(path);
  }
}

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.watch(supabaseProvider));
});

/// Boutique de l'utilisateur connecté (null s'il n'en a pas).
/// On l'invalide après création/édition pour rafraîchir l'écran.
final myShopProvider = FutureProvider<Shop?>((ref) async {
  ref.watch(authStateProvider);
  final uid = ref.watch(supabaseProvider).auth.currentUser?.id;
  if (uid == null) return null;
  return ref.watch(shopRepositoryProvider).fetchByOwner(uid);
});
