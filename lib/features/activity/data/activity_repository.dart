import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/activity_entry.dart';

/// Accès en lecture au journal d'activité de l'utilisateur courant
/// (table `activity_log`, alimentée par des triggers SQL — `step11.sql`).
class ActivityRepository {
  ActivityRepository(this._db, this._auth);
  final AppDatabase _db;
  final LocalAuthService _auth;

  Future<List<ActivityEntry>> fetchMine() async {
    final uid = _auth.currentUserId;
    if (uid == null) return [];
    final db = await _db.database;
    final data = await db.query(
      'activity_log',
      where: 'actor_id = ?',
      whereArgs: [uid],
      orderBy: 'created_at DESC',
      limit: 100,
    );
    return data
        .map((e) => ActivityEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(
    ref.watch(databaseProvider),
    ref.watch(localAuthProvider),
  );
});

/// Historique des actions de l'utilisateur connecté.
final myActivityProvider =
    FutureProvider.autoDispose<List<ActivityEntry>>((ref) {
  return ref.watch(activityRepositoryProvider).fetchMine();
});
