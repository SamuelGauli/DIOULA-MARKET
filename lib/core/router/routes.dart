/// Chemins (paths) et noms de routes de l'application.
/// On remplit au fur et à mesure des étapes (auth, boutiques, demandes, etc.).
class AppRoutes {
  AppRoutes._();

  static const home = '/';

  // Auth
  static const welcome = '/welcome'; // onboarding (non connecté)
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp'; // 2FA SMS simulée
  static const success = '/success'; // succès + confettis (après 2FA)
  static const tutorial = '/tutorial'; // mini-tuto par rôle (après inscription)

  // Profil
  static const profile = '/profile';
  static const profileEdit = '/profile/edit'; // modifier profil (avatar, infos)

  // Catalogue (consultation publique)
  static const search = '/search'; // recherche produits
  static const productDetail = '/product'; // fiche produit (extra = CatalogProduct)
  static const shopView = '/shop/view'; // fiche boutique (extra = shopId)

  // Boutiques & produits (espace propriétaire)
  static const myShop = '/shop';
  static const shopForm = '/shop/form';
  static const shopProducts = '/shop/products';
  static const productForm = '/shop/products/form';

  // Demandes instantanées
  static const requests = '/requests'; // hub (adapté au rôle)
  static const requestNew = '/requests/new'; // création d'une demande
  static const requestDetail = '/requests/detail'; // détail (extra = requestId)

  // Réservations
  static const reservations = '/reservations'; // mes réservations (acheteur)
  static const reserve = '/reserve'; // écran de réservation (extra = CatalogProduct)
  static const payment = '/payment'; // paiement simulé (extra = (montant, libellé))
  static const shopReservations = '/shop/reservations'; // reçues (extra = shopId)

  // Notifications
  static const notifications = '/notifications';

  // Historique des actions
  static const history = '/history';

  // Vérification d'identité (KYC)
  static const kyc = '/kyc';

  // Carte
  static const map = '/map';

  // Dashboard commerçant
  static const dashboard = '/dashboard';

  // Livraison / commandes
  static const orders = '/orders'; // mes commandes (acheteur)
  static const courses = '/courses'; // espace livreur (pool + mes courses)
  static const orderTracking = '/order'; // suivi d'une commande (extra = Order)
  static const shopOrders = '/shop/orders'; // commandes reçues (extra = shopId)

  // Back-office admin (écrans poussés depuis les onglets admin)
  static const adminUsers = '/admin/users'; // modération des comptes
  static const adminShops = '/admin/shops'; // modération des boutiques
  static const adminProducts = '/admin/products'; // modération des produits
  static const adminKyc = '/admin/kyc'; // validation des identités (KYC)
  static const adminReviews = '/admin/reviews'; // modération des avis
  static const adminBroadcast = '/admin/broadcast'; // annonce à tous
  static const adminAudit = '/admin/audit'; // journal d'audit global
}
