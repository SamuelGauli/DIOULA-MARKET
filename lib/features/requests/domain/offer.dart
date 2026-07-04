import '../../../core/constants/app_constants.dart';

/// Offre d'un vendeur en réponse à une demande (table `offers`).
class Offer {
  const Offer({
    required this.id,
    required this.requestId,
    required this.merchantId,
    required this.price,
    required this.status,
    this.shopId,
    this.quantity,
    this.unit,
    this.deliveryDelay,
    this.message,
    this.createdAt,
    this.counterPrice,
  });

  final String id;
  final String requestId;
  final String merchantId;
  final double price;
  final String status; // proposee / contre_proposee / acceptee / refusee
  final String? shopId;
  final double? quantity;
  final String? unit;
  final String? deliveryDelay;
  final String? message;
  final DateTime? createdAt;
  final double? counterPrice; // prix proposé par le client (négociation)

  bool get isPending => status == 'proposee';
  bool get isAccepted => status == 'acceptee';
  bool get isCountered => status == 'contre_proposee';

  OfferStatus get statusEnum => OfferStatus.values.firstWhere(
        (s) => s.value == status,
        orElse: () => OfferStatus.proposee,
      );

  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['id'] as String,
      requestId: map['request_id'] as String,
      merchantId: map['merchant_id'] as String,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'proposee',
      shopId: map['shop_id'] as String?,
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      deliveryDelay: map['delivery_delay'] as String?,
      message: map['message'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      counterPrice: (map['counter_price'] as num?)?.toDouble(),
    );
  }
}
