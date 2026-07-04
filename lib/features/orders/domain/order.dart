import '../../../core/utils/format.dart';

/// Commande (table `orders`), créée à l'acceptation d'une offre (étape 5)
/// puis livrée par un livreur (étape 10). Enrichie de la boutique, de
/// l'acheteur et d'un résumé des lignes via jointure.
class Order {
  const Order({
    required this.id,
    required this.buyerId,
    required this.shopId,
    required this.status,
    required this.totalAmount,
    this.courierId,
    this.deliveryAddress,
    this.createdAt,
    this.slotStart,
    this.slotEnd,
    this.deliveryStep = 0,
    this.shopName = 'Boutique',
    this.buyerName = 'Client',
    this.itemsLabel = '',
  });

  final String id;
  final String buyerId;
  final String shopId;
  final String? courierId;
  final String status; // en_cours / preparee / en_livraison / livree / annulee
  final double totalAmount;
  final String? deliveryAddress;
  final DateTime? createdAt;
  final DateTime? slotStart; // créneau de livraison (planning livreur, 10e)
  final DateTime? slotEnd;
  final int deliveryStep; // 0→5 : progression de la livraison

  final String shopName;
  final String buyerName;
  final String itemsLabel; // ex. « Tomate ×5, Oignon ×6 »

  bool get isDelivering => status == 'en_livraison';
  bool get isDelivered => status == 'livree';

  /// Libellé du créneau si défini (« mer. 3 juil. · 08h–12h »).
  String? get slotLabel => (slotStart != null && slotEnd != null)
      ? formatSlot(slotStart!, slotEnd!)
      : null;

  factory Order.fromMap(Map<String, dynamic> map) {
    final shop = map['shops'] as Map<String, dynamic>?;
    final buyer = map['buyer'] as Map<String, dynamic>?;
    final items = (map['order_items'] as List?) ?? const [];
    final itemsLabel = items.map((e) {
      final m = e as Map<String, dynamic>;
      final qty = (m['quantity'] as num?) ?? 1;
      return '${m['product_name']} ×${formatQty(qty)}';
    }).join(', ');

    return Order(
      id: map['id'] as String,
      buyerId: map['buyer_id'] as String,
      shopId: map['shop_id'] as String,
      courierId: map['courier_id'] as String?,
      status: map['status'] as String? ?? 'en_cours',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      deliveryAddress: map['delivery_address'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      slotStart: map['slot_start'] == null
          ? null
          : DateTime.tryParse(map['slot_start'] as String),
      slotEnd: map['slot_end'] == null
          ? null
          : DateTime.tryParse(map['slot_end'] as String),
      deliveryStep: (map['delivery_step'] as num?)?.toInt() ?? 0,
      shopName: shop?['name'] as String? ?? 'Boutique',
      buyerName: buyer?['full_name'] as String? ?? 'Client',
      itemsLabel: itemsLabel,
    );
  }
}
