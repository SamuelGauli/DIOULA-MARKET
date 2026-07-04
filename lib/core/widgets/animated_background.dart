import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

/// Fond animé façon template Rive : dégradé navy + grandes **formes floutées**
/// (vert / orange) qui dérivent et pulsent lentement en arrière-plan.
///
/// Réutilisé par les écrans d'authentification, l'onboarding et l'écran de
/// succès. Le [child] est posé net au-dessus des formes floutées.
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key, required this.child, this.gradient});

  final Widget child;

  /// Dégradé de base (par défaut : le navy d'auth).
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dégradé de base.
        Positioned.fill(
          child: DecoratedBox(
            decoration:
                BoxDecoration(gradient: gradient ?? AppColors.authGradient),
          ),
        ),
        // Formes floutées en mouvement (le flou est appliqué à l'ensemble).
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: const Stack(
              children: [
                _Blob(
                  color: AppColors.green,
                  alpha: 0.55,
                  size: 240,
                  top: -40,
                  left: -50,
                  moveX: 40,
                  moveY: 60,
                  seconds: 7,
                ),
                _Blob(
                  color: AppColors.orange,
                  alpha: 0.45,
                  size: 200,
                  top: 130,
                  right: -60,
                  moveX: -50,
                  moveY: 40,
                  seconds: 9,
                ),
                _Blob(
                  color: AppColors.beige,
                  alpha: 0.40,
                  size: 260,
                  bottom: -70,
                  left: 20,
                  moveX: 50,
                  moveY: -40,
                  seconds: 11,
                ),
              ],
            ),
          ),
        ),
        // Contenu net au-dessus.
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Une forme floutée qui dérive et pulse en boucle.
class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.alpha,
    required this.size,
    required this.seconds,
    required this.moveX,
    required this.moveY,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final Color color;
  final double alpha;
  final double size;
  final int seconds;
  final double moveX;
  final double moveY;
  final double? top, bottom, left, right;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: seconds);
    final blob = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveX(begin: 0, end: moveX, duration: duration, curve: Curves.easeInOut)
        .moveY(begin: 0, end: moveY, duration: duration, curve: Curves.easeInOut)
        .scaleXY(
          begin: 0.9,
          end: 1.15,
          duration: duration,
          curve: Curves.easeInOut,
        );

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: blob,
    );
  }
}
