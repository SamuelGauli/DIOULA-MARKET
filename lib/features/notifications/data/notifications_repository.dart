import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/app_notification.dart';

/// Accès aux notifications in-app (temps réel via `.stream()`).
class NotificationsRepository {
  NotificationsRepository(this._client);
  final SupabaseClient _client;

  Stream<List<AppNotification>> watchMine(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(AppNotification.fromMap).toList());
  }

  Future<void> markAllRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseProvider));
});

/// Flux temps réel des notifications de l'utilisateur (vide si visiteur).
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(supabaseProvider).auth.currentUser?.id;
  if (uid == null) return Stream.value(const []);
  return ref.watch(notificationsRepositoryProvider).watchMine(uid);
});

/// Nombre de notifications non lues (pour le badge de la cloche).
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final list = ref.watch(notificationsStreamProvider).value ?? const [];
  return list.where((n) => !n.isRead).length;
});
