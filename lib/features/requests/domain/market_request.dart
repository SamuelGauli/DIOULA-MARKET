import '../../../core/constants/app_constants.dart';

/// Demande instantanée complète (table `requests`).
class MarketRequest {
  const MarketRequest({
    required this.id,
    required this.consumerId,
    required this.title,
    required this.productName,
    required this.status,
    this.quantity,
    this.unit,
    this.description,
    this.radiusKm = 10,
    this.latitude,
    this.longitude,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String consumerId;
  final String title;
  final String productName;
  final String status; // ouverte / pourvue / expiree / annulee
  final double? quantity;
  final String? unit;
  final String? description;
  final double radiusKm;
  final double? latitude;
  final double? longitude;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  bool get isOpen => status == 'ouverte';

  RequestStatus get statusEnum => RequestStatus.values.firstWhere(
        (s) => s.value == status,
        orElse: () => RequestStatus.ouverte,
      );

  factory MarketRequest.fromMap(Map<String, dynamic> map) {
    return MarketRequest(
      id: map['id'] as String,
      consumerId: map['consumer_id'] as String,
      title: map['title'] as String? ?? '',
      productName: map['product_name'] as String? ?? '',
      status: map['status'] as String? ?? 'ouverte',
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      description: map['description'] as String?,
      radiusKm: (map['radius_km'] as num?)?.toDouble() ?? 10,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      expiresAt: map['expires_at'] == null
          ? null
          : DateTime.tryParse(map['expires_at'] as String),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }
}
