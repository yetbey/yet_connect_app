import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';

class StoryRing extends StatelessWidget {
  final String? imageUrl;
  final bool hasUnseenStories;
  final bool isAddStory;
  final VoidCallback? onTap;
  final double size;

  const StoryRing({
    super.key,
    this.imageUrl,
    this.hasUnseenStories = false,
    this.isAddStory = false,
    this.onTap,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasUnseenStories
              ? LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                    colorScheme.tertiary,
                  ],
                )
              : null,
          border: !hasUnseenStories && !isAddStory
              ? Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                  width: 2,
                )
              : null,
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.surface, width: 3),
          ),
          child: isAddStory
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: size * 0.4,
                  ),
                )
              : ClipOval(
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          cacheManager: CustomImageCacheManager(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person,
                            size: size * 0.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: size * 0.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                ),
        ),
      ),
    );
  }
}
