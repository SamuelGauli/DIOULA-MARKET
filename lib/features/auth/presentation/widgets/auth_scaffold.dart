import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/widgets/animated_background.dart';
import '../../../../core/widgets/theme_toggle_button.dart';

/// Gabarit commun des écrans d'authentification (façon template Rive) :
/// fond dégradé navy, barre du haut (retour + bascule thème), logo, titre,
/// sous-titre, puis le contenu (formulaire) dans une carte arrondie.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
    this.onBack,
    this.card = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  /// Si vrai, le [child] est enveloppé dans une carte (formulaires).
  /// Si faux, il est posé directement sur le dégradé (onboarding).
  final bool card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Barre du haut : retour (gauche) + bascule thème (droite).
                    Row(
                      children: [
                        if (showBack)
                          IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                            onPressed:
                                onBack ?? () => Navigator.of(context).maybePop(),
                          )
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                        const ThemeToggleButton(color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Logo de l'app (monogramme terracotta).
                    Center(
                      child: Container(
                        height: 88,
                        width: 88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset('assets/icon/app_icon.png',
                              fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 28),
                    if (card)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: child,
                      )
                    else
                      child,
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 450.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
