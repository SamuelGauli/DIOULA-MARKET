import '../../../core/constants/app_constants.dart';

/// Modèle d'un profil utilisateur (table `profiles`).
class Profile {
  const Profile({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.commune,
    this.latitude,
    this.longitude,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.verificationStatus = 'non_soumis',
    this.idDocPath,
    this.residenceDocPath,
    this.isActive = true,
    this.banReason,
  });

  final String id;
  final UserRole role;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? commune;
  final double? latitude;
  final double? longitude;
  final double ratingAvg;
  final int ratingCount;

  // KYC (vérification d'identité).
  final String verificationStatus; // non_soumis / en_attente / verifie / refuse
  final String? idDocPath;
  final String? residenceDocPath;

  // Modération (gérés uniquement par l'admin via RPC — absents de toMap).
  final bool isActive; // false = compte suspendu (banni)
  final String? banReason;

  /// Nom affichable (fallback si vide).
  String get displayName =>
      (fullName == null || fullName!.trim().isEmpty) ? 'Utilisateur' : fullName!;

  bool get isVerified => verificationStatus == 'verifie';
  bool get isPendingVerification => verificationStatus == 'en_attente';

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      role: UserRole.fromValue(map['role'] as String?),
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      commune: map['commune'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      ratingAvg: (map['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['rating_count'] as num?)?.toInt() ?? 0,
      verificationStatus:
          map['verification_status'] as String? ?? 'non_soumis',
      idDocPath: map['id_doc_path'] as String?,
      residenceDocPath: map['residence_doc_path'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      banReason: map['ban_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role.value,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'commune': commune,
        'latitude': latitude,
        'longitude': longitude,
        'is_active': isActive ? 1 : 0,
        'ban_reason': banReason,
        'verification_status': verificationStatus,
        'id_doc_path': idDocPath,
        'residence_doc_path': residenceDocPath,
        'rating_avg': ratingAvg,
        'rating_count': ratingCount,
      };
}
