import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/guest_gate.dart';
import '../../auth/presentation/guest_provider.dart';
import '../data/activity_repository.dart';
import '../domain/activity_entry.dart';

/// « Historique » : journal des actions de l'utilisateur (traçabilité).
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historique')),
        body: const GuestGate(
          icon: Icons.history,
          title: 'Historique',
          message:
              'Connecte-toi pour retrouver l\'historique de tes actions.',
        ),
      );
    }

    final async = ref.watch(myActivityProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async => ref.invalidate(myActivityProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.history,
                    title: 'Aucune activité',
                    message:
                        'Tes actions (demandes, réservations, commandes, avis…) apparaîtront ici.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _ActivityTile(entry: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});
  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual(entry.entity);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(entry.detail,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(_ago(entry.createdAt),
          style: const TextStyle(color: AppColors.body, fontSize: 12)),
    );
  }

  (IconData, Color) _visual(String? entity) {
    switch (entity) {
      case 'order':
        return (Icons.shopping_bag_outlined, AppColors.clay);
      case 'reservation':
        return (Icons.event_available_outlined, AppColors.info);
      case 'offer':
        return (Icons.bolt, AppColors.ocre);
      case 'review':
        return (Icons.star_rounded, AppColors.warning);
      case 'request':
        return (Icons.campaign_outlined, AppColors.success);
      default:
        return (Icons.history, AppColors.body);
    }
  }

  String _ago(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 1) return 'il y a ${diff.inDays} j';
    if (diff.inHours >= 1) return 'il y a ${diff.inHours} h';
    if (diff.inMinutes >= 1) return 'il y a ${diff.inMinutes} min';
    return 'à l\'instant';
  }
}
