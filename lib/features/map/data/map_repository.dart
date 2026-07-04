import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/nearby_shop.dart';
import 'location_service.dart';

const double kShowAllRadiusKm = 20000;

class MapRepository {
  MapRepository(this._db);
  final AppDatabase _db;

  Future<List<NearbyShop>> fetchNearby(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    final db = await _db.database;

    final rows = await db.query(
      'shops',
      where: 'is_active = 1 AND latitude IS NOT NULL AND longitude IS NOT NULL',
    );

    final results = <NearbyShop>[];

    for (final row in rows) {
      final shopLat = (row['latitude'] as num).toDouble();
      final shopLng = (row['longitude'] as num).toDouble();
      final dist = AppDatabase.distanceKm(lat, lng, shopLat, shopLng);

      if (dist <= radiusKm) {
        results.add(NearbyShop(
          id: row['id'] as String,
          name: row['name'] as String,
          commune: row['commune'] as String?,
          latitude: shopLat,
          longitude: shopLng,
          ratingAvg: (row['rating_avg'] as num?)?.toDouble() ?? 0,
          distanceKm: dist,
        ));
      }
    }

    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }
}

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(ref.watch(databaseProvider));
});

final currentPositionProvider = FutureProvider<LatLng>((ref) {
  return ref.watch(locationServiceProvider).current();
});

class SelectedRadius extends Notifier<double> {
  @override
  double build() => 10;

  void set(double value) => state = value;
}

final selectedRadiusProvider =
    NotifierProvider<SelectedRadius, double>(SelectedRadius.new);

final nearbyShopsProvider = FutureProvider<List<NearbyShop>>((ref) async {
  final pos = await ref.watch(currentPositionProvider.future);
  final radius = ref.watch(selectedRadiusProvider);
  return ref
      .watch(mapRepositoryProvider)
      .fetchNearby(pos.latitude, pos.longitude, radius);
});
