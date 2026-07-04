/// Notification in-app (table `notifications`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.isRead,
    this.body,
    this.createdAt,
  });

  final String id;
  final String type; // offre / reservation / stock / info
  final String title;
  final bool isRead;
  final String? body;
  final DateTime? createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: map['type'] as String? ?? 'info',
      title: map['title'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      body: map['body'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }
}
