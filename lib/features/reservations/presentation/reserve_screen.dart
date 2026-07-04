import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/primary_button.dart';
import '../../catalog/domain/catalog_product.dart';
import '../../profile/data/profile_repository.dart';
import '../data/reservations_repository.dart';

/// Écran de réservation : quantité + échéance, calcul de l'acompte (30 %) et
/// du solde, puis paiement simulé.
class ReserveScreen extends ConsumerStatefulWidget {
  const ReserveScreen({super.key, required this.product});
  final CatalogProduct product;

  @override
  ConsumerState<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends ConsumerState<ReserveScreen> {
  double _qty = 1;
  int _slotIndex = 0; // 0 = matin, 1 = après-midi
  bool _loading = false;

  late final DateTime _firstDay;
  late final DateTime _lastDay;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  // Plages horaires ouvertes (réglementées).
  static const _slots = <(String, int, int)>[
    ('Matin · 08h–12h', 8, 12),
    ('Après-midi · 14h–18h', 14, 18),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Livraison à partir de demain, sur 14 jours, hors dimanche.
    _firstDay =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _lastDay = _firstDay.add(const Duration(days: 13));
    var d = _firstDay;
    while (d.weekday == DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    _selectedDay = d;
    _focusedDay = d;
  }

  CatalogProduct get _p => widget.product;
  double get _total => _p.effectivePrice * _qty;
  double get _deposit => (_total * kDepositRate).roundToDouble();
  double get _balance => _total - _deposit;

  DateTime? get _slotStart {
    final d = _selectedDay;
    return d == null ? null : DateTime(d.year, d.month, d.day, _slots[_slotIndex].$2);
  }

  DateTime? get _slotEnd {
    final d = _selectedDay;
    return d == null ? null : DateTime(d.year, d.month, d.day, _slots[_slotIndex].$3);
  }

  Future<void> _pay() async {
    if (_qty < 1 || _qty > _p.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantité invalide (stock : ${formatQty(_p.stock)}).')),
      );
      return;
    }
    final start = _slotStart, end = _slotEnd;
    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis un créneau de livraison.')),
      );
      return;
    }
    // Grosse commande : CNI (vérification d'identité) requise.
    if (_total > kLargeOrderThreshold) {
      final verified =
          ref.read(currentProfileProvider).value?.isVerified ?? false;
      if (!verified) {
        final go = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Vérification requise'),
            content: Text(
              'Les commandes de plus de ${formatFcfa(kLargeOrderThreshold)} '
              'nécessitent une pièce d\'identité (CNI). '
              'Souhaites-tu la renseigner maintenant ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Plus tard'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Vérifier mon identité'),
              ),
            ],
          ),
        );
        if (go == true && mounted) context.push(AppRoutes.kyc);
        return;
      }
    }
    // Paiement simulé de l'acompte.
    final ok = await context.push<bool>(
      AppRoutes.payment,
      extra: (_deposit, 'Acompte — ${_p.name}'),
    );
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(reservationsRepositoryProvider).reserveProduct(
            productId: _p.id,
            quantity: _qty,
            slotStart: start,
            slotEnd: end,
          );
      ref.invalidate(myReservationsProvider);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.reservations);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQty = _p.stock < 1 ? 1.0 : _p.stock;
    return Scaffold(
      appBar: AppBar(title: const Text('Réserver')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(_p.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(
              '${_p.shopName} · ${formatFcfa(_p.effectivePrice)} / ${_p.unit}'
              '${_p.hasPromo ? '  (promo)' : ''}',
              style: const TextStyle(color: AppColors.body)),
          const SizedBox(height: 24),

          // Quantité
          Text('Quantité : ${formatQty(_qty)} ${_p.unit}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _qty > 1 ? () => setState(() => _qty -= 1) : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Slider(
                  value: _qty.clamp(1, maxQty),
                  min: 1,
                  max: maxQty,
                  divisions: maxQty > 1 ? (maxQty - 1).toInt().clamp(1, 100) : 1,
                  activeColor: AppColors.clay,
                  label: formatQty(_qty),
                  onChanged: (v) => setState(() => _qty = v.roundToDouble()),
                ),
              ),
              IconButton.filledTonal(
                onPressed:
                    _qty < maxQty ? () => setState(() => _qty += 1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Créneau de livraison (calendrier + plage horaire)
          const Text('Créneau de livraison',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.twoWeeks,
                availableCalendarFormats: const {
                  CalendarFormat.twoWeeks: '2 sem.'
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: const HeaderStyle(
                    formatButtonVisible: false, titleCentered: true),
                // Créneaux réglementés : pas de dimanche.
                enabledDayPredicate: (day) => day.weekday != DateTime.sunday,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selected, focused) => setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                }),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                      color: AppColors.clay, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                      color: AppColors.clay.withValues(alpha: 0.3),
                      shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              for (var i = 0; i < _slots.length; i++)
                ChoiceChip(
                  label: Text(_slots[i].$1),
                  selected: _slotIndex == i,
                  onSelected: (_) => setState(() => _slotIndex = i),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Récapitulatif
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_slotStart != null) ...[
                    _row('Créneau', formatSlot(_slotStart!, _slotEnd!)),
                    const SizedBox(height: 8),
                  ],
                  _row('Total', formatFcfa(_total)),
                  const SizedBox(height: 8),
                  _row('Acompte (30 %)', formatFcfa(_deposit), accent: true),
                  const Divider(height: 20),
                  _row('Solde au retrait', formatFcfa(_balance), muted: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Annulation possible jusqu\'à 12 h avant le créneau '
            '(remboursement de l\'acompte).',
            style: TextStyle(color: AppColors.body, fontSize: 12),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Payer l\'acompte ${formatFcfa(_deposit)}',
            icon: Icons.lock,
            gradient: true,
            loading: _loading,
            onPressed: _pay,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool accent = false, bool muted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: muted ? AppColors.body : null)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: accent ? 18 : 15,
            color: accent ? AppColors.clay : (muted ? AppColors.body : null),
          ),
        ),
      ],
    );
  }
}
