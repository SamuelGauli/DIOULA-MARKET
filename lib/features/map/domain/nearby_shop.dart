/// Boutique proche renvoyée par la fonction SQL `nearby_shops(lat, lng, radius)`.
///
/// Contrairement au modèle [Shop] complet, on ne garde ici que ce dont la carte
/// a besoin : position, note et **distance déjà calculée côté serveur**
/// (formule de Haversine `distance_km`, triée par distance croissante).
class NearbyShop {
  const NearbyShop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.commune,
    this.ratingAvg = 0,
    this.distanceKm = 0,
  });

  final String id;
  final String name;
  final String? commune;
  final double latitude;
  final double longitude;
  final double ratingAvg;
  final double distanceKm;

  /// Construit depuis une ligne renvoyée par le RPC `nearby_shops`.
  factory NearbyShop.fromMap(Map<String, dynamic> map) {
    return NearbyShop(
      id: map['id'] as String,
      name: map['name'] as String,
      commune: map['commune'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      ratingAvg: (map['rating_avg'] as num?)?.toDouble() ?? 0,
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Distance lisible : « 850 m » sous 1 km, sinon « 1,2 km ».
  String get distanceLabel {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}
