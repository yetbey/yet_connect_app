import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/chat/data/models/message_model.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:yet_x_app/features/chat/presentation/providers/chat_background_provider.dart';
import 'package:yet_x_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/core/services/media_service.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatDetailPage({
    required this.chatId,
    required this.otherUser,
    super.key,
  });

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const _messageListPadding = EdgeInsets.symmetric(vertical: 10);
  static const _avatarRadius = 20.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatMessagesProvider(widget.chatId).notifier)
          .markAsRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final content = _msgController.text.trim();
    if (content.isEmpty) return;

    _msgController.clear();

    try {
      await ref
          .read(chatMessagesProvider(widget.chatId).notifier)
          .sendMessage(widget.chatId, content);
      ref.read(chatListProvider.notifier).fetchChats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.chat_message_not_send.tr())),
        );
      }
    }
  }

  Future<void> _pickAndSendImage(bool fromCamera) async {
    final mediaService = ref.read(mediaServiceProvider);
    final File? imageFile = fromCamera
        ? await mediaService.pickImageFromCamera()
        : await mediaService.pickImageFromGallery();

    if (imageFile != null) {
      final content = _msgController.text.trim();
      _msgController.clear();

      await ref
          .read(chatMessagesProvider(widget.chatId).notifier)
          .sendMessage(widget.chatId, content, imageFile: imageFile);
      ref.read(chatListProvider.notifier).fetchChats();
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
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
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconsaxPlusBold.gallery,
                      color: colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    LocaleKeys.chat_select_from_gallery.tr(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(false);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconsaxPlusBold.camera,
                      color: colorScheme.secondary,
                    ),
                  ),
                  title: Text(
                    LocaleKeys.chat_take_photo.tr(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    NavigationService.back();
                    _pickAndSendImage(true);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWallpaperSettings() {
    final bgNotifier = ref.read(chatBackgroundProvider.notifier);
    const List<Color> colors = [
      Color(0xFFF5F5F5), // Varsayılan
      Color(0xFFE3F2FD), // Açık Mavi
      Color(0xFFF3E5F5), // Açık Mor
      Color(0xFFE8F5E9), // Açık Yeşil
      Color(0xFFFFF3E0), // Açık Turuncu
      Color(0xFFFFEBEE), // Açık Kırmızı
      Color(0xFFECEFF1), // Gri Mavi
      Color(0xFF263238), // Koyu Tema
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          height: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                LocaleKeys.chat_chat_background.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        bgNotifier.pickImage();
                      },
                      icon: const Icon(Icons.image),
                      label: Text(LocaleKeys.common_gallery.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        bgNotifier.resetToDefault();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(LocaleKeys.chat_default_background.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                LocaleKeys.common_colors.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        bgNotifier.setColor(colors[index]);
                        Navigator.pop(context);
                      },
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: Duration(milliseconds: 100 + (index * 50)),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colors[index],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors[index].withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = ref.watch(userProvider).currentUser?.id;
    final messageState = ref.watch(chatMessagesProvider(widget.chatId));
    final bgState = ref.watch(chatBackgroundProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(theme, colorScheme),
        body: Container(
          decoration: BoxDecoration(
            color: bgState.isImage
                ? null
                : (bgState.color ?? colorScheme.surface),
            image: (bgState.isImage && bgState.imagePath != null)
                ? DecorationImage(
                    image: FileImage(File(bgState.imagePath!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: messageState.messages.isEmpty
                    ? (messageState.isLoading
                          ? _buildShimmerLoading(colorScheme)
                          : _buildEmptyState(theme, false))
                    : _buildMessageList(currentUserId, messageState),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: messageState.replyingTo != null
                    ? _buildReplyBar(theme, colorScheme, messageState.replyingTo!)
                    : const SizedBox.shrink(),
              ),
              _buildInputArea(theme, colorScheme, messageState.isSending),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: colorScheme.surface,
      scrolledUnderElevation: 0.0,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () {
          ref.read(chatListProvider.notifier).fetchChats();
          NavigationService.back();
        },
      ),
      title: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.chatId}',
            child: CircleAvatar(
              radius: _avatarRadius,
              backgroundImage: widget.otherUser.profileImageUrl != null
                  ? CachedNetworkImageProvider(
                      widget.otherUser.profileImageUrl!,
                      maxHeight: 80,
                      maxWidth: 80,
                    )
                  : null,
              child: widget.otherUser.profileImageUrl == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUser.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showWallpaperSettings,
          icon: const Icon(IconsaxPlusLinear.gallery_edit),
          tooltip: LocaleKeys.chat_change_background.tr(),
        ),
        IconButton(onPressed: () {}, icon: const Icon(IconsaxPlusLinear.more)),
      ],
    );
  }

  Widget _buildShimmerLoading(ColorScheme colorScheme) {
    return ListView.builder(
      reverse: true,
      padding: _messageListPadding,
      itemCount: 8,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 150,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            child: Icon(
              IconsaxPlusBold.message,
              size: 40,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.chat_start_chat.tr(),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar(
    ThemeData theme,
    ColorScheme colorScheme,
    MessageModel replyTo,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withAlpha(51)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          if (replyTo.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: replyTo.imageUrl!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  replyTo.senderId == ref.watch(userProvider).currentUser?.id
                      ? 'Sen'
                      : widget.otherUser.userName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  replyTo.content.isEmpty ? '📷 Photo' : replyTo.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              ref
                  .read(chatMessagesProvider(widget.chatId).notifier)
                  .clearReply();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(String? currentUserId, messageState) {
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      itemCount: messageState.messages.length,
      padding: _messageListPadding,
      cacheExtent: 1000,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      itemBuilder: (context, index) {
        final message = messageState.messages[index];
        final isMe = message.senderId == currentUserId;

        bool isFirstInSequence = true;
        if (index < messageState.messages.length - 1) {
          final nextMessage = messageState.messages[index + 1];
          if (nextMessage.senderId == message.senderId) {
            isFirstInSequence = false;
          }
        }

        final sentAtFormatted =
            "${message.sentAt.hour}:${message.sentAt.minute.toString().padLeft(2, '0')}";

        String? displayReplyToSenderName;
        if (message.replyToMessageId != null) {
          try {
            final repliedMessage = messageState.messages.firstWhere(
              (m) => m.id == message.replyToMessageId,
              orElse: () => message,
            );

            if (repliedMessage.senderId == currentUserId) {
              displayReplyToSenderName = 'Sen';
            } else {
              displayReplyToSenderName = widget.otherUser.userName;
            }
          } catch (e) {
            displayReplyToSenderName = message.replyToSenderName;
          }
        }

        return RepaintBoundary(
          child: isMe
              ? MessageBubble.next(
                  key: ValueKey(message.id),
                  message: message.content,
                  contentImage: message.imageUrl,
                  isMe: true,
                  isRead: message.isRead,
                  sentAt: sentAtFormatted,
                  replyToContent: message.replyToContent,
                  replyToImageUrl: message.replyToImageUrl,
                  replyToSenderName: displayReplyToSenderName,
                  onReply: () => ref
                      .read(chatMessagesProvider(widget.chatId).notifier)
                      .setReplyTo(message),
                )
              : isFirstInSequence
              ? MessageBubble.first(
                  key: ValueKey(message.id),
                  username: widget.otherUser.userName,
                  userImage: widget.otherUser.profileImageUrl,
                  message: message.content,
                  contentImage: message.imageUrl,
                  isMe: false,
                  isRead: message.isRead,
                  sentAt: sentAtFormatted,
                  replyToContent: message.replyToContent,
                  replyToImageUrl: message.replyToImageUrl,
                  replyToSenderName: displayReplyToSenderName,
                  onReply: () => ref
                      .read(chatMessagesProvider(widget.chatId).notifier)
                      .setReplyTo(message),
                )
              : MessageBubble.next(
                  key: ValueKey(message.id),
                  message: message.content,
                  isMe: false,
                  contentImage: message.imageUrl,
                  isRead: message.isRead,
                  sentAt: sentAtFormatted,
                  replyToContent: message.replyToContent,
                  replyToImageUrl: message.replyToImageUrl,
                  replyToSenderName: displayReplyToSenderName,
                  onReply: () => ref
                      .read(chatMessagesProvider(widget.chatId).notifier)
                      .setReplyTo(message),
                ),
        );
      },
    );
  }

  Widget _buildInputArea(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isSending,
  ) {
    final hasText = _msgController.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom * 0.01,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showAttachmentOptions,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconsaxPlusLinear.add,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Text Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _msgController.text.isNotEmpty
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : colorScheme.outline.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        onChanged: (val) => setState(() {}),
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          fillColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,

                          hintText: LocaleKeys.chat_type_message.tr(),
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        IconsaxPlusLinear.emoji_happy,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        // Emoji picker eklenebilir
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send Button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: isSending
                  ? Container(
                      key: const ValueKey('loading'),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      key: const ValueKey('send'),
                      decoration: BoxDecoration(
                        gradient: hasText
                            ? LinearGradient(
                                colors: [
                                  theme.primaryColor,
                                  theme.primaryColor.withValues(alpha: 0.8),
                                ],
                              )
                            : null,
                        color: !hasText
                            ? colorScheme.surfaceContainerHighest
                            : null,
                        shape: BoxShape.circle,
                        boxShadow: hasText
                            ? [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: IconButton(
                        onPressed: hasText ? _handleSend : null,
                        icon: Icon(
                          IconsaxPlusBold.send_1,
                          color: hasText
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
