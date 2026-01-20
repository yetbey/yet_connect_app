import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yet_x_app/config/theme/app_text_styles.dart';
import 'package:yet_x_app/features/feed/data/models/comment_model.dart';
import 'package:yet_x_app/features/feed/presentation/providers/comment_provider.dart'; // commentsProvider burada
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

class CommentBottomSheet extends ConsumerStatefulWidget {
  final String postId;

  const CommentBottomSheet({super.key, required this.postId});

  @override
  ConsumerState<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends ConsumerState<CommentBottomSheet> with SingleTickerProviderStateMixin  {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;

  static const _avatarRadius = 18.0;
  static const _commentAvatarRadius = 16.0;
  static const _avatarCacheSize = 72; // 36dp * 2
  static const _commentAvatarCacheSize = 64;
  static const double _initialChildSize = 0.75;
  static const double _minChildSize = 0.5;
  static const double _maxChildSize = 0.95;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentsProvider(widget.postId).notifier).fetchComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _scrollDebounce?.cancel();
    super.dispose();
  }

  Timer? _scrollDebounce;

  void _onScrollChanged(ScrollController controller) {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 150), () {
      // Pagination logic
      if (controller.position.pixels >= controller.position.maxScrollExtent - 200) {
        ref.read(commentsProvider(widget.postId).notifier).fetchComments();
      }
    });
  }

  void _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    await ref.read(commentsProvider(widget.postId).notifier).addComment(text);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          _focusNode.unfocus();
          FocusScope.of(context).unfocus();
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: _initialChildSize,
        minChildSize: _minChildSize,
        maxChildSize: _maxChildSize,
        expand: false,
        snap: true,
        snapSizes:const  [0.5, 0.75, 0.95],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                )
              ]
            ),
            child: Column(
              children: [
                _buildDragHandle(theme),
                _buildHeader(theme),
                const Divider(height: 1),
                Expanded(child: _buildCommentsList(scrollController, theme)),
                _buildInputArea(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final commentState = ref.watch(commentsProvider(widget.postId));
    final commentCount = commentState.comments.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Yorum Sayısı
          Text(
            '${LocaleKeys.feed_comments.tr()} ${commentCount > 0 ? "($commentCount)" : ""}',
            style: AppTextStyles.bodyMedium.copyWith(letterSpacing: 0.5),
          ),
          // Sıralama Butonu
          TextButton.icon(
            onPressed: () {
              // sıralama seçenekleri
            },
            icon: Icon(Icons.sort_rounded, size: 18, color: theme.colorScheme.primary,),
            label: Text('En Yeni', style: TextStyle(color: theme.colorScheme.primary),),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(ScrollController scrollController, ThemeData theme) {
    final commentsState = ref.watch(commentsProvider(widget.postId));

    scrollController.addListener(() => _onScrollChanged(scrollController));

    if (commentsState.isLoading && commentsState.comments.isEmpty) {
      return _buildLoadingShimmer();
    }

    if (commentsState.comments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: commentsState.comments.length,
      physics: const BouncingScrollPhysics(),
      cacheExtent: 800,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      separatorBuilder: (_, _) => const SizedBox(height: 16,),
      itemBuilder: (context, index) {
        final comment = commentsState.comments[index];
        return RepaintBoundary(
          child: _buildCommentItem(comment, theme),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ayarlar Shimmer
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Content shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconsaxPlusBold.message,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
           Text(
            '${LocaleKeys.feed_no_comments_yet.tr()}\n${LocaleKeys.feed_first_comment}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment, ThemeData theme) {
    return Dismissible( // ✅ Swipe to like/delete
      key: ValueKey(comment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha:  0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        // Silme onayı
        return false; // Şimdilik iptal
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16), // ✅ Rounded card
          border: Border.all(
            color: theme.dividerColor.withValues(alpha:  0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommentAvatar(comment),
            const SizedBox(width: 12),
            Expanded(child: _buildCommentContent(comment, theme)),
            _buildLikeButton(comment), // ✅ Ayrı widget
          ],
        ),
      ),
    );
  }

  Widget _buildLikeButton(CommentModel comment) {
    const isLiked = false; // State'ten kontrol et

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        // Like işlemi
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: const Icon(
           Icons.favorite_border,
          key: ValueKey(isLiked),
          size: 20,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCommentAvatar(CommentModel comment) {
    if (comment.userProfileImage == null) {
      return const CircleAvatar(
        radius: _commentAvatarRadius,
        child: Icon(Icons.person, size: 16),
      );
    }

    return CircleAvatar(
      radius: _commentAvatarRadius,
      backgroundImage: CachedNetworkImageProvider(
        comment.userProfileImage!,
        maxHeight: _commentAvatarCacheSize,
        maxWidth: _commentAvatarCacheSize,
      ),
    );
  }

  Widget _buildCommentContent(CommentModel comment, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: '@${comment.userName} -> ',
                style: AppTextStyles.bodySmall
              ),
              TextSpan(
                text: comment.content,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              timeago.format(comment.createdAt, locale: 'tr'),
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Text(
              LocaleKeys.feed_reply,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentUser = ref.watch(userProvider.select((s) => s.currentUser)); // ✅ select() kullanımı

    return AnimatedContainer( // ✅ Keyboard açılınca smooth animasyon
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha:  0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildUserAvatar(currentUser),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField(theme)),
          const SizedBox(width: 8),
          _buildSendButton(theme),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(dynamic currentUser) {
    if (currentUser?.profileImageUrl == null) {
      return const CircleAvatar(
        radius: _avatarRadius,
        child: Icon(Icons.person, size: 20),
      );
    }

    return CircleAvatar(
      radius: _avatarRadius,
      backgroundImage: CachedNetworkImageProvider(
        currentUser!.profileImageUrl!,
        maxHeight: _avatarCacheSize,
        maxWidth: _avatarCacheSize,
      ),
    );
  }

  Widget _buildTextField(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120), // ✅ Max yükseklik
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _focusNode.hasFocus
              ? theme.colorScheme.primary.withValues(alpha:  0.5) // ✅ Focus border
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _commentController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: LocaleKeys.feed_write_comment.tr(),
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha:  0.5),
            fontSize: 15,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: TextStyle(
          fontSize: 15,
          color: theme.colorScheme.onSurface,
          height: 1.4,
        ),
        minLines: 1,
        maxLines: 5, // ✅ 4 → 5
        maxLength: 500, // ✅ Karakter limiti
        buildCounter: (context, {currentLength = 0, maxLength, isFocused = false}) {
          // Sayaç gizle
          return null;
        },
        textCapitalization: TextCapitalization.sentences,
        onChanged: (text) {
          // Send butonunu aktif et/deaktif et
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    final hasText = _commentController.text.trim().isNotEmpty;

    return AnimatedScale(
      scale: hasText ? 1.0 : 0.8, // ✅ Pulse effect
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
                : theme.colorScheme.onSurface.withValues(alpha:  0.3),
            size: 20,
          ),
        ),
      ),
    );
  }
}
