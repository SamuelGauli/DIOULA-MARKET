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
  final bool hasSession;
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

  /// Inscription. Le profil (rôle) est créé dans la base locale.
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
        ref
            .read(pendingTutorialProvider.notifier)
            .set(UserRole.fromValue(role));
        ref.read(otpControllerProvider.notifier).generate();
        return const AuthResult(success: true, hasSession: true);
      }
      ref.read(otpPendingProvider.notifier).set(false);
      return const AuthResult(
        success: true,
        hasSession: false,
        message: 'Compte créé. Connecte-toi.',
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
    ref.read(guestModeProvider.notifier).set(false);
  }

  String _humanize(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('incorrect')) return 'Email ou mot de passe incorrect.';
    if (msg.contains('déjà utilisé') || msg.contains('already')) {
      return 'Cet email est déjà utilisé.';
    }
    if (msg.contains('password') || msg.contains('court')) {
      return 'Mot de passe trop court (6 caractères minimum).';
    }
    return 'Une erreur est survenue. Réessaie.';
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
