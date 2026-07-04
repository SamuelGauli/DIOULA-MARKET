import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';

/// Mode visiteur : l'utilisateur explore l'app sans compte.
/// Activé depuis l'écran d'accueil (« Continuer en visiteur »).
class GuestMode extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final guestModeProvider = NotifierProvider<GuestMode, bool>(GuestMode.new);

/// Vrai si on est dans l'app SANS session (= visiteur).
/// Sert à verrouiller les actions réservées aux comptes (boutique, profil…).
final isGuestProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  final hasSession =
      ref.watch(supabaseProvider).auth.currentSession != null;
  return !hasSession && ref.watch(guestModeProvider);
});
