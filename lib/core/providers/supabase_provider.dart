import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client Supabase global (disponible après `Supabase.initialize` dans main).
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Flux de l'état d'authentification (connexion / déconnexion / refresh token).
/// Sera utilisé par le router pour rediriger selon l'état de session.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

/// Session courante (null si déconnecté).
final currentSessionProvider = Provider<Session?>((ref) {
  // On dépend de authStateProvider pour se rafraîchir à chaque changement.
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentSession;
});
