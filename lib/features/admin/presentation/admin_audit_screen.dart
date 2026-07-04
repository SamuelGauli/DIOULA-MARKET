import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../activity/domain/activity_entry.dart';
import '../data/admin_repository.dart';

/// Icône selon le type d'action journalisée.
IconData _iconFor(String action) {
  if (action.startsWith('admin_')) return Icons.admin_panel_settings_outlined;
  if (action.contains('order')) return Icons.receipt_long;
  if (action.contains('offer')) return Icons.local_offer_outlined;
  if (action.contains('reservation')) return Icons.event_available_outlined;
  if (action.contains('review')) return Icons.star_outline;
  if (action.contains('request')) return Icons.bolt_outlined;
  return Icons.circle_outlined;
}

/// Journal d'audit **global** de la plateforme (toutes les actions, dont
/// celles de l'admin). Lecture réservée à l'admin (policy `activity_admin_select`).
class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAuditProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Audit global')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async => ref.invalidate(adminAuditProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (entries) {
            if (entries.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 60),
                EmptyState(
                  icon: Icons.history,
                  title: 'Journal vide',
                  message: 'Les actions de la plateforme apparaîtront ici.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final (ActivityEntry e, String actor) = entries[i];
                final isAdmin = e.action.startsWith('admin_');
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (isAdmin ? AppColors.clay : AppColors.info)
                        .withValues(alpha: 0.14),
                    child: Icon(_iconFor(e.action),
                        size: 20,
                        color: isAdmin ? AppColors.clay : AppColors.info),
                  ),
                  title: Text(e.detail,
                      style: const TextStyle(fontSize: 13.5)),
                  subtitle: Text(
                    '$actor${e.createdAt != null ? ' · ${_fmt(e.createdAt!)}' : ''}',
                    style:
                        const TextStyle(color: AppColors.body, fontSize: 11.5),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}
