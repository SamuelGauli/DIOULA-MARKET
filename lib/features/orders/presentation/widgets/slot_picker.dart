import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';

/// Ouvre une feuille de choix de **créneau** (jour + plage horaire) et renvoie
/// `(début, fin)` ou `null` si annulé. Réutilisé par la prise en charge de
/// course (planning livreur). Mêmes règles que la réservation : à partir de
/// demain, sur 14 jours, hors dimanche, plages 08h–12h / 14h–18h.
Future<(DateTime, DateTime)?> showSlotPicker(BuildContext context) {
  return showModalBottomSheet<(DateTime, DateTime)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SlotPickerSheet(),
  );
}

const _plages = <(String, int, int)>[
  ('Matin · 08h–12h', 8, 12),
  ('Après-midi · 14h–18h', 14, 18),
];

class _SlotPickerSheet extends StatefulWidget {
  const _SlotPickerSheet();
  @override
  State<_SlotPickerSheet> createState() => _SlotPickerSheetState();
}

class _SlotPickerSheetState extends State<_SlotPickerSheet> {
  late final DateTime _firstDay;
  late final DateTime _lastDay;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  int _slotIndex = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
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

  void _confirm() {
    final d = _selectedDay;
    if (d == null) return;
    final start = DateTime(d.year, d.month, d.day, _plages[_slotIndex].$2);
    final end = DateTime(d.year, d.month, d.day, _plages[_slotIndex].$3);
    Navigator.of(context).pop((start, end));
  }

  @override
  Widget build(BuildContext context) {
    final d = _selectedDay;
    final recap = d == null
        ? ''
        : formatSlot(
            DateTime(d.year, d.month, d.day, _plages[_slotIndex].$2),
            DateTime(d.year, d.month, d.day, _plages[_slotIndex].$3),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Choisis un créneau',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TableCalendar(
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.twoWeeks,
            availableCalendarFormats: const {CalendarFormat.twoWeeks: '2 sem.'},
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
                formatButtonVisible: false, titleCentered: true),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (var i = 0; i < _plages.length; i++)
                ChoiceChip(
                  label: Text(_plages[i].$1),
                  selected: _slotIndex == i,
                  onSelected: (_) => setState(() => _slotIndex = i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.event_available),
              label: Text('Confirmer · $recap'),
            ),
          ),
        ],
      ),
    );
  }
}
