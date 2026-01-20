// lib/features/feed/presentation/pages/tag_posts_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/image_feed_card.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/text_feed_card.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/video_feed_card.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/shimmer_feed_card.dart';

class TagPostsPage extends ConsumerWidget {
  final String tag;

  const TagPostsPage({super.key, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagPosts = ref.watch(postsByTagProvider(tag));
    final tagFollowState = ref.watch(tagFollowProvider);
    final isFollowing = tagFollowState.value?.contains(tag) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('#$tag'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          // Takip et/Takibi bırak butonu
          IconButton(
            onPressed: () {
              ref.read(tagFollowProvider.notifier).toggleFollow(tag);
            },
            icon: Icon(
              isFollowing ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
              color: isFollowing ? Colors.red : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      body: tagPosts.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    IconsaxPlusLinear.hashtag,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bu etikette henüz gönderi yok',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            onRefresh: () async {
              ref.invalidate(postsByTagProvider(tag));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
                final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;

                if (hasImage) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ImageFeedCard(key: ValueKey(post.id), post: post),
                  );
                } else if (hasVideo) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: VideoFeedCard(key: ValueKey(post.id), post: post),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFeedCard(
                      key: ValueKey(post.id),
                      post: post,
                      index: index,
                    ),
                  );
                }
              },
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: ShimmerFeedCard(),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Bir hata oluştu',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.invalidate(postsByTagProvider(tag));
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
