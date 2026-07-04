import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_audit_screen.dart';
import '../../features/admin/presentation/admin_broadcast_screen.dart';
import '../../features/admin/presentation/admin_kyc_screen.dart';
import '../../features/admin/presentation/admin_products_screen.dart';
import '../../features/admin/presentation/admin_reviews_screen.dart';
import '../../features/admin/presentation/admin_shops_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/auth/presentation/guest_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_controller.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/success_screen.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/profile/presentation/kyc_screen.dart';
import '../../features/profile/presentation/profile_edit_screen.dart';
import '../../features/catalog/domain/catalog_product.dart';
import '../../features/catalog/presentation/product_detail_screen.dart';
import '../../features/catalog/presentation/search_screen.dart';
import '../../features/catalog/presentation/shop_detail_screen.dart';
import '../../features/dashboard/presentation/seller_dashboard_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/map/presentation/nearby_map_screen.dart';
import '../../features/orders/domain/order.dart';
import '../../features/orders/presentation/courier_courses_screen.dart';
import '../../features/orders/presentation/my_orders_screen.dart';
import '../../features/orders/presentation/order_tracking_screen.dart';
import '../../features/orders/presentation/shop_orders_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/reservations/presentation/fake_payment_screen.dart';
import '../../features/reservations/presentation/my_reservations_screen.dart';
import '../../features/reservations/presentation/reserve_screen.dart';
import '../../features/reservations/presentation/shop_reservations_screen.dart';
import '../../features/requests/presentation/create_request_screen.dart';
import '../../features/requests/presentation/request_detail_screen.dart';
import '../../features/requests/presentation/requests_hub_screen.dart';
import '../../features/tutorial/presentation/tutorial_screen.dart';
import '../../features/products/domain/product.dart';
import '../../features/products/presentation/product_form_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/shops/domain/shop.dart';
import '../../features/shops/presentation/my_shop_screen.dart';
import '../../features/shops/presentation/shop_form_screen.dart';
import '../constants/app_constants.dart';
import '../providers/supabase_provider.dart';
import 'routes.dart';

/// Écoute la session locale + l'attente 2FA pour rafraîchir le router.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(otpPendingProvider, (_, __) => notifyListeners());
    _ref.listen(guestModeProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(GoRouterState state) {
    final session = _ref.read(currentSessionProvider);
    final otpPending = _ref.read(otpPendingProvider);
    final guest = _ref.read(guestModeProvider);
    final loc = state.matchedLocation;
    final onAuthPage = loc == AppRoutes.login || loc == AppRoutes.register;
    final onOtpPage = loc == AppRoutes.otp;
    final onWelcome = loc == AppRoutes.welcome;

    // Non connecté :
    if (session == null) {
      // Mode visiteur : accès libre à l'app (les actions réservées sont
      // verrouillées dans les écrans eux-mêmes).
      if (guest) return null;
      // Sinon : seuls welcome / login / register sont accessibles.
      return (onWelcome || onAuthPage) ? null : AppRoutes.welcome;
    }
    // Connecté mais 2FA en attente : forcer l'écran OTP.
    if (otpPending) {
      return onOtpPage ? null : AppRoutes.otp;
    }
    // Connecté + vérifié : pas de raison de rester sur welcome/login/register/otp.
    if (onWelcome || onAuthPage || onOtpPage) return AppRoutes.home;
    return null;
  }
}

