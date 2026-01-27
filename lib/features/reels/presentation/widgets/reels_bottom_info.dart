import 'package:flutter/material.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';

class ReelsBottomInfo extends StatelessWidget {
  final PostModel post;

  const ReelsBottomInfo({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 70,
      bottom: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username
          GestureDetector(
            onTap: () => NavigationService.toNamed(
              AppRoutes.profile,
              arguments: {'userId': post.userId},
            ),
            child: Row(
              children: [
                Text(
                  '@${post.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Takip Et',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Caption
          if (post.caption != null && post.caption!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                shadows: [Shadow(color: Colors.black, blurRadius: 8)],
              ),
            ),
          ],

          // Tags
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: post.tags.take(3).map((tag) {
                return GestureDetector(
                  onTap: () {
                    NavigationService.toNamed(
                      AppRoutes.tagPosts,
                      arguments: {'tag': tag},
                    );
                  },
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
