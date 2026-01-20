import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble.first({
    super.key,
    required this.userImage,
    required this.username,
    required this.message,
    required this.isMe,
    required this.sentAt,
    this.onLongPress,
    this.contentImage,
    this.isRead = false,
    this.replyToContent,
    this.replyToImageUrl,
    this.replyToSenderName,
    this.onReply,
  }) : isFirstInSequence = true;

  const MessageBubble.next({
    super.key,
    required this.message,
    required this.isMe,
    required this.sentAt,
    this.onLongPress,
    this.contentImage,
    this.isRead = false,
    this.replyToContent,
    this.replyToImageUrl,
    this.replyToSenderName,
    this.onReply,
  }) : isFirstInSequence = false,
       userImage = null,
       username = null;

  final Function(Rect bubblePosition)? onLongPress;
  final bool isFirstInSequence;
  final String? userImage;
  final String? username;
  final String message;
  final String? contentImage;
  final String sentAt;
  final bool isMe;
  final bool isRead;
  final String? replyToContent;
  final String? replyToImageUrl;
  final String? replyToSenderName;
  final VoidCallback? onReply;

  BorderRadius _getBorderRadius() {
    const double rLarge = 20.0;
    const double rSmall = 4.0;

    if (isMe) {
      return BorderRadius.only(
        topLeft: const Radius.circular(rLarge),
        topRight: isFirstInSequence
            ? const Radius.circular(rSmall)
            : const Radius.circular(rLarge),
        bottomLeft: const Radius.circular(rLarge),
        bottomRight: const Radius.circular(rLarge),
      );
    } else {
      return BorderRadius.only(
        topLeft: isFirstInSequence
            ? const Radius.circular(rSmall)
            : const Radius.circular(rLarge),
        topRight: const Radius.circular(rLarge),
        bottomLeft: const Radius.circular(rLarge),
        bottomRight: const Radius.circular(rLarge),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bubbleDecoration = isMe
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: _getBorderRadius(),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: _getBorderRadius(),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          );

    final textColor = isMe
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        // ✅ Opacity'yi clamp ile sınırlandır
        final clampedOpacity = value.clamp(0.0, 1.0);
        // ✅ Scale'i güvenli aralıkta tut
        final clampedScale = (0.8 + (value * 0.2)).clamp(0.0, 1.0);

        return Transform.scale(
          scale: clampedScale,
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Opacity(opacity: clampedOpacity, child: child),
        );
      },
      child: GestureDetector(
        onLongPress: onReply,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe && isFirstInSequence && username != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (userImage != null)
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: CachedNetworkImageProvider(
                            userImage!,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        username!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: bubbleDecoration,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyToContent != null || replyToImageUrl != null)
                      _buildReplyPreview(
                        context,
                        theme,
                        textColor,
                        colorScheme,
                      ),
                    if (contentImage != null) _buildImage(),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      children: [
                        if (message.isNotEmpty)
                          Text(
                            message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildTimeAndStatus(colorScheme, textColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(
    BuildContext context,
    ThemeData theme,
    Color textColor,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? colorScheme.primary : colorScheme.secondary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyToImageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: replyToImageUrl!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(width: 36, height: 36, color: Colors.grey[300]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (replyToSenderName != null)
                  Text(
                    replyToSenderName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  replyToContent ?? '📷 Fotoğraf',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () => NavigationService.toNamed(
          AppRoutes.fullImageViewer,
          arguments: {'imageUrl': contentImage!},
        ),
        child: Hero(
          tag: contentImage!,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: contentImage!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAndStatus(ColorScheme colorScheme, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sentAt,
          style: TextStyle(
            fontSize: 10,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            isRead
                ? IconsaxPlusBold.tick_circle
                : IconsaxPlusLinear.tick_circle,
            size: 14,
            color: isRead
                ? colorScheme.primary
                : textColor.withValues(alpha: 0.6),
          ),
        ],
      ],
    );
  }
}
