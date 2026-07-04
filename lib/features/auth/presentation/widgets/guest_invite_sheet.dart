import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../guest_provider.dart';

/// Si l'utilisateur est **visiteur**, ouvre la modale d'invitation à
/// s'inscrire / se connecter et renvoie `false` (action bloquée).
/// Sinon renvoie `true` (action autorisée).
bool requireAccount(BuildContext context, WidgetRef ref, {String? action}) {
  if (ref.read(isGuestProvider)) {
    showGuestInvite(context, action: action);
    return false;
  }
  return true;
}

/// Bottom sheet animée invitant le visiteur à créer un compte / se connecter.
Future<void> showGuestInvite(BuildContext context, {String? action}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GuestInviteSheet(action: action),
  );
}

class _GuestInviteSheet extends StatelessWidget {
  const _GuestInviteSheet({this.action});
  final String? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionText = action == null
        ? 'Pour continuer'
        : 'Pour $action';

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.body.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 84,
            width: 84,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.clay.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.lock_open_rounded,
                color: Colors.white, size: 40),
          ).animate().scaleXY(
                begin: 0.6,
                end: 1,
                duration: 450.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 20),
          Text(
            'Rejoins Dioula Market',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$actionText, crée un compte gratuit ou connecte-toi. '
            "L'exploration reste libre 👀",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.body),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Créer un compte',
            icon: Icons.arrow_forward,
            gradient: true,
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.register);
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.login);
            },
            child: const Text('Se connecter'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
        ],
      ),
    ).animate().slideY(
          begin: 0.3,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
