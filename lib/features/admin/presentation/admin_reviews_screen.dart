import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../reviews/domain/review.dart';
import '../../reviews/presentation/widgets/star_rating.dart';
import '../data/admin_repository.dart';

/// Modération des avis : masquer un avis inapproprié (retiré des fiches
/// boutique et exclu du calcul de la note) ou le rétablir.
class AdminReviewsScreen extends ConsumerWidget {
  const AdminReviewsScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, Review r) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setReviewHidden(r.id, !r.isHidden);
      ref.invalidate(adminReviewsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.isHidden
              ? 'Avis rétabli.'
              : 'Avis masqué (retiré des fiches et de la note).')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Avis & commentaires')),
      body: RefreshIndicator(
        color: AppColors.clay,
        onRefresh: () async => ref.invalidate(adminReviewsProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (reviews) {
            if (reviews.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 60),
                EmptyState(
                  icon: Icons.reviews_outlined,
                  title: 'Aucun avis',
                  message: 'Les avis laissés après un achat apparaîtront ici.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ReviewTile(
                review: reviews[i],
                onToggle: () => _toggle(context, ref, reviews[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.onToggle});
  final Review review;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Card(
      color: r.isHidden ? AppColors.danger.withValues(alpha: 0.06) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                    name: r.authorName, url: r.authorAvatar, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      Text(r.isForShop ? 'Avis boutique' : 'Avis acheteur',
                          style: const TextStyle(
                              color: AppColors.body, fontSize: 11)),
                    ],
                  ),
                ),
                StarsDisplay(rating: r.rating.toDouble(), size: 16),
              ],
            ),
            if (r.comment != null && r.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.comment!),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (r.isHidden)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text('MASQUÉ',
                        style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                const Spacer(),
                r.isHidden
                    ? FilledButton.tonalIcon(
                        onPressed: onToggle,
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Rétablir'),
                      )
                    : OutlinedButton.icon(
                        onPressed: onToggle,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger),
                        icon: const Icon(Icons.visibility_off, size: 18),
                        label: const Text('Masquer'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
