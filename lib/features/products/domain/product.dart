/// Modes de vente possibles d'un produit (côté base : colonne `sale_mode`).
const kSaleModes = ['detail', 'gros', 'les_deux'];

/// Libellé lisible d'un mode de vente. Ex. : `saleModeLabel('gros')` → « En gros ».
String saleModeLabel(String mode) => switch (mode) {
      'gros' => 'En gros',
      'les_deux' => 'Gros & détail',
      _ => 'En détail',
    };

/// Modèle d'un produit d'une boutique (table `products`).
class Product {
  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    this.description,
    this.category,
    this.unit = 'unité',
    this.price = 0,
    this.stock = 0,
    this.imageUrl,
    this.isActive = true,
    this.promoPrice,
    this.saleMode = 'detail',
  });

  final String id;
  final String shopId;
  final String name;
  final String? description;
  final String? category;
  final String unit; // kg, sac, litre, unité...
  final double price; // en FCFA
  final double stock; // quantité disponible
  final String? imageUrl;
  final bool isActive;
  final double? promoPrice; // prix promo (anti-gaspillage), null = pas de promo
  final String saleMode; // detail / gros / les_deux

  bool get inStock => stock > 0;

  /// Libellé du mode de vente. Ex. : « En gros ».
  String get saleModeLabelText => saleModeLabel(saleMode);

  /// Promo active : prix promo positif et inférieur au prix normal.
  bool get hasPromo =>
      promoPrice != null && promoPrice! > 0 && promoPrice! < price;

  /// Prix effectivement payé (promo si active).
  double get effectivePrice => hasPromo ? promoPrice! : price;

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      unit: map['unit'] as String? ?? 'unité',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      promoPrice: (map['promo_price'] as num?)?.toDouble(),
      saleMode: map['sale_mode'] as String? ?? 'detail',
    );
  }

  /// Champs modifiables (insert + update). L'id est généré par la base.
  Map<String, dynamic> toWriteMap() => {
        'shop_id': shopId,
        'name': name,
        'description': description,
        'category': category,
        'unit': unit,
        'price': price,
        'stock': stock,
        'image_url': imageUrl,
        'is_active': isActive,
        'promo_price': promoPrice,
        'sale_mode': saleMode,
      };
}
