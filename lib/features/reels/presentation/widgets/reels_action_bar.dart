import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';

class ReelsActionBar extends StatelessWidget {
  final PostModel post;
  final bool isLiked;
  final int likesCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onProfileTap;

  const ReelsActionBar({
    super.key,
    required this.post,
    required this.isLiked,
    required this.likesCount,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onProfileTap
});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 100,
      child: Column(
        children: [
          // Profile Picture
          GestureDetector(
            onTap:  onProfileTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: post.userProfileImage != null
                  ? CachedNetworkImage(
                imageUrl: post.userProfileImage!,
                cacheManager: CustomImageCacheManager(),
                imageBuilder: (context, imageProvider) => CircleAvatar(backgroundImage: imageProvider),
                placeholder: (context, url) => const CircleAvatar(backgroundColor: Colors.grey),
                errorWidget: (context, url, error) => CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ) : CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  post.username?[0].toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Like Button
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(likesCount),
            color: isLiked ? Colors.red : Colors.white,
            onTap: onLike,
          ),

          const SizedBox(height: 24),

          // Comment Button
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(post.commentCount),
            color: Colors.white,
            onTap: onComment,
          ),

          const SizedBox(height: 24),

          // Share Button
          _buildActionButton(
            icon: Icons.share,
            label: '',
            color: Colors.white,
            onTap: onShare,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ]
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
