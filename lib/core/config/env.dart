import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Accès centralisé aux variables d'environnement (fichier `.env`).
///
/// Le fichier `.env` n'est jamais commité (voir `.gitignore`). On y met
/// uniquement l'URL Supabase et la clé **anon** (publique, safe côté client).
/// La clé `service_role` NE DOIT JAMAIS être mise ici ni dans l'app.
class Env {
  Env._();

  static String _get(String key) =>
      dotenv.isInitialized ? (dotenv.env[key] ?? '') : '';

  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');

  /// Vrai si les clés Supabase sont présentes et plausibles.
  /// Permet de lancer l'app pour la démo même si Supabase n'est pas encore
  /// configuré (on n'initialise simplement pas le client).
  static bool get isConfigured =>
      supabaseUrl.startsWith('http') && supabaseAnonKey.isNotEmpty;
}
