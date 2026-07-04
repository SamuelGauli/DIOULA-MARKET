import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/guest_gate.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/guest_provider.dart';
import '../../reviews/presentation/widgets/star_rating.dart';
import '../../shops/data/shop_repository.dart';
import '../data/profile_repository.dart';

/// Libellé court du statut de vérification (KYC) pour le sous-titre.
String _kycLabel(String? status) => switch (status) {
      'verifie' => 'Identité vérifiée ✓',
      'en_attente' => 'En cours de vérification',
      'refuse' => 'Vérification refusée',
      _ => 'Non vérifiée — à compléter',
    };

/// Onglet « Profil » : infos utilisateur + paramètres (dark mode, déconnexion).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mode visiteur : pas de profil → invitation à se connecter.
    if (ref.watch(isGuestProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const GuestGate(
          icon: Icons.person_outline,
          title: 'Tu explores en visiteur',
          message:
              'Connecte-toi ou crée un compte pour avoir un profil, une note et accéder à toutes les fonctionnalités.',
        ),
      );
    }

    final profile = ref.watch(currentProfileProvider).value;
    final email = ref.watch(supabaseProvider).auth.currentUser?.email ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = profile?.displayName ?? 'Utilisateur';
    final role = profile?.role;
    final avatarUrl = profile?.avatarUrl;
    final shop = ref.watch(myShopProvider).value; // pour les tuiles vendeur

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier mon profil',
            onPressed: () => context.push(AppRoutes.profileEdit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // En-tête profil
          Center(
            child: Column(
              children: [
                UserAvatar(
                  name: name,
                  url: avatarUrl,
                  radius: 44,
                  backgroundColor: AppColors.clay,
                  foregroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (profile != null)
                  Wrap(
                    spacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      Chip(
                        label: Text(profile.role.label),
                        avatar: const Icon(Icons.badge_outlined, size: 16),
                      ),
                      if (profile.isVerified)
                        Chip(
                          label: const Text('Vérifié'),
                          avatar: const Icon(Icons.verified,
                              size: 16, color: AppColors.success),
                          backgroundColor:
                              AppColors.success.withValues(alpha: 0.12),
                        ),
                    ],
                  ),
                if (profile != null && profile.ratingCount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StarsDisplay(rating: profile.ratingAvg, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${profile.ratingAvg.toStringAsFixed(1)} '
                        '(${profile.ratingCount} avis)',
                        style: const TextStyle(color: AppColors.body),
                      ),
                    ],
                  ),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: AppColors.body)),
                ],
                if (profile?.phone != null && profile!.phone!.isNotEmpty)
                  Text(profile.phone!,
                      style: const TextStyle(color: AppColors.body)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Mon activité',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                // Consommateur : réservations + commandes.
                if (role?.isConsumer ?? false) ...[
                  ListTile(
                    leading: const Icon(Icons.event_available_outlined),
                    title: const Text('Mes réservations'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.reservations),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Mes commandes'),
                    subtitle: const Text('Suivi des livraisons'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.orders),
                  ),
                  const Divider(height: 1),
                ],
                // Livreur : ses courses.
                if (role?.isCourier ?? false) ...[
                  ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: const Text('Mes courses'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.courses),
                  ),
                  const Divider(height: 1),
                ],
                // Vendeur : dashboard + réservations/commandes reçues.
                if (role?.isSeller ?? false) ...[
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: const Text('Tableau de bord'),
                    subtitle: const Text('Stats, diagrammes & historique'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.dashboard),
                  ),
                  if (shop != null) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.event_note_outlined),
                      title: const Text('Réservations reçues'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.shopReservations,
                          extra: shop.id),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.local_shipping_outlined),
                      title: const Text('Commandes & livraisons'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push(AppRoutes.shopOrders, extra: shop.id),
                    ),
                  ],
                  const Divider(height: 1),
                ],
                // Historique : tous les rôles.
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Historique de mes actions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.history),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Paramètres',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode_outlined),
                  title: const Text('Mode sombre'),
                  value: isDark,
                  onChanged: (v) => ref
                      .read(themeModeProvider.notifier)
                      .set(v ? ThemeMode.dark : ThemeMode.light),
                ),
                // Boutique : réservée aux vendeurs (commerçant / producteur).
                if (role?.isSeller ?? false) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: const Text('Ma boutique'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.myShop),
                  ),
                ],
                // Vérification d'identité : obligatoire pour les pros ;
                // requise pour les grosses commandes côté consommateur.
                if (role != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('Vérification d\'identité'),
                    subtitle: Text(_kycLabel(profile?.verificationStatus)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.kyc),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Revoir le tutoriel'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    AppRoutes.tutorial,
                    extra: profile?.role,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.danger.withValues(alpha: 0.08),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Se déconnecter',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ),
        ],
      ),
    );
  }
}
