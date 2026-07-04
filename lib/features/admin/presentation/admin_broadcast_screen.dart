import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/admin_repository.dart';

/// Annonce de la plateforme : envoie une notification à tous les comptes actifs.
class AdminBroadcastScreen extends ConsumerStatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  ConsumerState<AdminBroadcastScreen> createState() =>
      _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends ConsumerState<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Envoyer à tous ?'),
        content: const Text(
            'Cette annonce sera envoyée en notification à tous les comptes actifs.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Envoyer')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _sending = true);
    try {
      final body = _body.text.trim();
      final n = await ref
          .read(adminRepositoryProvider)
          .broadcast(_title.text.trim(), body.isEmpty ? null : body);
      if (!mounted) return;
      _title.clear();
      _body.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Annonce envoyée à $n utilisateur(s) ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Annonce à tous')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Diffuse un message à tous les utilisateurs de Dioula Market. '
                  'Il apparaîtra dans leurs notifications (cloche).',
                  style: TextStyle(color: AppColors.body),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  maxLength: 80,
                  decoration: const InputDecoration(
                      labelText: 'Titre *',
                      prefixIcon: Icon(Icons.campaign_outlined)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _body,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: const InputDecoration(
                      labelText: 'Message (optionnel)',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined)),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: Text(_sending ? 'Envoi…' : 'Envoyer à tous'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
