import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../theme/theme_provider.dart';

// ── Simulated session (remplace Supabase Session) ──

/// Session locale (un simple utilisateur connecté).
class LocalSession {
  const LocalSession({required this.userId, required this.email});
  final String userId;
  final String email;
}

// ── Auth State ──

enum AuthEventType { signedIn, signedOut, tokenRefreshed }

class AuthEvent {
  const AuthEvent(this.type, {this.session});
  final AuthEventType type;
  final LocalSession? session;
}

// ── Local Auth Service ──

/// Service d'authentification locale (remplace Supabase Auth).
class LocalAuthService {
  LocalAuthService(this._db, this._prefs);

  final AppDatabase _db;
  final SharedPreferences _prefs;

  static const _kSessionUserId = 'session_user_id';
  static const _kSessionEmail = 'session_email';

  final _authController = StreamController<AuthEvent>.broadcast();

  /// Flux d'événements d'auth (remplace `onAuthStateChange`).
  Stream<AuthEvent> get onAuthStateChange => _authController.stream;

  /// Session courante (remplace `currentSession`).
  LocalSession? get currentSession {
    final userId = _prefs.getString(_kSessionUserId);
    final email = _prefs.getString(_kSessionEmail);
    if (userId == null || email == null) return null;
    return LocalSession(userId: userId, email: email);
  }

  /// ID de l'utilisateur courant (remplace `currentUser?.id`).
  String? get currentUserId => currentSession?.userId;

  /// Email de l'utilisateur courant (remplace `currentUser?.email`).
  String? get currentUserEmail => currentSession?.email;

  // ── Connexion ──

  Future<LocalSession> signIn({
    required String email,
    required String password,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.trim().toLowerCase(), password],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception('Email ou mot de passe incorrect.');
    }

    final user = rows.first;
    final userId = user['id'] as String;
    final userEmail = user['email'] as String;

    await _prefs.setString(_kSessionUserId, userId);
    await _prefs.setString(_kSessionEmail, userEmail);

    final session = LocalSession(userId: userId, email: userEmail);
    _authController.add(AuthEvent(AuthEventType.signedIn, session: session));
    return session;
  }

  // ── Inscription ──

  Future<LocalSession> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    final db = await _db.database;

    // Vérifier que l'email n'existe pas déjà.
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw Exception('Cet email est déjà utilisé.');
    }

    // Générer un ID unique.
    final userId = 'user_${DateTime.now().microsecondsSinceEpoch}';

    // Insérer l'utilisateur.
    await db.insert('users', {
      'id': userId,
      'email': email.trim().toLowerCase(),
      'password_hash': password,
    });

    // Insérer le profil (remplace le trigger SQL handle_new_user).
    await db.insert('profiles', {
      'id': userId,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Connecter automatiquement.
    await _prefs.setString(_kSessionUserId, userId);
    await _prefs.setString(_kSessionEmail, email.trim().toLowerCase());

    final session = LocalSession(
      userId: userId,
      email: email.trim().toLowerCase(),
    );
    _authController.add(AuthEvent(AuthEventType.signedIn, session: session));
    return session;
  }

  // ── Déconnexion ──

  Future<void> signOut() async {
    await _prefs.remove(_kSessionUserId);
    await _prefs.remove(_kSessionEmail);
    _authController.add(AuthEvent(AuthEventType.signedOut));
  }

  void dispose() {
    _authController.close();
  }
}

// ── Providers ──

/// Provider de la base de données SQLite.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// Provider du service d'auth local.
final localAuthProvider = Provider<LocalAuthService>((ref) {
  final db = ref.watch(databaseProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalAuthService(db, prefs);
});

/// Flux de l'état d'authentification (remplace `authStateProvider` Supabase).
final authStateProvider = StreamProvider<AuthEvent>((ref) async* {
  final auth = ref.watch(localAuthProvider);

  // Émettre immédiatement l'état initial (déverrouille tous les providers).
  final session = auth.currentSession;
  yield session != null
      ? AuthEvent(AuthEventType.signedIn, session: session)
      : AuthEvent(AuthEventType.signedOut);

  // Transmettre les événements suivants (signIn, signOut…).
  yield* auth.onAuthStateChange;
});

/// Session courante (remplace `currentSessionProvider` Supabase).
final currentSessionProvider = Provider<LocalSession?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(localAuthProvider).currentSession;
});

/// ID de l'utilisateur courant (raccourci).
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.userId;
});
