/// Modèle d'une boutique virtuelle (table `shops`).
///
/// Une boutique appartient à un utilisateur (`ownerId`, un commerçant ou
/// producteur). Pour ce projet d'école, on considère **une boutique par
/// propriétaire** (le schéma autorise plusieurs, mais on garde simple).
class Shop {
  const Shop({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.category,
    this.logoUrl,
    this.bannerUrl,
    this.address,
    this.commune,
    this.phone,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.ownerVerified = false,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? category;
  final String? logoUrl;
  final String? bannerUrl;
  final String? address;
  final String? commune;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final double ratingAvg;
  final int ratingCount;

  /// Le propriétaire a-t-il une identité vérifiée (KYC) ? (via jointure)
  final bool ownerVerified;

  /// Construit un Shop depuis une ligne Supabase.
  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      logoUrl: map['logo_url'] as String?,
      bannerUrl: map['banner_url'] as String?,
      address: map['address'] as String?,
      commune: map['commune'] as String?,
      phone: map['phone'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isActive: (map['is_active'] as int?) == 1,
      ratingAvg: (map['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['rating_count'] as num?)?.toInt() ?? 0,
      ownerVerified: (map['owner_verified'] as int?) == 1,
    );
  }

  /// Champs modifiables (utilisé pour insert et update).
  /// On n'inclut PAS l'id (généré par la base) ni les notes (calculées).
  Map<String, dynamic> toWriteMap() => {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'category': category,
        'logo_url': logoUrl,
        'banner_url': bannerUrl,
        'address': address,
        'commune': commune,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'is_active': isActive,
      };

  Shop copyWith({
    String? name,
    String? description,
    String? category,
    String? logoUrl,
    String? bannerUrl,
    String? address,
    String? commune,
    String? phone,
    bool? isActive,
  }) {
    return Shop(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      address: address ?? this.address,
      commune: commune ?? this.commune,
      phone: phone ?? this.phone,
      latitude: latitude,
      longitude: longitude,
      isActive: isActive ?? this.isActive,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      ownerVerified: ownerVerified,
    );
  }
}
