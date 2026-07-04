import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../shops/domain/shop.dart';
import '../data/admin_repository.dart';

/// Modération des boutiques : suspendre / réactiver (interrupteur).
class AdminShopsScreen extends ConsumerWidget {
  const AdminShopsScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, Shop s) async {
    try {
      await ref.read(adminRepositoryProvider).setShopActive(s.id, !s.isActive);
      ref.invalidate(adminShopsProvider);
      ref.invalidate(adminStatsProvider);
      ref.invalidate(allShopsProvider); // catalogue public
      ref.invalidate(allProductsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.isActive
              ? 'Boutique suspendue (invisible du catalogue).'
              : 'Boutique réactivée.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminShopsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Boutiques')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async => ref.invalidate(adminShopsProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (shops) {
            if (shops.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 60),
                EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'Aucune boutique',
                  message: 'Les boutiques créées apparaîtront ici.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: shops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = shops[i];
                return Card(
                  child: SwitchListTile(
                    value: s.isActive,
                    onChanged: (_) => _toggle(context, ref, s),
                    secondary: CircleAvatar(
                      backgroundColor: AppColors.clay.withValues(alpha: 0.14),
                      child: Text(
                        s.name.isEmpty
                            ? '?'
                            : s.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.clay,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      [
                        if (s.category != null && s.category!.isNotEmpty)
                          s.category!,
                        if (s.commune != null && s.commune!.isNotEmpty)
                          s.commune!,
                        s.isActive ? 'Active' : 'SUSPENDUE',
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            s.isActive ? AppColors.body : AppColors.danger,
                        fontWeight:
                            s.isActive ? FontWeight.w400 : FontWeight.w700,
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
