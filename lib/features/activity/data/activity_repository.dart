import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/activity_entry.dart';

/// Accès en lecture au journal d'activité de l'utilisateur courant
/// (table `activity_log`, alimentée par des triggers SQL — `step11.sql`).
class ActivityRepository {
  ActivityRepository(this._client);
  final SupabaseClient _client;

  Future<List<ActivityEntry>> fetchMine() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client
        .from('activity_log')
        .select()
        .eq('actor_id', uid)
        .order('created_at', ascending: false)
        .limit(100);
    return (data as List)
        .map((e) => ActivityEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(supabaseProvider));
});

/// Historique des actions de l'utilisateur connecté.
final myActivityProvider =
    FutureProvider.autoDispose<List<ActivityEntry>>((ref) {
  return ref.watch(activityRepositoryProvider).fetchMine();
});
