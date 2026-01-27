import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readmore/readmore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/config/theme/app_text_styles.dart';
import 'package:yet_x_app/core/constants/decorations.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/features/feed/presentation/pages/comments_sheet.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/widgets/animated_heart_overlay.dart';

import 'action_button.dart';

class ImageFeedCard extends ConsumerStatefulWidget {
  final PostModel post;

  const ImageFeedCard({super.key, required this.post});

  @override
  ConsumerState<ImageFeedCard> createState() => _ImageFeedCardState();
}

class _ImageFeedCardState extends ConsumerState<ImageFeedCard>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late int likesCount;
  late bool isMe;
  bool _showHeartAnimation = false;
  late AnimationController _likeController;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLikedByCurrentUser;
    likesCount = widget.post.likes;
    isMe = widget.post.userId == Supabase.instance.client.auth.currentUser?.id;
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ImageFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      if (isLiked != widget.post.isLikedByCurrentUser ||
          likesCount != widget.post.likes) {
        setState(() {
          isLiked = widget.post.isLikedByCurrentUser;
          likesCount = widget.post.likes;
        });
      }
    }
  }

  void _handleDoubleTapLike() {
    HapticFeedback.mediumImpact();
    setState(() => _showHeartAnimation = true);
    if (isLiked) return;
    setState(() {
      isLiked = true;
      likesCount += 1;
    });
    _likeController.forward().then((_) => _likeController.reverse());
    ref.read(postActionsProvider.notifier).toggleLike(widget.post);
  }

  void _toggleLikeButton() {
    HapticFeedback.mediumImpact();
    final previousLikedState = isLiked;
    final previousLikeCount = likesCount;
    setState(() {
      isLiked = !previousLikedState;
      likesCount = previousLikedState
          ? previousLikeCount - 1
          : previousLikeCount + 1;
    });
    if (isLiked) {
      _likeController.forward().then((_) => _likeController.reverse());
    }

    final postToSend = widget.post.copyWith(
      isLikedByCurrentUser: previousLikedState,
      likes: previousLikeCount,
    );
    ref.read(postActionsProvider.notifier).toggleLike(postToSend).catchError((
      e,
    ) {
      if (mounted) {
        setState(() {
          isLiked = previousLikedState;
          likesCount = previousLikeCount;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark, theme),
          if (widget.post.imageUrl != null)
            _buildImageSection(context, isDark, theme),
          if (widget.post.caption != null || widget.post.tags.isNotEmpty)
            _buildCaptionSection(context, isDark, theme),
          _buildInteractionInfo(context, isDark),
          _buildActionsBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => NavigationService.toNamed(
              AppRoutes.profile,
              arguments: {'userId': widget.post.userId},
            ),
            child: Stack(
              children: [
                _buildAvatar(40),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => NavigationService.toNamed(
                AppRoutes.profile,
                arguments: {'userId': widget.post.userId},
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${widget.post.username}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _getTimeAgo(),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _showPostMenu(context),
            icon: Icon(
              Icons.more_horiz_rounded,
              color: Colors.grey[600],
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cacheSize = (screenWidth * 1.2).toInt();

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: CachedNetworkImage(
            imageUrl: widget.post.imageUrl!,
            memCacheHeight: cacheSize,
            memCacheWidth: cacheSize,
            cacheManager: CustomImageCacheManager(),
            fit: BoxFit.cover,
            imageBuilder: (context, imageProvider) => GestureDetector(
              onTap: () => NavigationService.toNamed(
                AppRoutes.detailedPost,
                arguments: {'post': widget.post},
              ),
              onDoubleTap: _handleDoubleTapLike,
              child: AspectRatio(
                aspectRatio: 1,
                child: Image(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
            placeholder: (context, url) => AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey[400],
                  size: 40,
                ),
              ),
            ),
            fadeInDuration: const Duration(milliseconds: 150),
            fadeOutDuration: const Duration(milliseconds: 100),
            maxHeightDiskCache: 1024,
            maxWidthDiskCache: 1024,
          ),
        ),
        if (_showHeartAnimation)
          AnimatedHeartOverlay(
            isAnimating: _showHeartAnimation,
            size: 120,
            onEnd: () => setState(() => _showHeartAnimation = false),
          ),
      ],
    );
  }

  Widget _buildCaptionSection(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            ReadMoreText(
              widget.post.caption!,
              trimLines: 3,
              trimMode: TrimMode.Line,
              trimCollapsedText: LocaleKeys.feed_read_more.tr(),
              trimExpandedText: LocaleKeys.feed_read_less.tr(),
              moreStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
              lessStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.grey[200] : Colors.grey[800],
                fontWeight: FontWeight.w400,
              ),
            ),
          if (widget.post.tags.isNotEmpty) ...[
            const SizedBox(height:8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.post.tags.map((tag) {
                return _buildModernTag(context, tag, isDark);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionInfo(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (likesCount > 0)
            GestureDetector(
              onTap: _showLikesSheet,
              child: _buildLikeText(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildLikeText(bool isDark) {
    final topLikers = widget.post.topLikers ?? [];

    if (topLikers.isEmpty) {
      // Fallback: Sadece sayı göster
      return Text(
        '${_formatCount(likesCount)} beğeni',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      );
    }

    String likeText;

    if (likesCount == 1 && topLikers.isNotEmpty) {
      // Tek kişi beğenmişse
      likeText = '${topLikers[0].username} beğendi';
    } else if (likesCount == 2 && topLikers.length >= 2) {
      // İki kişi beğenmişse
      likeText = '${topLikers[0].username} ve ${topLikers[1].username} beğendi';
    } else if (likesCount > 2 && topLikers.length >= 2) {
      // 2'den fazla kişi beğenmişse
      final othersCount = likesCount - 2;
      likeText = '${topLikers[0].username}, ${topLikers[1].username} ve $othersCount diğer kişi beğendi';
    } else {
      // Fallback
      likeText = '${_formatCount(likesCount)} beğeni';
    }

    return Text(
      likeText,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildActionsBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8  , 8, 12, 2),
      child: Row(
        children: [
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.2).animate(
              CurvedAnimation(parent: _likeController, curve: Curves.easeOut),
            ),
            child: UnifiedActionButton(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              label: _formatCount(likesCount),
              color: isLiked ? Colors.red : null,
              isActive: isLiked,
              onTap: _toggleLikeButton,
              onLongPress: _showLikesSheet,
            ),
          ),
          const SizedBox(width: 8),
          UnifiedActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(widget.post.commentCount),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useSafeArea: true,
                builder: (context) =>
                    CommentBottomSheet(postId: widget.post.id),
              );
            },
          ),
          const Spacer(),
          UnifiedActionButton(
            icon: Icons.ios_share,
            label: '',
            onTap: () {
              HapticFeedback.lightImpact();
              // Share functionality
            },
          ),
          const SizedBox(width: 8),
          UnifiedActionButton(
            icon: Icons.bookmark_border,
            label: '',
            onTap: () {
              HapticFeedback.lightImpact();
              // Bookmark functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernTag(BuildContext context, String tag, bool isDark) {
    return InkWell(
      onTap: () {
        NavigationService.toNamed(AppRoutes.tagPosts, arguments: {'tag': tag});
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          '#$tag',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double size) {
    if (widget.post.userProfileImage == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: Text(
            widget.post.username?[0].toUpperCase() ?? 'U',
            style: TextStyle(
              fontSize: size / 2,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: CachedNetworkImage(
        imageUrl: widget.post.userProfileImage!,
        memCacheWidth: (size * 2).toInt(),
        memCacheHeight: (size * 2).toInt(),
        cacheManager: CustomImageCacheManager(),
        imageBuilder: (context, imageProvider) =>
            CircleAvatar(radius: size / 2, backgroundImage: imageProvider),
        placeholder: (context, url) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey[300],
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey[300],
          child: Icon(Icons.person, size: size / 2),
        ),
      ),
    );
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(widget.post.createdAt);
    if (difference.inDays > 7) {
      return '${widget.post.createdAt.day}.${widget.post.createdAt.month}.${widget.post.createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}g';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}d';
    } else {
      return 'şimdi';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}B';
    }
    return count.toString();
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text(
                      LocaleKeys.feed_delete_confirm_title.tr(),
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm =
                          await NavigationService.showDeleteConfirmDialog(
                            message: LocaleKeys.feed_delete_confirm_message
                                .tr(),
                          );
                      if (confirm) {
                        await ref
                            .read(postActionsProvider.notifier)
                            .deletePost(widget.post.id);
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Paylaş'),
                  onTap: () {
                    Navigator.pop(context);
                    // Share functionality
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Linki kopyala'),
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    // Copy link
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLikesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: kLikesBottomSheetBoxDecoration(context),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: kLikesBottomSheetHandlerBoxDecoration(),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    LocaleKeys.feed_likers.tr(),
                    style: AppTextStyles.labelLarge,
                  ),
                  const Divider(),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: ref
                          .read(postActionsProvider.notifier)
                          .getPostLikeUsers(widget.post.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final users = snapshot.data ?? [];
                        if (users.isEmpty) {
                          return Center(
                            child: Text(LocaleKeys.feed_no_likes_yet.tr()),
                          );
                        }

                        return ListView.separated(
                          controller: controller,
                          itemCount: users.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 70),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final imgUrl = user['profile_image_url'];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    (imgUrl != null && imgUrl.isNotEmpty)
                                    ? CachedNetworkImageProvider(
                                        imgUrl,
                                        cacheManager: CustomImageCacheManager(),
                                      )
                                    : null,
                                child: (imgUrl == null)
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                user['full_name'] ??
                                    user['username'] ??
                                    'Kullanıcı',
                                style: AppTextStyles.bodyMedium,
                              ),
                              subtitle: Text(
                                "@${user['username']}",
                                style: AppTextStyles.bodySmall,
                              ),
                              onTap: () {
                                NavigationService.back();
                                NavigationService.toNamed(
                                  AppRoutes.profile,
                                  arguments: {'userId': user['id'].toString()},
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
