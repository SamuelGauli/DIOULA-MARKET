/// Une entrée du journal d'activité (table `activity_log`) : une action
/// effectuée par l'utilisateur (demande, offre, réservation, commande, avis…).
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.action,
    required this.detail,
    this.entity,
    this.entityId,
    this.createdAt,
  });

  final String id;
  final String action; // code machine (order_created, review_posted, …)
  final String detail; // libellé lisible
  final String? entity; // order / reservation / offer / review / request
  final String? entityId;
  final DateTime? createdAt;

  factory ActivityEntry.fromMap(Map<String, dynamic> map) {
    return ActivityEntry(
      id: map['id'] as String,
      action: map['action'] as String? ?? '',
      detail: map['detail'] as String? ?? 'Action',
      entity: map['entity'] as String?,
      entityId: map['entity_id'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }
}
