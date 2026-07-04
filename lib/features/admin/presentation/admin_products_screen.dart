import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../products/domain/product.dart';
import '../data/admin_repository.dart';

/// Modération des produits : masquer / republier (interrupteur).
class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, Product p) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setProductActive(p.id, !p.isActive);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminStatsProvider);
      ref.invalidate(allProductsProvider); // catalogue public
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(p.isActive
              ? 'Produit masqué du catalogue.'
              : 'Produit republié.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Produits')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async => ref.invalidate(adminProductsProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (items) {
            if (items.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 60),
                EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucun produit',
                  message: 'Les produits publiés apparaîtront ici.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final (p, shopName) = items[i];
                return Card(
                  child: SwitchListTile(
                    value: p.isActive,
                    onChanged: (_) => _toggle(context, ref, p),
                    secondary: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 44,
                        width: 44,
                        child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                            ? AppImage(
                                url: p.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const _Thumb(),
                                errorWidget: (_, __, ___) => const _Thumb(),
                              )
                            : const _Thumb(),
                      ),
                    ),
                    title: Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '$shopName · ${formatFcfa(p.effectivePrice)} / ${p.unit}'
                      '${p.isActive ? '' : ' · MASQUÉ'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            p.isActive ? AppColors.body : AppColors.danger,
                        fontWeight:
                            p.isActive ? FontWeight.w400 : FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.beige.withValues(alpha: 0.18),
      child: const Icon(Icons.image_outlined,
          size: 20, color: AppColors.beige),
    );
  }
}
