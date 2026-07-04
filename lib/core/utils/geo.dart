import 'dart:math' as math;

/// Distance en **kilomètres** entre deux points GPS (formule de Haversine).
///
/// Miroir Dart de la fonction SQL `distance_km(...)` : sert à **trier côté
/// client** les produits/boutiques par proximité sans requête serveur.
/// Ex. : `distanceKm(5.35, -4.00, 5.36, -3.99)` ≈ 1.5 km.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  double toRad(double deg) => deg * math.pi / 180.0;

  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRad(lat1)) *
          math.cos(toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.asin(math.min(1.0, math.sqrt(a)));
  return earthRadiusKm * c;
}
