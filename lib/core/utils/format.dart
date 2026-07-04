import 'package:intl/intl.dart';

final _fcfa = NumberFormat.decimalPattern('fr');

/// Formate un montant en FCFA avec séparateur de milliers.
/// Ex. : `formatFcfa(18000)` → « 18 000 FCFA ».
String formatFcfa(num value) => '${_fcfa.format(value)} FCFA';

/// Formate une quantité (sans décimales inutiles). Ex. : 20.0 → « 20 ».
String formatQty(num value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

const _slotDays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _slotMonths = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
];

/// Jour lisible. Ex. : « mer. 3 juil. ».
String formatDay(DateTime d) =>
    '${_slotDays[d.weekday - 1]} ${d.day} ${_slotMonths[d.month - 1]}';

/// Plage horaire d'un créneau. Ex. : « 08h–12h ».
String formatSlotTime(DateTime start, DateTime end) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(start.hour)}h–${two(end.hour)}h';
}

/// Libellé d'un créneau. Ex. : « mer. 3 juil. · 08h–12h ».
String formatSlot(DateTime start, DateTime end) =>
    '${formatDay(start)} · ${formatSlotTime(start, end)}';
