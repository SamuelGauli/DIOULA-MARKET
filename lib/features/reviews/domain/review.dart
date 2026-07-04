/// Avis 5 étoiles (table `reviews`). Un avis cible **une boutique** (`shopId`)
/// OU **un utilisateur** (`targetId`), et peut être rattaché à la réservation
/// qui l'a déclenché (`reservationId`). Enrichi de l'auteur via jointure.
class Review {
  const Review({
    required this.id,
    required this.authorId,
    required this.rating,
    this.shopId,
    this.targetId,
    this.reservationId,
    this.comment,
    this.createdAt,
    this.authorName = 'Client',
    this.authorAvatar,
    this.isHidden = false,
  });

  final String id;
  final String authorId;
  final int rating; // 1..5
  final String? shopId;
  final String? targetId;
  final String? reservationId;
  final String? comment;
  final DateTime? createdAt;

  final String authorName;
  final String? authorAvatar;
  final bool isHidden; // masqué par la modération (admin)

  /// Cible-t-il une boutique (sinon : un acheteur) ?
  bool get isForShop => shopId != null;

  factory Review.fromMap(Map<String, dynamic> map) {
    final author = map['author'] as Map<String, dynamic>?;
    return Review(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      rating: (map['rating'] as num).toInt(),
      shopId: map['shop_id'] as String?,
      targetId: map['target_id'] as String?,
      reservationId: map['reservation_id'] as String?,
      comment: map['comment'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      authorName: author?['full_name'] as String? ?? 'Client',
      authorAvatar: author?['avatar_url'] as String?,
      isHidden: (map['is_hidden'] as int?) == 1,
    );
  }
}
