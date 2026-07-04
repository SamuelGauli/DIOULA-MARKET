import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_loader.dart';

/// Bouton principal (CTA) façon Foodly/Rive : plein, coins arrondis,
/// **animation d'enfoncement au tap**, état de chargement animé (points
/// rebondissants) et icône optionnelle (ex: flèche).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  /// Si vrai, utilise le dégradé d'accent (effet CTA premium).
  final bool gradient;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  double _scale = 1;

  bool get _enabled => !widget.loading && widget.onPressed != null;

  void _down(_) {
    if (_enabled) setState(() => _scale = 0.96);
  }

  void _up([_]) {
    if (_scale != 1) setState(() => _scale = 1);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.loading
        ? const SizedBox(
            height: 22,
            child: AppLoader(color: Colors.white, size: 8),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.label),
              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                Icon(widget.icon, size: 20),
              ],
            ],
          );

    final Widget button;
    if (!widget.gradient) {
      button = FilledButton(
        onPressed: widget.loading ? null : widget.onPressed,
        child: child,
      );
    } else {
      // Variante dégradé : on enveloppe un FilledButton transparent.
      button = DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
          ),
          child: child,
        ),
      );
    }

    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: button,
      ),
    );
  }
}
