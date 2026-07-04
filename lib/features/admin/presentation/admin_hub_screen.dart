import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';

/// Hub « Modération » de l'admin : porte d'entrée vers les outils du
/// back-office. Une tuile sans route est affichée grisée (« bientôt ») —
/// les écrans sont branchés au fil des commits admin 2 et 3.
class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // (icône, titre, sous-titre, couleur, route ou null si pas encore branché)
    final tiles = <(IconData, String, String, Color, String?)>[
      (
        Icons.people_outline,
        'Utilisateurs',
        'Bannir / réactiver un compte',
        AppColors.info,
        AppRoutes.adminUsers,
      ),
      (
        Icons.storefront_outlined,
        'Boutiques',
        'Suspendre / réactiver une boutique',
        AppColors.clay,
        AppRoutes.adminShops,
      ),
      (
        Icons.inventory_2_outlined,
        'Produits',
        'Masquer / republier un produit',
        AppColors.ocre,
        AppRoutes.adminProducts,
      ),
      (
        Icons.verified_user_outlined,
        'Vérifications (KYC)',
        'Approuver / refuser les identités',
        AppColors.success,
        AppRoutes.adminKyc,
      ),
      (
        Icons.reviews_outlined,
        'Avis & commentaires',
        'Masquer un avis inapproprié',
        AppColors.warning,
        AppRoutes.adminReviews,
      ),
      (
        Icons.campaign_outlined,
        'Annonce à tous',
        'Notifier tous les utilisateurs',
        AppColors.clay,
        AppRoutes.adminBroadcast,
      ),
      (
        Icons.history,
        'Audit global',
        'Journal des actions de la plateforme',
        AppColors.body,
        AppRoutes.adminAudit,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Modération')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final t = tiles[i];
          final enabled = t.$5 != null;
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              enabled: enabled,
              leading: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: t.$4.withValues(alpha: enabled ? 0.14 : 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(t.$1,
                    color: enabled ? t.$4 : AppColors.body, size: 22),
              ),
              title: Text(t.$2,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(enabled ? t.$3 : '${t.$3} — bientôt',
                  style: const TextStyle(fontSize: 12)),
              trailing: enabled
                  ? const Icon(Icons.chevron_right)
                  : const Icon(Icons.lock_outline,
                      size: 18, color: AppColors.body),
              onTap: enabled ? () => context.push(t.$5!) : null,
            ),
          );
        },
      ),
    );
  }
}
