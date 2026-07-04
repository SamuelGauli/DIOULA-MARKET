/// Statistiques globales de la plateforme (RPC `admin_stats`, step22).
class AdminStats {
  const AdminStats({
    required this.usersTotal,
    required this.usersByRole,
    required this.kycPending,
    required this.shopsTotal,
    required this.shopsActive,
    required this.productsTotal,
    required this.productsActive,
    required this.ordersTotal,
    required this.ordersByStatus,
    required this.gmv,
    required this.reservationsTotal,
    required this.requestsOpen,
    required this.reviewsTotal,
  });

  final int usersTotal;
  final Map<String, int> usersByRole; // rôle -> nombre
  final int kycPending;
  final int shopsTotal;
  final int shopsActive;
  final int productsTotal;
  final int productsActive;
  final int ordersTotal;
  final Map<String, int> ordersByStatus; // statut -> nombre
  final double gmv; // CA des commandes livrées (FCFA)
  final int reservationsTotal;
  final int requestsOpen;
  final int reviewsTotal;

  int get shopsSuspended => shopsTotal - shopsActive;

  factory AdminStats.fromMap(Map<String, dynamic> map) {
    Map<String, int> counts(dynamic v) => (v as Map<String, dynamic>? ?? {})
        .map((k, n) => MapEntry(k, (n as num).toInt()));
    int i(String k) => (map[k] as num?)?.toInt() ?? 0;

    return AdminStats(
      usersTotal: i('users_total'),
      usersByRole: counts(map['users_by_role']),
      kycPending: i('kyc_pending'),
      shopsTotal: i('shops_total'),
      shopsActive: i('shops_active'),
      productsTotal: i('products_total'),
      productsActive: i('products_active'),
      ordersTotal: i('orders_total'),
      ordersByStatus: counts(map['orders_by_status']),
      gmv: (map['gmv'] as num?)?.toDouble() ?? 0,
      reservationsTotal: i('reservations_total'),
      requestsOpen: i('requests_open'),
      reviewsTotal: i('reviews_total'),
    );
  }
}
