import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_background.dart';
import '../../tutorial/presentation/tutorial_provider.dart';

/// Écran de **succès** affiché juste après la vérification 2FA :
/// coche animée (rebond élastique) + **confettis**, puis redirection
/// automatique vers le tutoriel (si en attente) ou l'accueil.
class SuccessScreen extends ConsumerStatefulWidget {
  const SuccessScreen({super.key});

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen> {
  late final ConfettiController _confetti;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _confetti.play();
    _timer = Timer(const Duration(milliseconds: 2600), _next);
  }

  void _next() {
    if (!mounted) return;
    final hasTutorial = ref.read(pendingTutorialProvider) != null;
    context.go(hasTutorial ? AppRoutes.tutorial : AppRoutes.home);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Stack(
          children: [
            // Confettis tirés depuis le haut.
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 24,
                minBlastForce: 8,
                maxBlastForce: 22,
                gravity: 0.25,
                colors: const [
                  AppColors.green,
                  AppColors.orange,
                  Colors.white,
                  Color(0xFF2BB76A),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 72),
                  )
                      .animate()
                      .scaleXY(
                        begin: 0,
                        end: 1,
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .then()
                      .shimmer(duration: 900.ms, color: Colors.white70),
                  const SizedBox(height: 28),
                  const Text(
                    'Compte vérifié !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 8),
                  const Text(
                    'Bienvenue sur Dioula Market',
                    style: TextStyle(color: Colors.white70),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
