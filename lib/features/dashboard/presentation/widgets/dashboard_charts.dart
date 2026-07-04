import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Camembert « Réservations par statut » (actives / terminées / perdues).
class ReservationsPieChart extends StatelessWidget {
  const ReservationsPieChart({
    super.key,
    required this.active,
    required this.done,
    required this.lost,
  });

  final int active;
  final int done;
  final int lost;

  @override
  Widget build(BuildContext context) {
    final data = [
      _Seg('Actives', active, AppColors.info),
      _Seg('Terminées', done, AppColors.success),
      _Seg('Perdues', lost, AppColors.danger),
    ].where((s) => s.value > 0).toList();

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
                    value: s.value.toDouble(),
                    color: s.color,
                    title: '${s.value}',
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
                          color: s.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${s.label} (${s.value})',
                          style: const TextStyle(fontSize: 13)),
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

/// Histogramme « Chiffre d'affaires (simulé) » : CA / Acompte / Remboursé.
class RevenueBarChart extends StatelessWidget {
  const RevenueBarChart({
    super.key,
    required this.caConfirmed,
    required this.acomptes,
    required this.refunded,
  });

  final double caConfirmed;
  final double acomptes;
  final double refunded;

  @override
  Widget build(BuildContext context) {
    final bars = <(String, double, Color)>[
      ('CA', caConfirmed, AppColors.success),
      ('Acompte', acomptes, AppColors.clay),
      ('Remb.', refunded, AppColors.body),
    ];
    final maxV = bars.fold<double>(0, (m, b) => b.$2 > m ? b.$2 : m);
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
                  if (i < 0 || i >= bars.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(bars[i].$1,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.body)),
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
                    toY: bars[i].$2,
                    color: bars[i].$3,
                    width: 28,
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

class _Seg {
  const _Seg(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
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
