import '../../../core/constants/app_constants.dart';
import '../../../core/utils/format.dart';

/// Réservation avec acompte (table `reservations`), enrichie des infos
/// produit/boutique via jointure.
class Reservation {
  const Reservation({
    required this.id,
    required this.productId,
    required this.shopId,
    required this.buyerId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.depositAmount,
    required this.depositPaid,
    required this.refundAmount,
    required this.status,
    this.deadline,
    this.createdAt,
    this.slotStart,
    this.slotEnd,
    this.productName = 'Produit',
    this.productImage,
    this.productUnit = 'unité',
    this.shopName = 'Boutique',
  });

  final String id;
  final String productId;
  final String shopId;
  final String buyerId;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final double depositAmount;
  final bool depositPaid;
  final double refundAmount;
  final String status; // en_attente / payee / terminee / annulee / expiree
  final DateTime? deadline;
  final DateTime? createdAt;
  final DateTime? slotStart; // créneau de livraison/retrait (10d)
  final DateTime? slotEnd;

  /// Libellé du créneau si défini (« mer. 3 juil. · 08h–12h »).
  String? get slotLabel =>
      (slotStart != null && slotEnd != null)
          ? formatSlot(slotStart!, slotEnd!)
          : null;

  final String productName;
  final String? productImage;
  final String productUnit;
  final String shopName;

  double get balance => totalAmount - depositAmount;
  bool get isActive => status == 'payee';

  ReservationStatus get statusEnum => ReservationStatus.values.firstWhere(
        (s) => s.value == status,
        orElse: () => ReservationStatus.enAttente,
      );

  /// Annulable tant qu'il reste plus de 12 h avant l'échéance.
  bool get cancellable {
    if (!isActive || deadline == null) return false;
    return deadline!.difference(DateTime.now()) >
        const Duration(hours: kReservationCancelCutoffHours);
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    final product = map['products'] as Map<String, dynamic>?;
    final shop = map['shops'] as Map<String, dynamic>?;
    return Reservation(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      shopId: map['shop_id'] as String,
      buyerId: map['buyer_id'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      depositAmount: (map['deposit_amount'] as num?)?.toDouble() ?? 0,
      depositPaid: (map['deposit_paid'] as int?) == 1,
      refundAmount: (map['refund_amount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'en_attente',
      deadline: map['deadline'] == null
          ? null
          : DateTime.tryParse(map['deadline'] as String),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      slotStart: map['slot_start'] == null
          ? null
          : DateTime.tryParse(map['slot_start'] as String),
      slotEnd: map['slot_end'] == null
          ? null
          : DateTime.tryParse(map['slot_end'] as String),
      productName: product?['name'] as String? ?? 'Produit',
      productImage: product?['image_url'] as String?,
      productUnit: product?['unit'] as String? ?? 'unité',
      shopName: shop?['name'] as String? ?? 'Boutique',
    );
  }
}
