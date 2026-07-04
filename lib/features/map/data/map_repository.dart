import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/nearby_shop.dart';
import 'location_service.dart';

/// Rayon « Tout voir » : assez grand pour renvoyer toutes les boutiques
/// géolocalisées, où que la démo soit lancée (filet de sécurité soutenance).
const double kShowAllRadiusKm = 20000;

/// Accès aux boutiques proches via la fonction SQL `nearby_shops`
/// (Haversine côté serveur, déjà triée par distance croissante).
class MapRepository {
  MapRepository(this._client);
  final SupabaseClient _client;

  Future<List<NearbyShop>> fetchNearby(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    final data = await _client.rpc('nearby_shops', params: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    });
    return (data as List)
        .map((e) => NearbyShop.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(ref.watch(supabaseProvider));
});

/// Position GPS courante de l'appareil.
/// Relancée par `ref.invalidate(currentPositionProvider)` (bouton « Réessayer »).
final currentPositionProvider = FutureProvider<LatLng>((ref) {
  return ref.watch(locationServiceProvider).current();
});

/// Rayon de recherche sélectionné (km). Modifié par les chips de l'écran carte ;
/// « Tout voir » le pousse à [kShowAllRadiusKm].
class SelectedRadius extends Notifier<double> {
  @override
  double build() => 10;

  void set(double value) => state = value;
}

final selectedRadiusProvider =
    NotifierProvider<SelectedRadius, double>(SelectedRadius.new);

/// Boutiques proches : dépend de la position GPS **et** du rayon choisi.
final nearbyShopsProvider = FutureProvider<List<NearbyShop>>((ref) async {
  final pos = await ref.watch(currentPositionProvider.future);
  final radius = ref.watch(selectedRadiusProvider);
  return ref
      .watch(mapRepositoryProvider)
      .fetchNearby(pos.latitude, pos.longitude, radius);
});
