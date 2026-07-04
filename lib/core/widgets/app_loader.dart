import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Indicateur de chargement animé : trois points qui rebondissent en cadence
/// (recréé en natif + flutter_animate, sans asset externe).
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.color = Colors.white, this.size = 9});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) => Container(
          height: size,
          width: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              delay: (i * 150).ms,
            )
            .scaleXY(begin: 0.5, end: 1, duration: 450.ms, curve: Curves.easeInOut);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(0),
        SizedBox(width: size * 0.7),
        dot(1),
        SizedBox(width: size * 0.7),
        dot(2),
      ],
    );
  }
}
