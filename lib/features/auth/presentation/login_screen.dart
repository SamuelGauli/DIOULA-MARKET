import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_controller.dart';
import 'otp_controller.dart';
import 'widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  int _shakeTick = 0; // change → secousse du formulaire sur erreur

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success && res.hasSession) {
      // Comptes démo : 2FA non armée → accès direct. Sinon → écran OTP.
      final pending = ref.read(otpPendingProvider);
      context.go(pending ? AppRoutes.otp : AppRoutes.home);
    } else if (!res.success) {
      setState(() => _shakeTick++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Erreur de connexion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Bon retour 👋',
      subtitle: 'Connecte-toi pour continuer',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _email,
              label: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _password,
              label: 'Mot de passe',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? '6 caractères minimum' : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Se connecter',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _loading ? null : () => context.push(AppRoutes.register),
              child: const Text("Pas de compte ? S'inscrire"),
            ),
          ],
        ),
      ).animate(key: ValueKey(_shakeTick)).shake(
            hz: _shakeTick == 0 ? 0 : 4,
            duration: 450.ms,
          ),
    );
  }
}
