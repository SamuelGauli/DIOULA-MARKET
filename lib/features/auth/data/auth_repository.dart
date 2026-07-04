import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';

/// Résultat simple d'une action d'authentification.
class AuthResponse {
  const AuthResponse({this.session, this.user});
  final dynamic session;
  final dynamic user;
}

/// Encapsule l'authentification locale (email + mot de passe).
class AuthRepository {
  AuthRepository(this._auth);
  final LocalAuthService _auth;

  String? get currentUser => _auth.currentUserId;
  String? get currentEmail => _auth.currentUserEmail;

  /// Inscription.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    final session = await _auth.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: role,
    );
    return AuthResponse(session: session, user: session.userId);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final session = await _auth.signIn(email: email, password: password);
    return AuthResponse(session: session, user: session.userId);
  }

  Future<void> signOut() => _auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(localAuthProvider));
});
