import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/config/theme/app_text_styles.dart'; // ✨ Eklendi
import 'package:yet_x_app/core/constants/app_colors.dart';
import 'package:yet_x_app/core/constants/decorations.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart'; // ✨ Eklendi
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/features/feed/presentation/providers/comment_provider.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/action_more_button.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/tag_chip.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

import '../widgets/action_button.dart';

class DetailedPostPage extends ConsumerStatefulWidget {
  final PostModel post;

  const DetailedPostPage({super.key, required this.post});

  @override
  ConsumerState<DetailedPostPage> createState() => _DetailedPostPageState();
}

class _DetailedPostPageState extends ConsumerState<DetailedPostPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  late AnimationController _likeAnimationController;

  late bool isLiked;
  late int likesCount;
  bool isMe = false;

  static const double _profileAvatarRadius = 20.0;
  static const double _commentAvatarRadius = 18.0;
  static const double _maxImageHeightRatio = 0.6; // 0.5 → 0.6 (daha büyük)
  static const int _captionMaxLines = 10; // 5 → 10 (daha uzun)
  static const int _profileAvatarCacheSize = 80;
  static const int _commentAvatarCacheSize = 72;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLikedByCurrentUser;
    likesCount = widget.post.likes;

    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = ref.read(
        userProvider.select((s) => s.currentUser?.id),
      );
      setState(() => isMe = widget.post.userId == currentUserId);
      ref.read(commentsProvider(widget.post.id).notifier).fetchComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DetailedPostPage oldWidget) {
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

  void _handleLike() {
    HapticFeedback.lightImpact();

    // ✅ Animasyon oynat
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });

    final previousState = isLiked;
    final previousCount = likesCount;

    setState(() {
      isLiked = !isLiked;
      likesCount = isLiked ? likesCount + 1 : likesCount - 1;
    });

    final postToSend = widget.post.copyWith(
      isLikedByCurrentUser: previousState,
      likes: previousCount,
    );

    ref.read(postActionsProvider.notifier).toggleLike(postToSend).catchError((
      e,
    ) {
      if (mounted) {
        setState(() {
          isLiked = previousState;
          likesCount = previousCount;
        });
      }
    });
  }

  void _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();

    await ref.read(commentsProvider(widget.post.id).notifier).addComment(text);
    _commentController.clear();

    if (mounted) {
      _commentFocus.unfocus(); // ✅ Focus yönetimi
    }
  }

  bool get _isImage => widget.post.imageUrl?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final commentState = ref.watch(commentsProvider(widget.post.id));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          _commentFocus.unfocus();
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(theme),
        body: CustomScrollView(
          // ✅ SingleChildScrollView → CustomScrollView
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: Divider(thickness: 1, color: AppColors.divider),
            ),

            if (_isImage) SliverToBoxAdapter(child: _buildPostImage(context)),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildPostContent(theme),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                child: _buildCommentsHeader(theme, commentState),
              ),
            ),

            _buildCommentsSliver(commentState), // ✅ Sliver olarak
            // ✅ Bottom padding
            SliverToBoxAdapter(child: SizedBox(height: bottomInset + 100)),
          ],
        ),
        bottomNavigationBar: _buildCommentInput(theme, bottomInset),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      scrolledUnderElevation: 0.0,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      actions: [
        if (isMe)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionMoreButton(post: widget.post, ref: ref),
          ),
      ],
    );
  }

  Widget _buildPostImage(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          NavigationService.toNamed(
            AppRoutes.fullImageViewer,
            arguments: {'imageUrl': widget.post.imageUrl},
          );
        },
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: screenHeight * _maxImageHeightRatio,
          ),
          child: CachedNetworkImage(
            imageUrl: widget.post.imageUrl!,
            fit: BoxFit.cover,
            memCacheHeight: (screenHeight * _maxImageHeightRatio * 2).toInt(),
            memCacheWidth: (screenWidth * 2).toInt(),
            maxHeightDiskCache: 1024,
            maxWidthDiskCache: 1024,
            cacheManager: CustomImageCacheManager(),
            fadeInDuration: const Duration(milliseconds: 150),
            fadeOutDuration: const Duration(milliseconds: 100),
            placeholder: (_, _) => Container(
              color: AppColors.cardColor,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.cardColor,
              child: const Icon(Icons.error, color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostContent(ThemeData theme) {
    return Column(
      children: [
        _buildUserInfo(theme),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 12),

        if (widget.post.caption?.isNotEmpty ?? false) _buildCaption(),

        if (widget.post.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.post.tags.map((tag) {
                  return TagChip(
                    tag: tag,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      NavigationService.toNamed(
                        AppRoutes.tagPosts,
                        arguments: {'tag': tag},
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                NavigationService.toNamed(
                  AppRoutes.profile,
                  arguments: {'userId': widget.post.userId},
                );
              },
              borderRadius: BorderRadius.circular(_profileAvatarRadius),
              child: CircleAvatar(
                radius: _profileAvatarRadius,
                backgroundImage: widget.post.userProfileImage != null
                    ? CachedNetworkImageProvider(
                        widget.post.userProfileImage!,
                        maxHeight: _profileAvatarCacheSize,
                        maxWidth: _profileAvatarCacheSize,
                        cacheManager: CustomImageCacheManager(),
                      )
                    : null,
                backgroundColor: AppColors.cardColor,
                child: widget.post.userProfileImage == null
                    ? const Icon(Icons.person, color: AppColors.textColor)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${widget.post.username}',
                  style: AppTextStyles.postUsername.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.post.userFullName != null)
                  Text(
                    widget.post.userFullName!,
                    style: AppTextStyles.postFullname.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),

          // ✅ Animated like button
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.3).animate(
              CurvedAnimation(
                parent: _likeAnimationController,
                curve: Curves.easeOut,
              ),
            ),
            child: UnifiedActionButton(
              onTap: _handleLike,
              color: isLiked ? AppColors.error : AppColors.textColor,
              icon: isLiked ? Icons.favorite : IconsaxPlusBold.heart,
              label: '$likesCount',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          widget.post.caption!,
          maxLines: _captionMaxLines,
          style: AppTextStyles.postCaption.copyWith(
            fontSize: 16,
            height: 1.5, // ✅ Satır yüksekliği
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsHeader(ThemeData theme, dynamic commentState) {
    return Row(
      children: [
        Text(
          LocaleKeys.feed_comments.tr(),
          style: AppTextStyles.headline3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        if (!commentState.isLoading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${commentState.comments.length}',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentsSliver(dynamic commentState) {
    if (commentState.isLoading && commentState.comments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (commentState.comments.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyComments());
    }

    final reversedComments = commentState.comments.reversed.toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final comment = reversedComments[index];

            // ✅ Staggered animation
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 250 + (index * 30)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RepaintBoundary(child: _buildCommentItem(comment)),
              ),
            );
          },
          childCount: reversedComments.length,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: false,
        ),
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              IconsaxPlusBold.message,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.feed_no_comments_yet.tr(),
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.feed_first_comment.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                NavigationService.toNamed(
                  AppRoutes.profile,
                  arguments: {'userId': comment.userId},
                );
              },
              borderRadius: BorderRadius.circular(_commentAvatarRadius),
              child: CircleAvatar(
                radius: _commentAvatarRadius,
                backgroundImage: comment.userProfileImage != null
                    ? CachedNetworkImageProvider(
                        comment.userProfileImage!,
                        maxHeight: _commentAvatarCacheSize,
                        maxWidth: _commentAvatarCacheSize,
                        cacheManager: CustomImageCacheManager(),
                      )
                    : null,
                backgroundColor: AppColors.cardColor,
                child: comment.userProfileImage == null
                    ? const Icon(
                        IconsaxPlusBold.personalcard,
                        size: 16,
                        color: AppColors.textColor,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@${comment.userName}',
                      style: AppTextStyles.postUsername.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: AppTextStyles.postTimestamp,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              HapticFeedback.lightImpact();
              // Like comment
            },
            icon: const Icon(
              IconsaxPlusBold.like_1,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}dk';
    if (difference.inHours < 24) return '${difference.inHours}sa';
    if (difference.inDays < 7) return '${difference.inDays}g';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}h';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}ay';
    return '${(difference.inDays / 365).floor()}y';
  }

  Widget _buildCommentInput(ThemeData theme, double bottomInset) {
    final hasText = _commentController.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _commentFocus.hasFocus
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocus,
                decoration: InputDecoration(
                  hintText: LocaleKeys.feed_write_comment.tr(),
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ✅ Animated send button
          AnimatedScale(
            scale: hasText ? 1.0 : 0.8,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: hasText
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: hasText ? _sendComment : null,
                icon: Icon(
                  IconsaxPlusBold.send_1,
                  color: hasText
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLikesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLikesSheet(),
    );
  }

  Widget _buildLikesSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.6, 0.9],
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final users = snapshot.data ?? [];
                    if (users.isEmpty) {
                      return Center(
                        child: Text(
                          LocaleKeys.feed_no_likes_yet.tr(),
                          style: AppTextStyles.bodyMedium,
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: controller,
                      itemCount: users.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        indent: 70,
                        color: AppColors.divider,
                      ),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final imgUrl = user['profile_image_url'];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (imgUrl != null && imgUrl.isNotEmpty)
                                ? CachedNetworkImageProvider(
                                    imgUrl,
                                    maxHeight: 80,
                                    maxWidth: 80,
                                    cacheManager: CustomImageCacheManager(),
                                  )
                                : null,
                            backgroundColor: AppColors.cardColor,
                            child: (imgUrl == null)
                                ? const Icon(
                                    Icons.person,
                                    color: AppColors.textColor,
                                  )
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
                            Navigator.pop(context);
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
  }
}
