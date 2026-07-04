import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';

/// Rôle pour lequel un tutoriel doit être affiché (défini après inscription).
/// `null` = pas de tutoriel en attente (ex: simple connexion).
class PendingTutorial extends Notifier<UserRole?> {
  @override
  UserRole? build() => null;

  void set(UserRole? role) => state = role;
}

final pendingTutorialProvider =
    NotifierProvider<PendingTutorial, UserRole?>(PendingTutorial.new);
