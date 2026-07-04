import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/guest_gate.dart';
import '../../auth/presentation/guest_provider.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

/// Écran des notifications in-app. Marque tout comme lu à l'ouverture.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(currentUserIdProvider);
      if (uid != null) {
        ref.read(notificationsRepositoryProvider).markAllRead(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const GuestGate(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          message:
              'Crée un compte pour recevoir tes offres, réservations et alertes.',
        ),
      );
    }

    final async = ref.watch(notificationsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Aucune notification',
              message: 'Tes offres, réservations et alertes apparaîtront ici.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _NotificationTile(item: list[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});
  final AppNotification item;

  (IconData, Color) get _visual {
    switch (item.type) {
      case 'offre':
        return (Icons.bolt, AppColors.clay);
      case 'reservation':
        return (Icons.event_available, AppColors.success);
      case 'stock':
        return (Icons.inventory_2_outlined, AppColors.warning);
      default:
        return (Icons.notifications_none_rounded, AppColors.info);
    }
  }

  /// Écran cible selon le type de notification (navigation « exploitable »).
  String? get _route {
    switch (item.type) {
      case 'offre':
        return AppRoutes.requests;
      case 'reservation':
        return AppRoutes.reservations;
      case 'livraison':
        return AppRoutes.orders;
      case 'stock':
        return AppRoutes.shopProducts;
      case 'avis':
        return AppRoutes.history;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual;
    final route = _route;
    return Card(
      child: ListTile(
        onTap: route == null ? null : () => context.push(route),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(icon, color: color),
        ),
        title: Text(item.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: item.body == null ? null : Text(item.body!),
        trailing: Text(
          _timeAgo(item.createdAt),
          style: const TextStyle(color: AppColors.body, fontSize: 11),
        ),
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} j';
  }
}
