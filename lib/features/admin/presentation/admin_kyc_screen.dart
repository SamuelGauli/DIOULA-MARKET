import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../profile/domain/profile.dart';
import '../data/admin_repository.dart';

/// Validation des identités (KYC) : file des profils « en attente »,
/// consultation des pièces (URL signée du bucket privé), approuver / refuser.
class AdminKycScreen extends ConsumerWidget {
  const AdminKycScreen({super.key});

  Future<void> _review(BuildContext context, WidgetRef ref, Profile p,
      {required bool approve}) async {
    try {
      await ref.read(adminRepositoryProvider).reviewKyc(p.id, approve: approve);
      ref.invalidate(adminPendingKycProvider);
      ref.invalidate(adminStatsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve
              ? '${p.displayName} est maintenant vérifié(e) ✅'
              : 'Vérification refusée — l\'utilisateur peut resoumettre.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  /// Ouvre une pièce dans une boîte de dialogue (image via URL signée 1 h).
  Future<void> _viewDoc(BuildContext context, WidgetRef ref, String path,
      String title) async {
    try {
      final url = await ref.read(adminRepositoryProvider).signedKycUrl(path);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Flexible(
                child: AppImage(
                  url: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Impossible d\'afficher la pièce.'),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pièce inaccessible (step23.sql exécuté ?) : $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPendingKycProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vérifications (KYC)')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async => ref.invalidate(adminPendingKycProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (pending) {
            if (pending.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 60),
                EmptyState(
                  icon: Icons.verified_user_outlined,
                  title: 'Aucune vérification en attente',
                  message:
                      'Les identités soumises par les utilisateurs apparaîtront ici.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = pending[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            UserAvatar(
                                name: p.displayName,
                                url: p.avatarUrl,
                                radius: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                    '${p.role.label}'
                                    '${p.commune != null ? ' · ${p.commune}' : ''}',
                                    style: const TextStyle(
                                        color: AppColors.body, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Pièces soumises (CNI seule pour un consommateur).
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (p.idDocPath != null)
                              OutlinedButton.icon(
                                onPressed: () => _viewDoc(context, ref,
                                    p.idDocPath!, 'Pièce d\'identité'),
                                icon: const Icon(Icons.badge_outlined,
                                    size: 18),
                                label: const Text('Pièce d\'identité'),
                              ),
                            if (p.residenceDocPath != null)
                              OutlinedButton.icon(
                                onPressed: () => _viewDoc(
                                    context,
                                    ref,
                                    p.residenceDocPath!,
                                    'Justificatif de résidence'),
                                icon: const Icon(Icons.home_outlined,
                                    size: 18),
                                label: const Text('Résidence'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _review(context, ref, p,
                                    approve: true),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Approuver'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _review(context, ref, p,
                                    approve: false),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Refuser'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
