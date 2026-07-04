import '../../../core/utils/format.dart';

/// Produit enrichi pour le catalogue : champs du produit + infos de sa
/// boutique (nom, commune, note) obtenues via une jointure Supabase.
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.shopId,
    required this.name,
    required this.unit,
    required this.price,
    required this.stock,
    this.description,
    this.category,
    this.imageUrl,
    this.promoPrice,
    this.saleMode = 'detail',
    this.shopName = 'Boutique',
    this.shopCommune,
    this.shopRating = 0,
    this.shopRatingCount = 0,
    this.shopLat,
    this.shopLng,
  });

  final String id;
  final String shopId;
  final String name;
  final String unit;
  final double price;
  final double stock;
  final String? description;
  final String? category;
  final String? imageUrl;
  final double? promoPrice;
  final String saleMode; // detail / gros / les_deux

  final String shopName;
  final String? shopCommune;
  final double shopRating;
  final int shopRatingCount;
  final double? shopLat;
  final double? shopLng;

  bool get inStock => stock > 0;

  /// Promo active : prix promo positif et inférieur au prix normal.
  bool get hasPromo =>
      promoPrice != null && promoPrice! > 0 && promoPrice! < price;

  /// Prix effectivement payé (promo si active).
  double get effectivePrice => hasPromo ? promoPrice! : price;

  String get priceLabel => formatFcfa(effectivePrice);
  String get originalPriceLabel => formatFcfa(price);

  factory CatalogProduct.fromMap(Map<String, dynamic> map) {
    final shop = map['shops'] as Map<String, dynamic>?;
    return CatalogProduct(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      name: map['name'] as String,
      unit: map['unit'] as String? ?? 'unité',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String?,
      category: map['category'] as String?,
      imageUrl: map['image_url'] as String?,
      promoPrice: (map['promo_price'] as num?)?.toDouble(),
      saleMode: map['sale_mode'] as String? ?? 'detail',
      shopName: shop?['name'] as String? ?? 'Boutique',
      shopCommune: shop?['commune'] as String?,
      shopRating: (shop?['rating_avg'] as num?)?.toDouble() ?? 0,
      shopRatingCount: (shop?['rating_count'] as num?)?.toInt() ?? 0,
      shopLat: (shop?['latitude'] as num?)?.toDouble(),
      shopLng: (shop?['longitude'] as num?)?.toDouble(),
    );
  }
}
