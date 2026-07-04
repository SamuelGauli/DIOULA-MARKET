import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/app_badge.dart';
import '../data/notifications_repository.dart';

/// Cloche de notifications connectée : badge du nombre de non-lues + ouverture
/// de l'écran des notifications au tap.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider);
    return NotificationBell(
      count: count,
      onTap: () => context.push(AppRoutes.notifications),
    );
  }
}
