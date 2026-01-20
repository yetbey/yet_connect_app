import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';

class ProfileHeader extends ConsumerStatefulWidget {
  final UserModel user;
  final bool isMe;
  final int postCount;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.isMe,
    required this.postCount,
  });

  @override
  ConsumerState<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<ProfileHeader>
    with SingleTickerProviderStateMixin {
  static const _avatarRadius = 50.0;
  static const _avatarCacheSize = 200;
  static const _padding = 20.0;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bioText = widget.user.bio ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surface.withOpacity(0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Gradient Background Orbs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.secondary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar and Info Row
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      _buildModernAvatar(context, colorScheme),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.fullName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (bioText.isNotEmpty)
                              Text(
                                bioText,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Glassmorphic Stats
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildGlassmorphicStats(theme, colorScheme),
                ),
                
                const SizedBox(height: 16),
                
                // Modern Action Buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildModernActionButtons(context, ref, colorScheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAvatar(BuildContext context, ColorScheme colorScheme) {
    return Hero(
      tag: 'profile_avatar_${widget.user.id}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          if (widget.user.profileImageUrl != null) {
            NavigationService.toNamed(
              AppRoutes.fullImageViewer,
              arguments: {'imageUrl': widget.user.profileImageUrl},
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.8),
                colorScheme.secondary.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
              border: Border.all(
                color: colorScheme.surface,
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: _avatarRadius,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: widget.user.profileImageUrl != null
                  ? CachedNetworkImageProvider(
                      widget.user.profileImageUrl!,
                      maxHeight: _avatarCacheSize,
                      maxWidth: _avatarCacheSize,
                    )
                  : null,
              child: widget.user.profileImageUrl == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicStats(ThemeData theme, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHigh.withOpacity(0.7),
                colorScheme.surfaceContainerHigh.withOpacity(0.5),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                _buildGlassStatItem(
                  count: widget.postCount.toString(),
                  label: 'Gönderiler',
                  theme: theme,
                  colorScheme: colorScheme,
                  index: 0,
                ),
                const SizedBox(width: 8),
                _buildGlassStatItem(
                  count: widget.user.followersCount.toString(),
                  label: 'Takipçi',
                  theme: theme,
                  colorScheme: colorScheme,
                  index: 1,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    NavigationService.toNamed(
                      AppRoutes.followList,
                      arguments: {'userId': widget.user.id, 'initialTabIndex': 0},
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildGlassStatItem(
                  count: widget.user.followingCount.toString(),
                  label: 'Takip',
                  theme: theme,
                  colorScheme: colorScheme,
                  index: 2,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    NavigationService.toNamed(
                      AppRoutes.followList,
                      arguments: {'userId': widget.user.id, 'initialTabIndex': 1},
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStatItem({
    required String count,
    required String label,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required int index,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 400 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: colorScheme.primary.withValues(alpha:  0.2),
            highlightColor: colorScheme.primary.withValues(alpha:  0.1),
            child: Container(
              height: 90,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.6),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionButtons(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    if (widget.isMe) {
      return _buildGradientButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          NavigationService.toNamed(AppRoutes.editProfile);
        },
        label: 'Profili Düzenle',
        icon: Icons.edit_rounded,
        colorScheme: colorScheme,
        isPrimary: false,
      );
    }

    final userNotifier = ref.read(userProvider.notifier);
    final isFollowing = userNotifier.isFollowingUser(widget.user.id);
    final userState = ref.watch(userProvider);

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: userState.isFollowingLoading
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _buildGradientButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    userNotifier.toggleFollowUser(widget.user.id);
                  },
                  label: isFollowing ? 'Takipten Çık' : 'Takip Et',
                  icon: isFollowing ? Icons.person_remove_rounded : Icons.person_add_rounded,
                  colorScheme: colorScheme,
                  isPrimary: !isFollowing,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: _buildGradientButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              final chatId = await ref
                  .read(chatListProvider.notifier)
                  .startChat(widget.user.id);
              if (context.mounted && chatId != null) {
                NavigationService.toNamed(
                  AppRoutes.chatDetail,
                  arguments: {'chatId': chatId, 'otherUser': widget.user},
                );
              }
            },
            label: 'Mesaj',
            icon: Icons.chat_bubble_rounded,
            colorScheme: colorScheme,
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 12),
        _buildIconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
          },
          icon: Icons.more_horiz_rounded,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool isPrimary,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              )
            : null,
        color: isPrimary ? null : colorScheme.surfaceContainerHigh.withOpacity(0.6),
        border: Border.all(
          color: isPrimary
              ? Colors.transparent
              : colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withOpacity(0.9),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback onPressed,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colorScheme.surfaceContainerHigh.withOpacity(0.6),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
