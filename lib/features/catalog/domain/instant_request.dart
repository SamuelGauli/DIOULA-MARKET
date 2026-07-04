/// Résumé d'une demande instantanée « ouverte » (pour l'accueil).
class InstantRequest {
  const InstantRequest({
    required this.id,
    required this.title,
    required this.productName,
    this.quantity,
    this.unit,
    this.radiusKm = 10,
    this.authorName,
    this.authorCommune,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String productName;
  final double? quantity;
  final String? unit;
  final double radiusKm;
  final String? authorName;
  final String? authorCommune;
  final DateTime? expiresAt;

  factory InstantRequest.fromMap(Map<String, dynamic> map) {
    final author = map['profiles'] as Map<String, dynamic>?;
    return InstantRequest(
      id: map['id'] as String,
      title: map['title'] as String,
      productName: map['product_name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      radiusKm: (map['radius_km'] as num?)?.toDouble() ?? 10,
      authorName: author?['full_name'] as String?,
      authorCommune: author?['commune'] as String?,
      expiresAt: map['expires_at'] == null
          ? null
          : DateTime.tryParse(map['expires_at'] as String),
    );
  }
}
