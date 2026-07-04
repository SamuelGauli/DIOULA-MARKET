import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/profile.dart';

/// Accès aux profils dans Supabase (table `profiles`).
class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  static const _kycBucket = 'kyc-docs';

  /// Récupère un profil par son id (= id de l'utilisateur auth).
  Future<Profile?> fetch(String id) async {
    final data =
        await _client.from('profiles').select().eq('id', id).maybeSingle();
    return data == null ? null : Profile.fromMap(data);
  }

  /// Met à jour les champs modifiables du profil.
  Future<void> update(Profile profile) async {
    await _client.from('profiles').update(profile.toMap()).eq('id', profile.id);
  }

  /// Téléverse une **photo de profil** (bucket public `avatars`, dossier = uid)
  /// et renvoie son URL publique (à stocker dans `profiles.avatar_url`).
  Future<String> uploadAvatar({
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  // ---- KYC (vérification d'identité) ----

  /// Téléverse un document KYC dans le bucket privé (dossier = uid).
  /// [kind] = 'id' ou 'residence'. Renvoie le chemin stocké.
  Future<String> uploadKycDoc({
    required Uint8List bytes,
    required String kind,
    String contentType = 'image/jpeg',
  }) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${kind}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from(_kycBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    return path;
  }

  /// Soumet les 2 pièces (pro) → passe le profil "en vérification".
  Future<void> submitKyc(String idPath, String residencePath) =>
      _client.rpc('submit_kyc',
          params: {'p_id_path': idPath, 'p_residence_path': residencePath});

  /// Soumet la CNI seule (consommateur) → "en vérification".
  Future<void> submitCni(String idPath) =>
      _client.rpc('submit_cni', params: {'p_id_path': idPath});

  /// Validation simulée (en prod : revue admin / fournisseur KYC).
  Future<void> simulateVerifyKyc() => _client.rpc('simulate_verify_kyc');
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});

/// Profil de l'utilisateur connecté (null si déconnecté).
/// Se rafraîchit à chaque changement d'état d'authentification.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider);
  final uid = ref.watch(supabaseProvider).auth.currentUser?.id;
  if (uid == null) return null;
  return ref.watch(profileRepositoryProvider).fetch(uid);
});
