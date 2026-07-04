import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/primary_button.dart';
import 'guest_provider.dart';
import 'widgets/auth_scaffold.dart';

/// Écran d'accueil (onboarding) — point d'entrée des visiteurs non connectés.
/// Style façon template Rive : fond dégradé navy + CTA + accès visiteur.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthScaffold(
      showBack: false,
      card: false,
      title: AppInfo.appName,
      subtitle: AppInfo.tagline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: 'Se connecter',
            icon: Icons.arrow_forward,
            onPressed: () => context.push(AppRoutes.login),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.register),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
            child: const Text('Créer un compte'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              // Active le mode visiteur puis entre dans l'app.
              ref.read(guestModeProvider.notifier).set(true);
              context.go(AppRoutes.home);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Continuer en visiteur'),
          ),
        ],
      ),
    );
  }
}
