import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/presentation/guest_provider.dart';
import '../../auth/presentation/widgets/guest_invite_sheet.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog_product.dart';
import '../../catalog/domain/categories.dart';
import '../../catalog/domain/instant_request.dart';
import '../../catalog/presentation/widgets/product_card.dart';
import '../../catalog/presentation/widgets/shop_card.dart';
import '../../map/data/location_service.dart';
import '../../notifications/presentation/notification_bell_button.dart';
import '../../profile/data/profile_repository.dart';
import '../../shops/domain/shop.dart';

/// Position GPS du consommateur pour trier le flux par proximité — **tolérant** :
/// renvoie `null` si le GPS est refusé/indisponible (repli sur la commune, sans
/// jamais bloquer l'accueil ni lever d'exception). Mise en cache pour la session.
final feedPositionProvider = FutureProvider<LatLng?>((ref) async {
  try {
    return await ref.watch(locationServiceProvider).current();
  } catch (_) {
    return null;
  }
});

/// Compteur d'actualisation : à chaque pull-to-refresh il augmente et fait
/// **tourner la fenêtre** de produits affichés → on voit d'autres articles.
class FeedTick extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state = state + 1;
}

final feedTickProvider = NotifierProvider<FeedTick, int>(FeedTick.new);

/// Filtre « type de vente » du flux consommateur : `tout` / `detail` / `gros`.
class FeedSaleMode extends Notifier<String> {
  @override
  String build() => 'tout';
  void select(String v) => state = v;
}

final feedSaleModeProvider =
    NotifierProvider<FeedSaleMode, String>(FeedSaleMode.new);

/// Un produit correspond-il au filtre choisi ? Un produit « les deux » apparaît
/// dans **En détail** comme dans **En gros**.
bool _matchesSale(CatalogProduct p, String filter) {
  if (filter == 'gros') return p.saleMode == 'gros' || p.saleMode == 'les_deux';
  if (filter == 'detail') {
    return p.saleMode == 'detail' || p.saleMode == 'les_deux';
  }
  return true; // 'tout'
}

/// Trie une liste par **proximité** : si une position est connue, du plus proche
/// au plus loin (éléments sans coordonnées en dernier) ; sinon, ceux de la même
/// **commune** que le consommateur d'abord ; sinon l'ordre d'origine.
List<T> _byProximity<T>(
  List<T> items,
  LatLng? pos,
  String? commune, {
  required double? Function(T) lat,
  required double? Function(T) lng,
  required String? Function(T) itemCommune,
}) {
  final list = [...items];
  if (pos != null) {
    double dist(T e) {
      final la = lat(e), ln = lng(e);
      if (la == null || ln == null) return double.infinity;
      return distanceKm(pos.latitude, pos.longitude, la, ln);
    }

    list.sort((a, b) => dist(a).compareTo(dist(b)));
    return list;
  }
  if (commune != null && commune.trim().isNotEmpty) {
    final c = commune.trim().toLowerCase();
    bool here(T e) => (itemCommune(e) ?? '').trim().toLowerCase() == c;
    final near = list.where(here).toList();
    final rest = list.where((e) => !here(e)).toList();
    return [...near, ...rest];
  }
  return list;
}

/// Fenêtre glissante de `take` éléments démarrant à `tick*take` (avec bouclage) :
/// chaque actualisation révèle la tranche suivante du catalogue.
List<T> _window<T>(List<T> items, int take, int tick) {
  if (items.length <= take) return items;
  final start = (tick * take) % items.length;
  return [for (var i = 0; i < take; i++) items[(start + i) % items.length]];
}

/// Onglet « Accueil » — vitrine riche (style food app) consultable en visiteur :
/// en-tête, recherche, services, carrousel promo, catégories et sections
/// vivantes (en vedette, près de vous, producteurs, meilleures notes, demandes).
class HomeFeedPage extends ConsumerWidget {
  const HomeFeedPage({super.key, required this.onOpenShop});

  /// Ouvre l'onglet Boutique (depuis le service « Vendre »).
  final VoidCallback onOpenShop;