/// Configuration de navigation (go_router).
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: notifier,
    redirect: (context, state) => notifier.redirect(state),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => _fade(state, const MainShell()),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) => _fade(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _fade(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => _fade(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        pageBuilder: (context, state) => _fade(state, const OtpScreen()),
      ),
      GoRoute(
        path: AppRoutes.success,
        name: 'success',
        pageBuilder: (context, state) => _fade(state, const SuccessScreen()),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        // extra = catégorie initiale optionnelle (String)
        pageBuilder: (context, state) =>
            _fade(state, SearchScreen(initialCategory: state.extra as String?)),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        name: 'productDetail',
        // extra = CatalogProduct
        pageBuilder: (context, state) => _fade(
          state,
          ProductDetailScreen(product: state.extra as CatalogProduct),
        ),
      ),
      GoRoute(
        path: AppRoutes.shopView,
        name: 'shopView',
        // extra = shopId (String)
        pageBuilder: (context, state) =>
            _fade(state, ShopDetailScreen(shopId: state.extra as String)),
      ),

      // --- Demandes instantanées ---
      GoRoute(
        path: AppRoutes.requests,
        name: 'requests',
        pageBuilder: (context, state) => _fade(state, const RequestsHubScreen()),
      ),
      GoRoute(
        path: AppRoutes.requestNew,
        name: 'requestNew',
        pageBuilder: (context, state) =>
            _fade(state, const CreateRequestScreen()),
      ),
      GoRoute(
        path: AppRoutes.requestDetail,
        name: 'requestDetail',
        // extra = requestId (String)
        pageBuilder: (context, state) =>
            _fade(state, RequestDetailScreen(requestId: state.extra as String)),
      ),

      // --- Réservations + paiement simulé ---
      GoRoute(
        path: AppRoutes.reservations,
        name: 'reservations',
        pageBuilder: (context, state) =>
            _fade(state, const MyReservationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.reserve,
        name: 'reserve',
        // extra = CatalogProduct
        pageBuilder: (context, state) =>
            _fade(state, ReserveScreen(product: state.extra as CatalogProduct)),
      ),
      GoRoute(
        path: AppRoutes.payment,
        name: 'payment',
        // extra = (montant: double, libellé: String)
        pageBuilder: (context, state) {
          final args = state.extra as (double, String);
          return _fade(
              state, FakePaymentScreen(amount: args.$1, label: args.$2));
        },
      ),
      GoRoute(
        path: AppRoutes.shopReservations,
        name: 'shopReservations',
        // extra = shopId (String)
        pageBuilder: (context, state) =>
            _fade(state, ShopReservationsScreen(shopId: state.extra as String)),
      ),

      // --- Notifications ---
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (context, state) =>
            _fade(state, const NotificationsScreen()),
      ),

      // --- Historique des actions ---
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) =>
            _fade(state, const ActivityScreen()),
      ),

      // --- Vérification d'identité (KYC) ---
      GoRoute(
        path: AppRoutes.kyc,
        name: 'kyc',
        pageBuilder: (context, state) => _fade(state, const KycScreen()),
      ),

      // --- Édition du profil (avatar + infos) ---
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profileEdit',
        pageBuilder: (context, state) =>
            _fade(state, const ProfileEditScreen()),
      ),

      // --- Back-office admin ---
      GoRoute(
        path: AppRoutes.adminUsers,
        name: 'adminUsers',
        pageBuilder: (context, state) =>
            _fade(state, const AdminUsersScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminShops,
        name: 'adminShops',
        pageBuilder: (context, state) =>
            _fade(state, const AdminShopsScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminProducts,
        name: 'adminProducts',
        pageBuilder: (context, state) =>
            _fade(state, const AdminProductsScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminKyc,
        name: 'adminKyc',
        pageBuilder: (context, state) =>
            _fade(state, const AdminKycScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminReviews,
        name: 'adminReviews',
        pageBuilder: (context, state) =>
            _fade(state, const AdminReviewsScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminBroadcast,
        name: 'adminBroadcast',
        pageBuilder: (context, state) =>
            _fade(state, const AdminBroadcastScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminAudit,
        name: 'adminAudit',
        pageBuilder: (context, state) =>
            _fade(state, const AdminAuditScreen()),
      ),

      // --- Carte de proximité (géolocalisation) ---
      GoRoute(
        path: AppRoutes.map,
        name: 'map',
        pageBuilder: (context, state) =>
            _fade(state, const NearbyMapScreen()),
      ),

      // --- Tableau de bord commerçant ---
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) =>
            _fade(state, const SellerDashboardScreen()),
      ),

      // --- Livraison / commandes ---
      GoRoute(
        path: AppRoutes.orders,
        name: 'orders',
        pageBuilder: (context, state) =>
            _fade(state, const MyOrdersScreen()),
      ),
      GoRoute(
        path: AppRoutes.courses,
        name: 'courses',
        pageBuilder: (context, state) =>
            _fade(state, const CourierCoursesScreen()),
      ),
      GoRoute(
        path: AppRoutes.orderTracking,
        name: 'orderTracking',
        // extra = Order
        pageBuilder: (context, state) =>
            _fade(state, OrderTrackingScreen(order: state.extra as Order)),
      ),
      GoRoute(
        path: AppRoutes.shopOrders,
        name: 'shopOrders',
        // extra = shopId (String)
        pageBuilder: (context, state) =>
            _fade(state, ShopOrdersScreen(shopId: state.extra as String)),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        name: 'tutorial',
        // extra = UserRole optionnel (ex: depuis « Revoir le tuto »)
        pageBuilder: (context, state) =>
            _fade(state, TutorialScreen(role: state.extra as UserRole?)),
      ),

      // --- Espace boutique (propriétaire) ---
      GoRoute(
        path: AppRoutes.myShop,
        name: 'myShop',
        pageBuilder: (context, state) => _fade(state, const MyShopScreen()),
      ),
      GoRoute(
        path: AppRoutes.shopForm,
        name: 'shopForm',
        // extra = la boutique à éditer (null = création)
        pageBuilder: (context, state) =>
            _fade(state, ShopFormScreen(existing: state.extra as Shop?)),
      ),
      GoRoute(
        path: AppRoutes.shopProducts,
        name: 'shopProducts',
        pageBuilder: (context, state) => _fade(state, const ProductsScreen()),
      ),
      GoRoute(
        path: AppRoutes.productForm,
        name: 'productForm',
        // extra = (shopId, produit à éditer ?)
        pageBuilder: (context, state) {
          final args = state.extra as (String, Product?)?;
          if (args == null) {
            return _fade(
              state,
              const Scaffold(
                body: Center(child: Text('Aucun produit sélectionné')),
              ),
            );
          }
          return _fade(
            state,
            ProductFormScreen(shopId: args.$1, existing: args.$2),
          );
        },
      ),
    ],
  );
});

/// Page avec **transition fluide** (fondu + léger glissement vers le haut),
/// appliquée à toutes les routes de l'app.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
