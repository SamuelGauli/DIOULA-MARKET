/// Configuration de l'application.
/// Plus besoin de Supabase ni de .env — tout est local.
class Env {
  Env._();

  /// Toujours "configuré" en mode local.
  static bool get isConfigured => true;
}
