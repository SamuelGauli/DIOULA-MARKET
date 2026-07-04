import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../tutorial/presentation/tutorial_provider.dart';
import '../data/auth_repository.dart';
import 'guest_provider.dart';
import 'otp_controller.dart';

/// Résultat simple d'une action d'authentification.
class AuthResult {
  const AuthResult({required this.success, this.hasSession = false, this.message});
  final bool success;
  final bool hasSession; // une session est-elle ouverte ? (sinon : confirmer email)
  final String? message;
}

/// Orchestre l'authentification + déclenche la 2FA simulée.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Connexion email + mot de passe. En cas de succès, arme la 2FA.
  Future<AuthResult> signIn(String email, String password) async {
    state = const AsyncLoading();
    // 2FA active pour TOUTES les connexions (démo comprise) : on l'arme AVANT
    // l'appel, car l'événement d'auth déclenche la redirection du router, qui
    // doit déjà voir otpPending = true (sinon il filerait à l'accueil).
    ref.read(otpPendingProvider.notifier).set(true);
    try {
      final res = await _repo.signIn(email: email, password: password);
      state = const AsyncData(null);
      if (res.session != null) {
        ref.read(otpControllerProvider.notifier).generate();
        return const AuthResult(success: true, hasSession: true);
      }
      ref.read(otpPendingProvider.notifier).set(false);
      return const AuthResult(success: true, hasSession: false);
    } catch (e) {
      ref.read(otpPendingProvider.notifier).set(false);
      state = AsyncError(e, StackTrace.current);
      return AuthResult(success: false, message: _humanize(e));
    }
  }

  /// Inscription. Le profil (rôle) est créé par le trigger SQL côté Supabase.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    state = const AsyncLoading();
    ref.read(otpPendingProvider.notifier).set(true);
    try {
      final res = await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      state = const AsyncData(null);
      if (res.session != null) {
        // Inscription réussie avec session : on arme le tutoriel du rôle.
        ref
            .read(pendingTutorialProvider.notifier)
            .set(UserRole.fromValue(role));
        ref.read(otpControllerProvider.notifier).generate();
        return const AuthResult(success: true, hasSession: true);
      }
      // Pas de session => confirmation d'email activée côté Supabase.
      ref.read(otpPendingProvider.notifier).set(false);
      return const AuthResult(
        success: true,
        hasSession: false,
        message: 'Compte créé. Vérifie ton email pour confirmer, puis connecte-toi.',
      );
    } catch (e) {
      ref.read(otpPendingProvider.notifier).set(false);
      state = AsyncError(e, StackTrace.current);
      return AuthResult(success: false, message: _humanize(e));
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    ref.read(otpPendingProvider.notifier).set(false);
    ref.read(otpControllerProvider.notifier).clear();
    ref.read(pendingTutorialProvider.notifier).set(null);
    // On quitte aussi le mode visiteur → retour à l'écran d'accueil.
    ref.read(guestModeProvider.notifier).set(false);
  }

  String _humanize(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login')) return 'Email ou mot de passe incorrect.';
    if (msg.contains('already registered') || msg.contains('user already')) {
      return 'Cet email est déjà utilisé.';
    }
    if (msg.contains('password')) {
      return 'Mot de passe trop court (6 caractères minimum).';
    }
    return 'Une erreur est survenue. Réessaie.';
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
