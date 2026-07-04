import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indique qu'une vérification 2FA est en attente (juste après login/inscription).
/// Le router redirige vers l'écran OTP tant que ce flag est vrai.
class OtpPending extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final otpPendingProvider =
    NotifierProvider<OtpPending, bool>(OtpPending.new);

/// 2FA SMS **simulée** : on génère un code à 6 chiffres et on l'affiche à
/// l'écran / dans les logs au lieu d'envoyer un vrai SMS. On branchera un
/// vrai provider SMS plus tard.
class OtpController extends Notifier<String?> {
  @override
  String? build() => null;

  /// Génère un nouveau code à 6 chiffres et le « envoie » (affichage/log).
  String generate() {
    final code = (Random().nextInt(900000) + 100000).toString();
    state = code;
    debugPrint('🔐 [2FA simulée] Code envoyé par SMS : $code');
    return code;
  }

  /// Vérifie le code saisi.
  bool verify(String input) => state != null && input.trim() == state;

  void clear() => state = null;
}

final otpControllerProvider =
    NotifierProvider<OtpController, String?>(OtpController.new);
