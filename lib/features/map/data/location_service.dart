import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Erreur lisible de géolocalisation (service coupé / permission refusée).
/// Le message est affichable tel quel à l'utilisateur.
class LocationFailure implements Exception {
  const LocationFailure(this.message, {this.permanentlyDenied = false});

  final String message;

  /// `true` si la permission est refusée **définitivement** : seul un passage
  /// par les réglages système peut la réactiver.
  final bool permanentlyDenied;

  @override
  String toString() => message;
}

/// Service de localisation **réelle** (GPS) basé sur `geolocator`.
class LocationService {
  /// Renvoie la position actuelle de l'appareil, ou lève une [LocationFailure]
  /// avec un message clair si ce n'est pas possible.
  Future<LatLng> current() async {
    // 1) Le service de localisation de l'appareil est-il activé ?
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationFailure(
        'La localisation de ton appareil est désactivée. '
        'Active-la puis réessaie.',
      );
    }

    // 2) Permission accordée (sinon on la demande) ?
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Autorisation de localisation refusée. '
        'Réactive-la dans les réglages pour voir les boutiques proches.',
        permanentlyDenied: true,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Autorisation de localisation refusée. '
        'Elle est nécessaire pour afficher la carte.',
      );
    }

    // 3) Récupère la position courante (avec délai max pour ne pas rester
    //    bloqué indéfiniment si le navigateur/l'OS ne répond pas).
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } on LocationFailure {
      rethrow;
    } catch (e) {
      throw LocationFailure(
        'Impossible de récupérer ta position. Vérifie l\'autorisation de '
        'localisation du navigateur, puis réessaie.',
      );
    }
  }

  /// Ouvre les réglages de l'application (pour réactiver la permission).
  Future<void> openSettings() => Geolocator.openAppSettings();
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
