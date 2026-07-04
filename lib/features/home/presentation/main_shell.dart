import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../admin/presentation/admin_hub_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/guest_provider.dart';
import '../../orders/presentation/courier_courses_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_page.dart';
import '../../requests/presentation/requests_hub_screen.dart';
import '../../shops/presentation/my_shop_screen.dart';
import 'home_feed_page.dart';

/// Coquille principale (après connexion / en visiteur) : barre de navigation
/// basse **adaptée au rôle** + contenu en `IndexedStack` (conserve l'état).
///
/// - Consommateur / visiteur : Accueil · Demandes · Profil
/// - Commerçant / Producteur : Accueil · Boutique · Demandes · Profil
/// - Livreur : Accueil · Courses · Profil
/// - Admin : Accueil · Supervision · Modération · Profil
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  /// Icône sélectionnée qui rebondit à chaque changement d'onglet.
  Widget _bounce(IconData icon) => Icon(icon)
      .animate(key: ValueKey(_index))
      .scaleXY(begin: 0.7, end: 1, duration: 350.ms, curve: Curves.elasticOut);

  @override
  Widget build(BuildContext context) {
    if (!Env.isConfigured) return const _NotConfigured();

    // Compte suspendu par la modération → message + déconnexion immédiate.
    ref.listen(currentProfileProvider, (_, next) {
      final p = next.value;
      if (p != null && !p.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Compte suspendu par la modération'
              '${p.banReason == null ? '' : ' : ${p.banReason}'}.'),
          duration: const Duration(seconds: 5),
        ));
        ref.read(authControllerProvider.notifier).signOut();
      }
    });

    final isGuest = ref.watch(isGuestProvider);
    final role =
        ref.watch(currentProfileProvider).value?.role ?? UserRole.consommateur;

    // Onglets selon le rôle.
    final List<_NavTab> tabs;
    if (!isGuest && role.isAdmin) {
      tabs = [
        _NavTab(Icons.home_outlined, Icons.home, 'Accueil',
            HomeFeedPage(onOpenShop: () {})),
        const _NavTab(Icons.bar_chart_outlined, Icons.bar_chart, 'Supervision',
            AdminDashboardScreen()),
        const _NavTab(Icons.admin_panel_settings_outlined,
            Icons.admin_panel_settings, 'Modération', AdminHubScreen()),
        const _NavTab(
            Icons.person_outline, Icons.person, 'Profil', ProfilePage()),
      ];
    } else if (!isGuest && role.isSeller) {
      tabs = [
        _NavTab(Icons.home_outlined, Icons.home, 'Accueil',
            HomeFeedPage(onOpenShop: () => _goTo(1))),
        const _NavTab(Icons.storefront_outlined, Icons.storefront, 'Boutique',
            MyShopScreen()),
        const _NavTab(
            Icons.bolt_outlined, Icons.bolt, 'Demandes', RequestsHubScreen()),
        const _NavTab(
            Icons.person_outline, Icons.person, 'Profil', ProfilePage()),
      ];
    } else if (!isGuest && role.isCourier) {
      tabs = [
        _NavTab(Icons.home_outlined, Icons.home, 'Accueil',
            HomeFeedPage(onOpenShop: () {})),
        const _NavTab(
          Icons.local_shipping_outlined,
          Icons.local_shipping,
          'Courses',
          CourierCoursesScreen(),
        ),
        const _NavTab(
            Icons.person_outline, Icons.person, 'Profil', ProfilePage()),
      ];
    } else {
      // Consommateur + visiteur. Les demandes ne concernent pas les visiteurs.
      tabs = [
        _NavTab(Icons.home_outlined, Icons.home, 'Accueil',
            HomeFeedPage(onOpenShop: () {})),
        if (!isGuest)
          const _NavTab(
              Icons.bolt_outlined, Icons.bolt, 'Demandes', RequestsHubScreen()),
        const _NavTab(
            Icons.person_outline, Icons.person, 'Profil', ProfilePage()),
      ];
    }

    // Sécurité : si le rôle change et réduit le nombre d'onglets.
    final index = _index < tabs.length ? _index : 0;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [for (final t in tabs) t.page],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _goTo,
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: _bounce(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

/// Descripteur d'un onglet de la barre de navigation.
class _NavTab {
  const _NavTab(this.icon, this.selectedIcon, this.label, this.page);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppInfo.appName)),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber, size: 64, color: AppColors.warning),
              SizedBox(height: 16),
              Text('Supabase non configuré',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                'Copie .env.example → .env et renseigne SUPABASE_URL et '
                'SUPABASE_ANON_KEY, puis relance l\'application.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
