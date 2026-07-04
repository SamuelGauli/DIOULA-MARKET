import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  // Rôles choisissables à l'inscription (pas "admin").
  final _roles = UserRole.values.where((r) => r != UserRole.admin).toList();
  UserRole _role = UserRole.consommateur;
  bool _obscure = true;
  bool _loading = false;
  int _shakeTick = 0; // change → secousse du formulaire sur erreur

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await ref.read(authControllerProvider.notifier).signUp(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _fullName.text.trim(),
          phone: _phone.text.trim(),
          role: _role.value,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success && res.hasSession) {
      context.go(AppRoutes.otp);
    } else if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Compte créé.')),
      );
      context.go(AppRoutes.login);
    } else {
      setState(() => _shakeTick++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? "Erreur d'inscription")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Créer un compte',
      subtitle: 'Rejoins Dioula Market',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _fullName,
              label: 'Nom complet',
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _phone,
              label: 'Téléphone',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Téléphone requis' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _email,
              label: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            DropdownButtonFormField<UserRole>(
              value: _role,
              decoration: const InputDecoration(
                labelText: 'Je suis…',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: _roles
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (r) => setState(() => _role = r ?? _role),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: "S'inscrire",
              loading: _loading,
              onPressed: _submit,
            ),
            TextButton(
              onPressed: _loading ? null : () => context.push(AppRoutes.login),
              child: const Text('Déjà un compte ? Se connecter'),
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