  Future<void> _refresh(WidgetRef ref) async {
    // Fait tourner la fenêtre affichée → d'autres articles apparaissent.
    ref.read(feedTickProvider.notifier).bump();
    ref.invalidate(allProductsProvider);
    ref.invalidate(allShopsProvider);
    ref.invalidate(producerShopsProvider);
    ref.invalidate(openRequestsProvider);
    ref.invalidate(currentProfileProvider);
    await Future.wait([
      ref.read(allProductsProvider.future),
      ref.read(allShopsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final profile = isGuest ? null : ref.watch(currentProfileProvider).value;
    final name =
        profile?.displayName ?? (isGuest ? 'Invité' : 'Bienvenue');
    final location = profile?.commune ?? 'Côte d\'Ivoire';

    // Les demandes ne concernent que consommateurs et vendeurs
    // (pas les visiteurs ni les livreurs).
    final role = profile?.role;
    final showRequests =
        !isGuest && (role?.isConsumer == true || role?.isSeller == true);

    final productsAsync = ref.watch(allProductsProvider);
    final shopsAsync = ref.watch(allShopsProvider);
    final producersAsync = ref.watch(producerShopsProvider);
    final requestsAsync = showRequests ? ref.watch(openRequestsProvider) : null;

    // Proximité (GPS d'abord, repli commune) + fenêtre d'actualisation.
    final position = ref.watch(feedPositionProvider).value;
    final tick = ref.watch(feedTickProvider);
    final commune = profile?.commune;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.clay,
          onRefresh: () async {
            await _refresh(ref);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Flux mis à jour'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
            }
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: _Header(
                  name: name,
                  location: location,
                  avatarUrl: profile?.avatarUrl,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SearchBarButton(
                  onTap: () => context.push(AppRoutes.search),
                ),
              ),
              const SizedBox(height: 20),
              _ServicesRow(onOpenShop: onOpenShop),
              const SizedBox(height: 22),
              const _PromoCarousel(),
              const SizedBox(height: 8),
              _Categories(
                onSelect: (c) =>
                    context.push(AppRoutes.search, extra: c.label),
              ),
              const SizedBox(height: 12),
              const _SaleModeFilter(),
              const SizedBox(height: 4),

              // ---- En vedette (produits) ----
              _SectionPadding(
                child: SectionHeader(
                  title: 'En vedette',
                  subtitle: position != null
                      ? 'Au plus près de toi'
                      : 'Les produits du moment',
                  actionLabel: 'Voir tout',
                  onAction: () => context.push(AppRoutes.search),
                ),
              ),
              const SizedBox(height: 12),
              _ProductRail(
                async: productsAsync,
                take: 12,
                proximity: true,
                position: position,
                commune: commune,
                tick: tick,
              ),

              // ---- Près de vous (boutiques) ----
              const SizedBox(height: 20),
              _SectionPadding(
                child: SectionHeader(
                  title: 'Près de vous',
                  subtitle: 'Boutiques & marchés',
                  actionLabel: 'Voir la carte',
                  onAction: () => context.push(AppRoutes.map),
                ),
              ),
              const SizedBox(height: 12),
              _ShopRail(
                async: shopsAsync,
                proximity: true,
                position: position,
                commune: commune,
              ),

              // ---- Producteurs locaux ----
              const SizedBox(height: 20),
              const _SectionPadding(
                child: SectionHeader(
                  title: 'Producteurs locaux',
                  subtitle: 'Directement de la ferme',
                ),
              ),
              const SizedBox(height: 12),
              _ShopRail(async: producersAsync, emptyHint: 'Aucun producteur'),

              // ---- Meilleures notes (produits triés par note boutique) ----
              const SizedBox(height: 20),
              const _SectionPadding(
                child: SectionHeader(
                  title: 'Meilleures notes',
                  subtitle: 'Les mieux évalués',
                ),
              ),
              const SizedBox(height: 12),
              _ProductRail(async: productsAsync, take: 8, byRating: true),

              // ---- Demandes en cours (consommateurs & vendeurs uniquement) ----
              if (showRequests) ...[
                const SizedBox(height: 20),
                const _SectionPadding(
                  child: SectionHeader(
                    title: 'Demandes en cours',
                    subtitle: 'Des consommateurs cherchent…',
                  ),
                ),
                const SizedBox(height: 8),
                _RequestsList(async: requestsAsync!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Padding latéral standard des sections.
class _SectionPadding extends StatelessWidget {
  const _SectionPadding({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);
}

// ---------------------------------------------------------------------------
//  EN-TÊTE
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.location,
    required this.avatarUrl,
  });

  final String name;
  final String location;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(name: name, url: avatarUrl, radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour 👋',
                  style: TextStyle(color: AppColors.body, fontSize: 12)),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 13, color: AppColors.clay),
                  const SizedBox(width: 2),
                  Text(location,
                      style:
                          const TextStyle(color: AppColors.body, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const NotificationBellButton(),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ---------------------------------------------------------------------------
//  BARRE DE RECHERCHE (bouton)
// ---------------------------------------------------------------------------
class _SearchBarButton extends StatelessWidget {
  const _SearchBarButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.clay),
            const SizedBox(width: 12),
            Text('Rechercher un produit, une boutique…',
                style: TextStyle(color: AppColors.body)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.clay,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  SERVICES
// ---------------------------------------------------------------------------
class _ServicesRow extends ConsumerWidget {
  const _ServicesRow({required this.onOpenShop});
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final role = isGuest
        ? UserRole.consommateur
        : (ref.watch(currentProfileProvider).value?.role ??
            UserRole.consommateur);

    final search = _Service(Icons.search, 'Recherche', AppColors.info,
        () => context.push(AppRoutes.search));

    // Services adaptés au rôle (un consommateur ne « vend » pas, etc.).
    final List<_Service> services;
    if (!isGuest && role.isSeller) {
      services = [
        search,
        _Service(Icons.storefront, 'Ma boutique', AppColors.ocre, onOpenShop),
        _Service(Icons.bolt, 'Demandes', AppColors.clay,
            () => context.push(AppRoutes.requests)),
        _Service(Icons.bar_chart, 'Tableau de bord', AppColors.success,
            () => context.push(AppRoutes.dashboard)),
      ];
    } else if (!isGuest && role.isCourier) {
      services = [
        search,
        _Service(Icons.local_shipping, 'Courses', AppColors.clay,
            () => context.push(AppRoutes.courses)),
        _Service(Icons.map, 'Carte', AppColors.info,
            () => context.push(AppRoutes.map)),
      ];
    } else {
      // Consommateur + visiteur.
      services = [
        search,
        // Carte de proximité : consultable sans compte.
        _Service(Icons.map, 'Carte', AppColors.info,
            () => context.push(AppRoutes.map)),
        // Demandes réservées aux comptes connectés (pas les visiteurs).
        if (!isGuest)
          _Service(Icons.bolt, 'Demande', AppColors.clay,
              () => context.push(AppRoutes.requests)),
        _Service(Icons.event_available, 'Réservations', AppColors.success, () {
          if (requireAccount(context, ref, action: 'voir tes réservations')) {
            context.push(AppRoutes.reservations);
          }
        }),
        _Service(Icons.receipt_long, 'Commandes', AppColors.beigeDeep, () {
          if (requireAccount(context, ref, action: 'suivre tes commandes')) {
            context.push(AppRoutes.orders);
          }
        }),
      ];
    }

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final s = services[i];
          return GestureDetector(
            onTap: s.onTap,
            child: Column(
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(s.icon, color: s.color, size: 26),
                ),
                const SizedBox(height: 6),
                Text(s.label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (i * 60).ms)
              .slideX(begin: 0.3, end: 0, duration: 300.ms);
        },
      ),
    );
  }
}

class _Service {
  const _Service(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

// ---------------------------------------------------------------------------
//  CARROUSEL PROMO
// ---------------------------------------------------------------------------
class _PromoCarousel extends ConsumerStatefulWidget {
  const _PromoCarousel();
  @override
  ConsumerState<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends ConsumerState<_PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _page = 0;

  // Chaque bannière : titre, sous-titre, icône, dégradé de repli, image de fond.
  // L'image (Unsplash, libre) se superpose au dégradé ; si elle échoue à charger,
  // on retombe simplement sur le dégradé (aucune exception ne remonte).
  static const _banners = <(String, String, IconData, List<Color>, String)>[
    (
      'Demande instantanée',
      'Publie ton besoin, les vendeurs répondent en direct.',
      Icons.bolt,
      [Color(0xFFEE8A4E), AppColors.clay],
      'https://images.unsplash.com/photo-1556740738-b6a63e27c4df?auto=format&fit=crop&w=900&q=60',
    ),
    (
      'Produits frais & locaux',
      'Du producteur à ton assiette, au juste prix.',
      Icons.eco,
      [Color(0xFF49B36E), AppColors.success],
      'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=900&q=60',
    ),
    (
      'Livraison près de vous',
      'Des livreurs disponibles dans ta commune.',
      Icons.local_shipping,
      [Color(0xFFE9B44C), AppColors.warning],
      'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=900&q=60',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Défilement automatique (boucle) toutes les 4 s.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _banners.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Destination de chaque bannière (cohérente avec l'accès aux demandes).
  void _open(int i) {
    if (i == 0) {
      // Demande instantanée : réservée aux comptes (consommateur/vendeur).
      if (ref.read(isGuestProvider)) {
        requireAccount(context, ref, action: 'publier une demande');
        return;
      }
      final role = ref.read(currentProfileProvider).value?.role;
      if (role?.isConsumer == true || role?.isSeller == true) {
        context.push(AppRoutes.requests);
      } else {
        context.push(AppRoutes.search); // livreur : repli neutre
      }
    } else if (i == 1) {
      context.push(AppRoutes.search);
    } else {
      context.push(AppRoutes.map);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final b = _banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => _open(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1) Dégradé de repli (visible pendant le chargement ou
                        //    si l'image échoue).
                        DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: LinearGradient(colors: b.$4)),
                        ),
                        // 2) Image de fond (transparente tant qu'elle ne charge
                        //    pas → le dégradé transparaît).
                        CachedNetworkImage(
                          imageUrl: b.$5,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SizedBox.shrink(),
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        // 3) Voile sombre pour la lisibilité du texte blanc.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.62),
                                Colors.black.withValues(alpha: 0.18),
                              ],
                            ),
                          ),
                        ),
                        // 4) Contenu.
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.$1,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(b.$2,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              Icon(b.$3,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 46),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 7,
              width: _page == i ? 20 : 7,
              decoration: BoxDecoration(
                color: _page == i
                    ? AppColors.clay
                    : AppColors.body.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
//  CATÉGORIES
// ---------------------------------------------------------------------------
class _Categories extends StatelessWidget {
  const _Categories({required this.onSelect});
  final void Function(MarketCategory) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionPadding(child: SectionHeader(title: 'Catégories')),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: kCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final c = kCategories[i];
              return CategoryChip(
                icon: c.icon,
                label: c.label,
                color: c.color,
                onTap: () => onSelect(c),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
//  FILTRE GROS / DÉTAIL (divise les sections produits)
// ---------------------------------------------------------------------------
class _SaleModeFilter extends ConsumerWidget {
  const _SaleModeFilter();

  static const _choices = <(String, String, IconData)>[
    ('tout', 'Tout', Icons.grid_view_rounded),
    ('detail', 'En détail', Icons.shopping_basket_outlined),
    ('gros', 'En gros', Icons.inventory_2_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(feedSaleModeProvider);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _choices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _choices[i];
          final active = selected == c.$1;
          return ChoiceChip(
            selected: active,
            onSelected: (_) =>
                ref.read(feedSaleModeProvider.notifier).select(c.$1),
            avatar: Icon(c.$3,
                size: 16, color: active ? Colors.white : AppColors.clay),
            label: Text(c.$2),
            labelStyle: TextStyle(
                color: active ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 12.5),
            selectedColor: AppColors.clay,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  RAIL PRODUITS (liste horizontale + skeleton/empty)
// ---------------------------------------------------------------------------
class _ProductRail extends ConsumerWidget {
  const _ProductRail({
    required this.async,
    this.take = 8,
    this.byRating = false,
    this.proximity = false,
    this.position,
    this.commune,
    this.tick = 0,
  });

  final AsyncValue<List<dynamic>> async;
  final int take;
  final bool byRating;

  /// Trie par proximité (position GPS ou commune) et applique la fenêtre `tick`.
  final bool proximity;
  final LatLng? position;
  final String? commune;
  final int tick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filtre gros/détail choisi par le consommateur (s'applique aux 2 rails).
    final saleFilter = ref.watch(feedSaleModeProvider);
    return SizedBox(
      height: 248,
      child: async.when(
        loading: () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => const SizedBox(
            width: 165,
            child: ProductCardSkeleton(),
          ),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (raw) {
          // raw est une List<CatalogProduct> (typée dynamic pour réutiliser
          // le même rail pour « En vedette » et « Meilleures notes »).
          final all = raw
              .cast<CatalogProduct>()
              .where((p) => _matchesSale(p, saleFilter))
              .toList();
          final List<CatalogProduct> items;
          if (byRating) {
            all.sort((a, b) => b.shopRating.compareTo(a.shopRating));
            items = all.take(take).toList();
          } else if (proximity) {
            final ordered = _byProximity(
              all,
              position,
              commune,
              lat: (p) => p.shopLat,
              lng: (p) => p.shopLng,
              itemCommune: (p) => p.shopCommune,
            );
            items = _window(ordered, take, tick);
          } else {
            items = all.take(take).toList();
          }
          if (items.isEmpty) {
            return const Center(
              child: Text('Aucun produit', style: TextStyle(color: AppColors.body)),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final p = items[i];
              return SizedBox(
                width: 165,
                child: ProductCard(
                  product: p,
                  // Tag unique par rail (un même produit peut figurer dans
                  // « En vedette » ET « Meilleures notes » sur le même écran).
                  heroTag: 'rail${byRating ? 'Top' : 'Feat'}-${p.id}',
                  onTap: () =>
                      context.push(AppRoutes.productDetail, extra: p),
                  onAdd: () => requireAccount(context, ref,
                      action: 'réserver ce produit'),
                ),
              ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.2, end: 0);
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  RAIL BOUTIQUES
// ---------------------------------------------------------------------------
class _ShopRail extends ConsumerWidget {
  const _ShopRail({
    required this.async,
    this.emptyHint = 'Aucune boutique',
    this.proximity = false,
    this.position,
    this.commune,
  });

  final AsyncValue<List<dynamic>> async;
  final String emptyHint;

  /// Trie les boutiques par proximité (position GPS ou commune du consommateur).
  final bool proximity;
  final LatLng? position;
  final String? commune;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 168,
      child: async.when(
        loading: () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => const SizedBox(
            width: 210,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Skeleton(height: 150, radius: 16),
            ),
          ),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (raw) {
          if (raw.isEmpty) {
            return Center(
              child: Text(emptyHint,
                  style: const TextStyle(color: AppColors.body)),
            );
          }
          final shops = proximity
              ? _byProximity(
                  raw.cast<Shop>().toList(),
                  position,
                  commune,
                  lat: (s) => s.latitude,
                  lng: (s) => s.longitude,
                  itemCommune: (s) => s.commune,
                )
              : raw.cast<Shop>().toList();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final s = shops[i];
              return SizedBox(
                width: 210,
                child: ShopCard(
                  shop: s,
                  onTap: () =>
                      context.push(AppRoutes.shopView, extra: s.id),
                ),
              ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.2, end: 0);
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  DEMANDES EN COURS
// ---------------------------------------------------------------------------
class _RequestsList extends ConsumerWidget {
  const _RequestsList({required this.async});
  final AsyncValue<List<InstantRequest>> async;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Skeleton(height: 70, radius: 16),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Erreur : $e'),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: EmptyState(
              icon: Icons.bolt,
              title: 'Aucune demande en cours',
              message: 'Les demandes des consommateurs apparaîtront ici.',
            ),
          );
        }
        return Column(
          children: [
            for (final r in requests)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _RequestCard(
                  request: r,
                  onTap: () {
                    if (requireAccount(context, ref,
                        action: 'voir cette demande')) {
                      context.push(AppRoutes.requestDetail, extra: r.id);
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, this.onTap});
  final InstantRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final qty = request.quantity == null
        ? ''
        : '${formatQty(request.quantity!)} ${request.unit ?? ''} · ';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: AppColors.clay.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt, color: AppColors.clay),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '$qty${request.authorCommune ?? 'Côte d\'Ivoire'} · rayon ${formatQty(request.radiusKm)} km',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.body, fontSize: 12),
                  ),
                ],
              ),
            ),
            const AppBadge(label: 'Ouverte', color: AppColors.success),
          ],
        ),
        ),
      ),
    );
  }
}
