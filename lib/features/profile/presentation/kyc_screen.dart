import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/guest_gate.dart';
import '../../auth/presentation/guest_provider.dart';
import '../data/profile_repository.dart';

/// Écran « Vérification d'identité » (KYC) : dépôt de la pièce d'identité et du
/// certificat de résidence → statut « en vérification » puis « vérifié ».
/// Réservé aux vendeurs / producteurs / livreurs (obligatoire pour exercer).
class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  String? _idPath;
  String? _residencePath;
  bool _busy = false;

  Future<void> _pick(String kind) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (x == null) return;
      setState(() => _busy = true);
      final file = kIsWeb ? File.fromRawPath(await x.readAsBytes()) : File(x.path);
      final userId = ref.read(currentUserIdProvider)!;
      final path = await ref.read(profileRepositoryProvider).uploadKycDoc(
            userId: userId,
            file: file,
            kind: kind,
          );
      setState(() {
        if (kind == 'id') {
          _idPath = path;
        } else {
          _residencePath = path;
        }
      });
    } catch (e) {
      _snack('Erreur d\'envoi : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_idPath == null || _residencePath == null) return;
    setState(() => _busy = true);
    try {
      final userId = ref.read(currentUserIdProvider)!;
      await ref
          .read(profileRepositoryProvider)
          .submitKyc(userId, _idPath!, _residencePath!);
      ref.invalidate(currentProfileProvider);
      _snack('Documents soumis — en cours de vérification.');
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Consommateur : soumission de la CNI seule.
  Future<void> _submitCni() async {
    if (_idPath == null) return;
    setState(() => _busy = true);
    try {
      final userId = ref.read(currentUserIdProvider)!;
      await ref.read(profileRepositoryProvider).submitCni(userId, _idPath!);
      ref.invalidate(currentProfileProvider);
      _snack('CNI soumise — en cours de vérification.');
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _simulateVerify() async {
    setState(() => _busy = true);
    try {
      final userId = ref.read(currentUserIdProvider)!;
      await ref.read(profileRepositoryProvider).simulateVerifyKyc(userId);
      ref.invalidate(currentProfileProvider);
      _snack('Identité vérifiée ✅');
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vérification d\'identité')),
        body: const GuestGate(
          icon: Icons.verified_user_outlined,
          title: 'Vérification d\'identité',
          message: 'Connecte-toi avec un compte professionnel pour te vérifier.',
        ),
      );
    }

    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification d\'identité')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (p) {
          final status = p?.verificationStatus ?? 'non_soumis';
          final isConsumer = p?.role.isConsumer ?? false;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusBanner(status: status),
              const SizedBox(height: 16),
              if (status == 'verifie')
                const AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: AppColors.success),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            'Ton identité est vérifiée. Merci, tu peux exercer en toute confiance.'),
                      ),
                    ],
                  ),
                )
              else if (status == 'en_attente') ...[
                const AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_top, color: AppColors.warning),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            'Tes pièces ont été reçues et sont en cours de vérification.'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _simulateVerify,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Simuler la validation (démo)'),
                ),
              ] else if (isConsumer) ...[
                Text(
                  'Pour valider une commande de plus de '
                  '${formatFcfa(kLargeOrderThreshold)}, ajoute ta pièce '
                  'd\'identité (CNI). Elle reste privée.',
                  style: const TextStyle(color: AppColors.body),
                ),
                const SizedBox(height: 14),
                _DocTile(
                  icon: Icons.badge_outlined,
                  label: 'Pièce d\'identité (CNI)',
                  done: _idPath != null,
                  busy: _busy,
                  onPick: () => _pick('id'),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: (_idPath != null && !_busy) ? _submitCni : null,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Soumettre ma CNI'),
                ),
              ] else ...[
                const Text(
                  'Dépose ta pièce d\'identité et ton certificat de résidence. '
                  'Ils restent privés et servent uniquement à valider ton compte.',
                  style: TextStyle(color: AppColors.body),
                ),
                const SizedBox(height: 14),
                _DocTile(
                  icon: Icons.badge_outlined,
                  label: 'Pièce d\'identité',
                  done: _idPath != null,
                  busy: _busy,
                  onPick: () => _pick('id'),
                ),
                const SizedBox(height: 10),
                _DocTile(
                  icon: Icons.home_outlined,
                  label: 'Certificat de résidence',
                  done: _residencePath != null,
                  busy: _busy,
                  onPick: () => _pick('residence'),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed:
                      (_idPath != null && _residencePath != null && !_busy)
                          ? _submit
                          : null,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Soumettre pour vérification'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'verifie' => ('Vérifié', AppColors.success, Icons.verified),
      'en_attente' => ('En vérification', AppColors.warning, Icons.hourglass_top),
      'refuse' => ('Refusé', AppColors.danger, Icons.cancel_outlined),
      _ => ('Non soumis', AppColors.body, Icons.privacy_tip_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text('Statut : ',
              style: const TextStyle(color: AppColors.body)),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.icon,
    required this.label,
    required this.done,
    required this.busy,
    required this.onPick,
  });

  final IconData icon;
  final String label;
  final bool done;
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : icon,
              color: done ? AppColors.success : AppColors.clay),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: busy ? null : onPick,
            child: Text(done ? 'Remplacer' : 'Choisir'),
          ),
        ],
      ),
    );
  }
}
