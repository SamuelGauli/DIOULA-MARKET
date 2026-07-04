import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../profile/domain/profile.dart';
import '../data/admin_repository.dart';

/// Modération des comptes : liste + recherche, bannir / réactiver (avec motif).
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';

  Future<void> _toggle(Profile p) async {
    String? reason;
    if (p.isActive) {
      // Bannir : demander un motif (optionnel).
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Suspendre ${p.displayName} ?'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Motif (optionnel)',
              hintText: 'Ex. : contenu frauduleux, abus…',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Suspendre')),
          ],
        ),
      );
      if (ok != true) return;
      final text = controller.text.trim();
      reason = text.isEmpty ? null : text;
    }

    try {
      await ref
          .read(adminRepositoryProvider)
          .setUserActive(p.id, !p.isActive, reason: reason);
      ref.invalidate(adminProfilesProvider);
      ref.invalidate(adminStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(p.isActive
              ? 'Compte suspendu (ses boutiques aussi).'
              : 'Compte réactivé.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Utilisateurs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher (nom, téléphone, commune)…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.clay,
              onRefresh: () async => ref.invalidate(adminProfilesProvider),
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (all) {
                  final list = _query.isEmpty
                      ? all
                      : all.where((p) {
                          final hay = '${p.fullName ?? ''} ${p.phone ?? ''} '
                                  '${p.commune ?? ''}'
                              .toLowerCase();
                          return hay.contains(_query);
                        }).toList();
                  if (list.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 60),
                      EmptyState(
                        icon: Icons.people_outline,
                        title: 'Aucun utilisateur',
                        message: 'Aucun compte ne correspond à la recherche.',
                      ),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _UserTile(
                      profile: list[i],
                      onToggle: () => _toggle(list[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.profile, required this.onToggle});
  final Profile profile;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final banned = !p.isActive;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            UserAvatar(name: p.displayName, url: p.avatarUrl, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Tag(p.role.label, AppColors.info),
                      if (p.isVerified) _Tag('Vérifié', AppColors.success),
                      if (banned) _Tag('Suspendu', AppColors.danger),
                    ],
                  ),
                  if (p.commune != null && p.commune!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(p.commune!,
                        style: const TextStyle(
                            color: AppColors.body, fontSize: 12)),
                  ],
                  if (banned && p.banReason != null) ...[
                    const SizedBox(height: 2),
                    Text('Motif : ${p.banReason}',
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 11)),
                  ],
                ],
              ),
            ),
            // On ne suspend pas un compte admin.
            if (!p.role.isAdmin)
              banned
                  ? FilledButton.tonal(
                      onPressed: onToggle, child: const Text('Réactiver'))
                  : OutlinedButton(
                      onPressed: onToggle,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger),
                      child: const Text('Suspendre'),
                    ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
