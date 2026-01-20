import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:yet_x_app/config/theme/app_text_styles.dart';
import 'package:yet_x_app/core/constants/app_colors.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/core/services/media_service.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/widgets/image_positioner.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final PostModel? postToEdit;

  const CreatePostScreen({super.key, this.postToEdit});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  late final TextEditingController captionController;
  final TextEditingController _tagController = TextEditingController();
  File? selectedImage;
  File? selectedVideo;
  VideoPlayerController? _videoController;
  Alignment _alignment = Alignment.center;
  List<String> _tags = [];

  // 🎨 Güncellenmiş sabitler
  static const _avatarRadius = 22.0; // 🎨 20 → 22
  static const _mediaBorderRadius = 20.0; // 🎨 16 → 20
  static const _closeButtonSize = 24.0; // 🎨 20 → 24
  static const _maxCaptionLength = 500; // ✨ Karakter limiti
  static const _contentPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  );
  static const _toolbarPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12, // 🎨 8 → 12
  );

  bool get isEditing => widget.postToEdit != null;

  @override
  void initState() {
    super.initState();
    captionController = TextEditingController(
      text: widget.postToEdit?.caption ?? '',
    );
    _tags = widget.postToEdit?.tags ?? [];

    // ✨ Karakter sayacı için listener
    captionController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    captionController.dispose();
    _tagController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final cleanTag = tag.trim().toLowerCase().replaceAll('#', '');
    if (cleanTag.isEmpty) return;

    if (_tags.length >= 3) {
      NavigationService.showSnackbar('En fazla 3 etiket ekleyebilirsiniz!');
      return;
    }

    if (_tags.contains(cleanTag)) {
      NavigationService.showSnackbar('Bu etiket zaten ekli');
      return;
    }

    HapticFeedback.lightImpact(); // ✨ Haptic feedback
    setState(() {
      _tags.add(cleanTag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    HapticFeedback.lightImpact(); // ✨ Haptic feedback
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              IconsaxPlusBold.hashtag,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Etiket Ekle'),
          ],
        ),
        content: TextField(
          controller: _tagController,
          decoration: InputDecoration(
            hintText: 'Etiket girin (# olmadan)',
            prefixIcon: Icon(
              Icons.tag,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          textCapitalization: TextCapitalization.none,
          autofocus: true,
          onSubmitted: (value) {
            _addTag(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              _addTag(_tagController.text);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(bool fromCamera) async {
    HapticFeedback.selectionClick(); // ✨ Haptic feedback
    final mediaService = ref.read(mediaServiceProvider);
    final file = fromCamera
        ? await mediaService.pickImageFromCamera()
        : await mediaService.pickImageFromGallery();

    if (file != null) {
      setState(() {
        selectedImage = file;
        selectedVideo = null;
        _videoController?.dispose();
        _videoController = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    HapticFeedback.selectionClick(); // ✨ Haptic feedback
    final mediaService = ref.read(mediaServiceProvider);
    final file = await mediaService.pickVideoFromGallery();

    if (file != null) {
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {
            selectedVideo = file;
            selectedImage = null;
          });
          _videoController!.play();
          _videoController!.setLooping(true);
        });
    }
  }

  void _clearMedia() {
    HapticFeedback.lightImpact(); // ✨ Haptic feedback
    setState(() {
      selectedImage = null;
      selectedVideo = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  Future<void> _submit() async {
    final text = captionController.text.trim();
    final actions = ref.read(postActionsProvider.notifier);

    if (text.isEmpty &&
        selectedImage == null &&
        selectedVideo == null &&
        !isEditing) {
      NavigationService.showSnackbar('Lütfen bir içerik ekleyin');
      return;
    }

    if (text.length > _maxCaptionLength) {
      NavigationService.showSnackbar(
        'Metin çok uzun! Maksimum $_maxCaptionLength karakter',
      );
      return;
    }

    HapticFeedback.mediumImpact(); // ✨ Haptic feedback
    FocusScope.of(context).unfocus();

    if (isEditing) {
      await actions.updatePost(
        postId: widget.postToEdit!.id,
        caption: text,
        tags: _tags,
      );
    } else {
      await actions.createPost(
        text,
        imageFile: selectedImage,
        videoFile: selectedVideo,
        alignment: _alignment,
        tags: _tags,
      );
    }

    NavigationService.back();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = ref.watch(postActionsProvider);
    final currentUser = ref.watch(userProvider).currentUser;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: _buildAppBar(theme, colorScheme, isLoading),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: _contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputRow(theme, colorScheme, currentUser),

                      // ✨ Karakter sayacı
                      if (captionController.text.isNotEmpty)
                        _buildCharacterCounter(colorScheme),

                      const SizedBox(height: 20),

                      if (_tags.isNotEmpty) _buildTagChips(colorScheme),
                      if (_tags.isNotEmpty) const SizedBox(height: 20),
                      if (_shouldShowMediaPreview()) _buildMediaPreview(theme),
                    ],
                  ),
                ),
              ),
              _buildToolbar(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ Karakter sayacı widget
  Widget _buildCharacterCounter(ColorScheme colorScheme) {
    final currentLength = captionController.text.length;
    final isNearLimit = currentLength > _maxCaptionLength * 0.8;
    final isOverLimit = currentLength > _maxCaptionLength;

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOverLimit
                ? Colors.red.withAlpha(26)
                : isNearLimit
                ? Colors.orange.withAlpha(26)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverLimit
                  ? Colors.red
                  : isNearLimit
                  ? Colors.orange
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            '$currentLength/$_maxCaptionLength',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOverLimit
                  ? Colors.red
                  : isNearLimit
                  ? Colors.orange
                  : colorScheme.onSurface.withAlpha(154),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagChips(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withAlpha(38),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tag, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                tag,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _removeTag(tag),
                child: Icon(Icons.close, size: 18, color: colorScheme.primary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        icon: Icon(Icons.close, color: colorScheme.onSurface),
      ),
      title: Text(
        isEditing
            ? LocaleKeys.feed_edit_post.tr()
            : LocaleKeys.feed_new_post.tr(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    elevation: 2,
                  ),
                  child: Text(
                    isEditing
                        ? LocaleKeys.common_save.tr()
                        : LocaleKeys.common_share.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInputRow(
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic currentUser,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: _avatarRadius,
          backgroundColor: colorScheme.surfaceContainerHighest,
          backgroundImage: (currentUser?.profileImageUrl != null)
              ? CachedNetworkImageProvider(
                  currentUser.profileImageUrl,
                  cacheManager: CustomImageCacheManager(),
                )
              : null,
          child: (currentUser?.profileImageUrl == null)
              ? Icon(
                  Icons.person,
                  size: _avatarRadius,
                  color: colorScheme.onSurface,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: captionController,
            style: AppTextStyles.labelMedium,
            decoration: InputDecoration(
              hintText: LocaleKeys.feed_what_happening.tr(),
              hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(128)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
            maxLength: _maxCaptionLength,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) {
                  return const SizedBox.shrink(); // Counter yukarıda gösteriliyor
                },
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      ],
    );
  }

  bool _shouldShowMediaPreview() {
    return selectedImage != null ||
        selectedVideo != null ||
        (isEditing && widget.postToEdit?.imageUrl != null);
  }

  Widget _buildMediaPreview(ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_mediaBorderRadius),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: theme.dividerColor.withAlpha(51),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildPreviewContent(),
          ),
        ),
        if (selectedImage != null || selectedVideo != null) _buildCloseButton(),
      ],
    );
  }

  Widget _buildPreviewContent() {
    if (selectedImage != null) {
      return ImagePositioner(
        imageFile: selectedImage!,
        aspectRatio: 4 / 5,
        onPositionChanged: (value) {
          _alignment = value;
        },
      );
    } else if (selectedVideo != null &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else if (isEditing && widget.postToEdit!.imageUrl != null) {
      return Image.network(widget.postToEdit!.imageUrl!, fit: BoxFit.cover);
    }

    return const SizedBox();
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        onTap: _clearMedia,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(179),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 8),
            ],
          ),
          child: const Icon(
            Icons.close,
            color: AppColors.flat,
            size: _closeButtonSize,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withAlpha(51)),
        ),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: _toolbarPadding,
      child: Row(
        children: [
          _buildToolbarButton(
            icon: IconsaxPlusBold.gallery,
            label: 'Galeri',
            onPressed: () => _pickImage(false),
            colorScheme: colorScheme,
          ),
          _buildToolbarButton(
            icon: IconsaxPlusBold.camera,
            label: LocaleKeys.common_camera.tr(),
            onPressed: () => _pickImage(true),
            colorScheme: colorScheme,
          ),
          _buildToolbarButton(
            icon: IconsaxPlusBold.video_circle,
            label: LocaleKeys.common_video.tr(),
            onPressed: _pickVideo,
            colorScheme: colorScheme,
          ),
          _buildToolbarButton(
            icon: IconsaxPlusBold.hashtag,
            label: 'Etiket',
            onPressed: _tags.length < 3 ? _showAddTagDialog : null,
            colorScheme: colorScheme,
            isDisabled: _tags.length >= 3,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.feed_everyone_can_see.tr(),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Modern toolbar button
  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
    bool isDisabled = false,
  }) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 28, // 🎨 Büyütüldü
        ),
        color: isDisabled
            ? colorScheme.onSurface.withAlpha(77)
            : colorScheme.primary,
        style: IconButton.styleFrom(
          backgroundColor: isDisabled
              ? colorScheme.surfaceContainerHighest.withAlpha(128)
              : colorScheme.primary.withAlpha(26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
