import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/location_service.dart';
import '../data/map_repository.dart';
import '../domain/nearby_shop.dart';
import 'widgets/nearby_shop_tile.dart';

/// Carte de proximité (étape 7) : centrée sur la position GPS réelle de
/// l'utilisateur, avec les boutiques proches en marqueurs + une liste triée
/// par distance. Données via la fonction SQL `nearby_shops` (Haversine).
class NearbyMapScreen extends ConsumerStatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  ConsumerState<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends ConsumerState<NearbyMapScreen> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _openShop(String shopId) =>
      context.push(AppRoutes.shopView, extra: shopId);

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Autour de moi')),
      body: positionAsync.when(
        loading: () => const _Loading(),
        error: (e, _) => _LocationError(error: e),
        data: (pos) => _MapView(
          position: pos,
          controller: _mapController,
          onOpenShop: _openShop,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  ÉTAT : LOCALISATION EN COURS
// ---------------------------------------------------------------------------
class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.clay),
          SizedBox(height: 16),
          Text('Localisation en cours…',
              style: TextStyle(color: AppColors.body)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  ÉTAT : ERREUR DE LOCALISATION (service coupé / permission refusée)
// ---------------------------------------------------------------------------
class _LocationError extends ConsumerWidget {
  const _LocationError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = error is LocationFailure ? error as LocationFailure : null;
    final message =
        failure?.message ?? 'Impossible de te localiser. Réessaie.';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyState(
            icon: Icons.location_off_outlined,
            title: 'Localisation indisponible',
            message: message,
            actionLabel: 'Réessayer',
            onAction: () => ref.invalidate(currentPositionProvider),
          ),
          if (failure?.permanentlyDenied ?? false)
            TextButton.icon(
              onPressed: () =>
                  ref.read(locationServiceProvider).openSettings(),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Ouvrir les réglages'),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  CARTE + LISTE
// ---------------------------------------------------------------------------
class _MapView extends ConsumerWidget {
  const _MapView({
    required this.position,
    required this.controller,
    required this.onOpenShop,
  });

  final LatLng position;
  final MapController controller;
  final void Function(String shopId) onOpenShop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(nearbyShopsProvider);
    final shops = shopsAsync.value ?? const <NearbyShop>[];

    final panelHeight =
        (MediaQuery.of(context).size.height * 0.36).clamp(220.0, 360.0);

    return Stack(
      children: [
        // ---- Carte OpenStreetMap ----
        FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: position,
            initialZoom: 12,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.dioula.market',
            ),
            MarkerLayer(
              markers: [
                // Position de l'utilisateur.
                Marker(
                  point: position,
                  width: 26,
                  height: 26,
                  child: const _UserDot(),
                ),
                // Boutiques proches.
                for (final s in shops)
                  Marker(
                    point: LatLng(s.latitude, s.longitude),
                    width: 44,
                    height: 44,
                    child: _ShopMarker(onTap: () => onOpenShop(s.id)),
                  ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap'),
              ],
            ),
          ],
        ),

        // ---- Chips de rayon (en haut) ----
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: const _RadiusChips(),
        ),

        // ---- Bouton « recentrer » (au-dessus du panneau) ----
        Positioned(
          right: 16,
          bottom: panelHeight + 12,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.clay,
            onPressed: () => controller.move(position, 13),
            child: const Icon(Icons.my_location),
          ),
        ),

        // ---- Panneau liste (en bas) ----
        Align(
          alignment: Alignment.bottomCenter,
          child: _ShopsPanel(
            height: panelHeight,
            shopsAsync: shopsAsync,
            onOpenShop: onOpenShop,
          ),
        ),
      ],
    );
  }
}

/// Point bleu pulsant de la position utilisateur.
class _UserDot extends StatelessWidget {
  const _UserDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.info,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

/// Marqueur d'une boutique (pastille blanche + icône terracotta).
class _ShopMarker extends StatelessWidget {
  const _ShopMarker({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.clay, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.storefront, color: AppColors.clay, size: 22),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  CHIPS DE RAYON
// ---------------------------------------------------------------------------
class _RadiusChips extends ConsumerWidget {
  const _RadiusChips();

  static const _options = <(String, double)>[
    ('5 km', 5),
    ('10 km', 10),
    ('25 km', 25),
    ('Tout', kShowAllRadiusKm),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = ref.watch(selectedRadiusProvider);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, value) = _options[i];
          final selected = radius == value;
          return GestureDetector(
            onTap: () => ref.read(selectedRadiusProvider.notifier).set(value),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? AppColors.clay : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  PANNEAU LISTE DES BOUTIQUES
// ---------------------------------------------------------------------------
class _ShopsPanel extends ConsumerWidget {
  const _ShopsPanel({
    required this.height,
    required this.shopsAsync,
    required this.onOpenShop,
  });

  final double height;
  final AsyncValue<List<NearbyShop>> shopsAsync;
  final void Function(String shopId) onOpenShop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = ref.watch(selectedRadiusProvider);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          // Poignée.
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 4,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.body.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: shopsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: AppColors.clay)),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Erreur : $e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.body)),
                ),
              ),
              data: (shops) {
                if (shops.isEmpty) {
                  return _EmptyShops(radius: radius);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        '${shops.length} boutique${shops.length > 1 ? 's' : ''} à proximité',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: shops.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => NearbyShopTile(
                          shop: shops[i],
                          onTap: () => onOpenShop(shops[i].id),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Liste vide : propose d'élargir le rayon (« Tout voir »).
class _EmptyShops extends ConsumerWidget {
  const _EmptyShops({required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showingAll = radius >= kShowAllRadiusKm;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 40, color: AppColors.body),
            const SizedBox(height: 12),
            Text(
              showingAll
                  ? 'Aucune boutique géolocalisée pour le moment.'
                  : 'Aucune boutique dans ce rayon.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.body),
            ),
            if (!showingAll) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref
                    .read(selectedRadiusProvider.notifier)
                    .set(kShowAllRadiusKm),
                icon: const Icon(Icons.travel_explore),
                label: const Text('Tout voir'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
