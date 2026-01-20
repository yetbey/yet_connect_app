import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/config/theme/app_text_styles.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/chat/presentation/widgets/image_viewer/full_screen_image_viewer.dart';
import 'package:yet_x_app/features/profile/presentation/widgets/stat_column.dart';
import 'package:yet_x_app/features/profile/utils/profile_image_manager.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';

class ProfileCard extends ConsumerWidget {
  final UserModel user;
  final bool isMe;
  final int postCount;

  const ProfileCard({
    super.key,
    required this.user,
    required this.isMe,
    required this.postCount,
  });

  static const _avatarRadius = 70.0;
  static const _borderWidth = 2.0;
  static const _cardBorderRadius = 24.0;
  static const _buttonHeight = 50.0;
  static const _profileImageCacheSize = 280;

  Future<ImageProvider> _getImageProvider(String? networkImageUrl) async {
    final localImage = await ProfileImageManager.loadProfileImage(user.id);
    if (localImage != null) {
      return FileImage(localImage);
    }

    // Local'de yoksa network'ten çek ve kaydet
    if (networkImageUrl != null) {
      await ProfileImageManager.saveProfileImage(networkImageUrl, user.id);
      return CachedNetworkImageProvider(
        networkImageUrl,
        maxHeight: _profileImageCacheSize,
        maxWidth: _profileImageCacheSize,
      );
    }

    return const AssetImage('assets/images/yet.jpg');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.grey.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Profil Resmi
          _buildProfileImage(context, theme, colorScheme),
          const SizedBox(height: 16),
          // 2. İsim ve Kullanıcı Adı
          _buildUserInfo(context),
          const SizedBox(height: 24),
          // 3. İstatistikler
          _buildStats(theme),
          const SizedBox(height: 24),
          // 4. Biyografi
          if (user.bio != null && user.bio!.isNotEmpty) _buildBio(context),
          const Spacer(),
          // 5. Aksiyon Butonları
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildProfileImage(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.primary, width: _borderWidth),
      ),
      child: GestureDetector(
        onTap: () {
          if (user.profileImageUrl != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FullScreenImageViewer(imageUrl: user.profileImageUrl!),
              ),
            );
          }
        },
        child: FutureBuilder<ImageProvider>(
          future: _getImageProvider(user.profileImageUrl),
          builder: (context, snapshot) {
            return CircleAvatar(
              radius: _avatarRadius,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage:
                  snapshot.data ?? const AssetImage('assets/images/yet.jpg'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      children: [
        Text(
          user.fullName,
          style: AppTextStyles.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text('@${user.userName}', style: AppTextStyles.bodyMedium),
      ],
    );
  }

  Widget _buildStats(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StatColumn(label: 'Gönderi', count: postCount.toString()),
        Container(width: 1, height: 40, color: theme.dividerColor),
        StatColumn(
          label: 'Takipçi',
          count: user.followersCount.toString(),
          onTap: () => NavigationService.toNamed(
            AppRoutes.followList,
            arguments: {'userId': user.id, 'initialTabIndex': 0},
          ),
        ),
        Container(width: 1, height: 40, color: theme.dividerColor),
        StatColumn(
          label: 'Takip',
          count: user.followingCount.toString(),
          onTap: () => NavigationService.toNamed(
            AppRoutes.followList,
            arguments: {'userId': user.id, 'initialTabIndex': 1},
          ),
        ),
      ],
    );
  }

  Widget _buildBio(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        user.bio!,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    if (isMe) {
      return SizedBox(
        width: double.infinity,
        height: _buttonHeight,
        child: FilledButton.icon(
          onPressed: () => NavigationService.toNamed(AppRoutes.editProfile),
          icon: const Icon(IconsaxPlusBold.edit),
          label: const Text('Profili Düzenle'),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    // ✅ Provider çağrılarını önbelleğe al
    final userNotifier = ref.read(userProvider.notifier);
    final isFollowing = userNotifier.isFollowingUser(user.id);
    final userState = ref.watch(userProvider);
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _buttonHeight,
            child: userState.isFollowingLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildFollowButton(theme, userNotifier, isFollowing),
          ),
        ),
        const SizedBox(width: 12),
        _buildMessageButton(context, ref),
      ],
    );
  }

  Widget _buildFollowButton(
    ThemeData theme,
    dynamic userNotifier,
    bool isFollowing,
  ) {
    if (isFollowing) {
      return OutlinedButton(
        onPressed: () => userNotifier.toggleFollowUser(user.id),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: const Text('Takip Ediliyor'),
      );
    }

    return FilledButton(
      onPressed: () => userNotifier.toggleFollowUser(user.id),
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text('Takip Et'),
    );
  }

  Widget _buildMessageButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: _buttonHeight,
      width: _buttonHeight,
      child: IconButton.filledTonal(
        onPressed: () async {
          final chatId = await ref
              .read(chatListProvider.notifier)
              .startChat(user.id);

          if (!context.mounted) return;

          if (chatId != null) {
            NavigationService.toNamed(
              AppRoutes.chatDetail,
              arguments: {'chatId': chatId, 'otherUser': user},
            );
          }
        },
        icon: const Icon(IconsaxPlusBold.message),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
