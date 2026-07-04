import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._db);
  final AppDatabase _db;

  final _controller = StreamController<List<AppNotification>>.broadcast();

  Stream<List<AppNotification>> watchMine(String userId) {
    _refresh(userId);
    return _controller.stream;
  }

  Future<void> _refresh(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    final list = rows.map((r) {
      return AppNotification(
        id: r['id'] as String,
        type: r['type'] as String? ?? 'info',
        title: r['title'] as String? ?? '',
        body: r['body'] as String?,
        isRead: (r['is_read'] as int? ?? 0) == 1,
        createdAt: r['created_at'] == null
            ? null
            : DateTime.tryParse(r['created_at'] as String),
      );
    }).toList();
    if (!_controller.isClosed) _controller.add(list);
  }

  Future<void> markAllRead(String userId) async {
    final db = await _db.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );
    await _refresh(userId);
  }

  void dispose() => _controller.close();
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationsRepository(db);
});

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(const []);
  final repo = ref.watch(notificationsRepositoryProvider);
  ref.onDispose(() => repo.dispose());
  return repo.watchMine(uid);
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final list = ref.watch(notificationsStreamProvider).value ?? const [];
  return list.where((n) => !n.isRead).length;
});
