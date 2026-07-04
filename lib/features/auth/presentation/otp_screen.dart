import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_controller.dart';
import 'otp_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Écran de vérification 2FA (SMS **simulé**).
/// Le code est affiché à l'écran (zone ambre) pour la démo.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  String? _error;
  int _shakeTick = 0; // change → rejoue la secousse sur erreur

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(otpControllerProvider) == null) {
        ref.read(otpControllerProvider.notifier).generate();
      }
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    final ok = ref.read(otpControllerProvider.notifier).verify(_code.text);
    if (ok) {
      ref.read(otpPendingProvider.notifier).set(false);
      ref.read(otpControllerProvider.notifier).clear();
      // Écran de succès (coche animée + confettis) → puis tuto / accueil.
      context.go(AppRoutes.success);
    } else {
      setState(() {
        _error = 'Code incorrect. Réessaie.';
        _shakeTick++;
      });
    }
  }

  Future<void> _cancel() async {
    // Annuler la 2FA = se déconnecter (le router renvoie vers l'accueil).
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(otpControllerProvider);

    return AuthScaffold(
      title: 'Vérification',
      subtitle: 'Entre le code reçu par SMS',
      onBack: _cancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Démo : on affiche le code simulé (zone ambre).
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: AppColors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Démo (SMS simulé) — code : ${code ?? "…"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 26, letterSpacing: 10),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ).animate(key: ValueKey(_shakeTick)).shake(
                hz: _shakeTick == 0 ? 0 : 4,
                duration: 450.ms,
              ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Vérifier', onPressed: _verify),
          TextButton(
            onPressed: () =>
                ref.read(otpControllerProvider.notifier).generate(),
            child: const Text('Renvoyer le code'),
          ),
        ],
      ),
    );
  }
}
