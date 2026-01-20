import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/features/story/presentation/providers/story_provider.dart';
import 'package:yet_x_app/features/story/presentation/widgets/story_ring.dart';

class StoryBar extends ConsumerWidget {
  const StoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(followingStoriesProvider);
    final currentUser = ref.watch(userProvider).currentUser;

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: storiesAsync.when(
        data: (storyGroups) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: storyGroups.length + 1, // +1 for add story button
            itemBuilder: (context, index) {
              if (index == 0) {
                // Kendi story'ni ekle butonu
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      StoryRing(
                        imageUrl: currentUser?.profileImageUrl,
                        isAddStory: true,
                        onTap: () {
                          NavigationService.toNamed(AppRoutes.createStory);
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hikayen',
                        style: TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }

              final group = storyGroups[index - 1];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    StoryRing(
                      imageUrl: group.userProfileImage,
                      hasUnseenStories: group.hasUnseenStories,
                      onTap: () {
                        NavigationService.toNamed(
                          AppRoutes.storyViewer,
                          arguments: {
                            'storyGroups': storyGroups,
                            'initialIndex': index - 1,
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 70,
                      child: Text(
                        group.username,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const SizedBox.shrink(),
      ),
    );
  }
}
