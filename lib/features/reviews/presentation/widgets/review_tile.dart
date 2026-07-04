import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/review.dart';
import 'star_rating.dart';

/// Une ligne d'avis : auteur (avatar + nom), note, date relative, commentaire.
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final avatar = review.authorAvatar;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(name: review.authorName, url: avatar, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(review.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text(_ago(review.createdAt),
                        style: const TextStyle(
                            color: AppColors.body, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                StarsDisplay(rating: review.rating.toDouble(), size: 15),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(review.comment!,
                      style: const TextStyle(color: AppColors.body, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ago(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 1) return 'il y a ${diff.inDays} j';
    if (diff.inHours >= 1) return 'il y a ${diff.inHours} h';
    if (diff.inMinutes >= 1) return 'il y a ${diff.inMinutes} min';
    return 'à l\'instant';
  }
}
