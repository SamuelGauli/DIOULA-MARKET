import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../data/admin_repository.dart';
import '../domain/admin_stats.dart';

/// Couleur associée à un statut de commande (camembert).
Color _statusColor(String status) => switch (status) {
      'livree' => AppColors.success,
      'en_livraison' => AppColors.info,
      'preparee' => AppColors.ocre,
      'annulee' => AppColors.danger,
      _ => AppColors.clay, // en_cours
    };

/// Libellé lisible d'un statut de commande.
String _statusLabel(String status) => OrderStatus.values
    .firstWhere((s) => s.value == status, orElse: () => OrderStatus.enCours)
    .label;

/// Tableau de bord **global** de la plateforme (admin) : compteurs clés,
/// commandes par statut (camembert) et utilisateurs par rôle (barres).
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Supervision — Dioula Market')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 60),
              Center(child: Text('Erreur : $e')),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Vérifie que step22.sql est exécuté et que ce compte est admin.',
                  style: TextStyle(color: AppColors.body, fontSize: 12),
                ),
              ),
            ],
          ),
          data: (s) => _Dashboard(stats: s),
        ),
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.stats});
  final AdminStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- Alerte KYC en attente → file de validation ----
        if (stats.kycPending > 0) ...[
          AppCard(
            onTap: () => context.push(AppRoutes.adminKyc),
            child: Row(
              children: [
                const Icon(Icons.pending_actions, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${stats.kycPending} vérification(s) d\'identité en attente',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.body),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ---- Compteurs clés ----
        const _SectionTitle('Plateforme'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.people_outline,
                label: 'Utilisateurs',
                value: '${stats.usersTotal}',
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.storefront_outlined,
                label: 'Boutiques actives',
                value: '${stats.shopsActive}/${stats.shopsTotal}',
                color: AppColors.clay,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.inventory_2_outlined,
                label: 'Produits actifs',
                value: '${stats.productsActive}/${stats.productsTotal}',
                color: AppColors.ocre,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.receipt_long,
                label: 'Commandes',
                value: '${stats.ordersTotal}',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.payments_outlined,
                label: 'GMV (commandes livrées)',
                value: formatFcfa(stats.gmv),
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.event_available_outlined,
                label: 'Réservations',
                value: '${stats.reservationsTotal}',
                color: AppColors.beigeDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.bolt_outlined,
                label: 'Demandes ouvertes',
                value: '${stats.requestsOpen}',
                color: AppColors.clay,
              ),
            ),
          ],
        ),

        // ---- Commandes par statut ----
        const SizedBox(height: 18),
        const _SectionTitle('Commandes par statut'),
        const SizedBox(height: 10),
        AppCard(
          child: _LabeledPie(
            segments: [
              for (final e in stats.ordersByStatus.entries)
                (_statusLabel(e.key), e.value, _statusColor(e.key)),
            ],
          ),
        ),

        // ---- Utilisateurs par rôle ----
        const SizedBox(height: 18),
        const _SectionTitle('Utilisateurs par rôle'),
        const SizedBox(height: 10),
        AppCard(
          child: _LabeledBars(
            bars: [
              for (final r in UserRole.values)
                if ((stats.usersByRole[r.value] ?? 0) > 0)
                  (r.label, stats.usersByRole[r.value]!, AppColors.clay),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
//  Widgets (mêmes patterns fl_chart que le dashboard vendeur)
// ---------------------------------------------------------------------------

/// Camembert générique avec légende (libellé, valeur, couleur).
class _LabeledPie extends StatelessWidget {
  const _LabeledPie({required this.segments});
  final List<(String, int, Color)> segments;

  @override
  Widget build(BuildContext context) {
    final data = segments.where((s) => s.$2 > 0).toList();
    if (data.isEmpty) return const _NoData();

    return Row(
      children: [
        SizedBox(
          height: 130,
          width: 130,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: [
                for (final s in data)
                  PieChartSectionData(
                    value: s.$2.toDouble(),
                    color: s.$3,
                    title: '${s.$2}',
                    radius: 28,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in data)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          color: s.$3,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${s.$1} (${s.$2})',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Histogramme générique (libellé, valeur, couleur).
class _LabeledBars extends StatelessWidget {
  const _LabeledBars({required this.bars});
  final List<(String, int, Color)> bars;

  @override
  Widget build(BuildContext context) {
    final maxV = bars.fold<int>(0, (m, b) => b.$2 > m ? b.$2 : m);
    if (maxV <= 0) return const _NoData();

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxV * 1.25,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(bars[i].$1,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.body)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < bars.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: bars[i].$2.toDouble(),
                    color: bars[i].$3,
                    width: 26,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.body, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _NoData extends StatelessWidget {
  const _NoData();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('Pas encore de données.',
            style: TextStyle(color: AppColors.body)),
      ),
    );
  }
}
