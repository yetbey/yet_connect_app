import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:yet_x_app/core/constants/app_colors.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/shimmer_feed_card.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/text_feed_card.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/video_feed_card.dart';
import 'package:yet_x_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  UserModel? _otherUserProfile;
  bool _isLoadingOtherUser = false;
  late TabController _tabController;
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;
  static const double _cardSpacing = 12.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndFetchOtherUser();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAndFetchOtherUser() async {
    final myId = ref.read(userProvider).currentUser?.id;

    if (widget.userId != null && widget.userId != myId) {
      if (mounted) setState(() => _isLoadingOtherUser = true);

      final user = await ref
          .read(userProvider.notifier)
          .getUserById(widget.userId!);

      if (mounted) {
        setState(() {
          _otherUserProfile = user;
          _isLoadingOtherUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userState = ref.watch(userProvider);
    final myUser = userState.currentUser;
    final myId = myUser?.id;
    final targetUserId = widget.userId ?? myId;

    if (targetUserId == null) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) {
            FocusScope.of(context).unfocus();
          }
        },
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final bool isMe = (targetUserId == myId);
    final userToShow = isMe ? myUser : _otherUserProfile;

    if (!isMe && _isLoadingOtherUser) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) {
            FocusScope.of(context).unfocus();
          }
        },
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (userToShow == null) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) {
            FocusScope.of(context).unfocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(title: Text(LocaleKeys.navigation_profile.tr())),
          body: Center(child: Text(LocaleKeys.search_user_not_found.tr())),
        ),
      );
    }

    final postsAsyncValue = ref.watch(profilePostsProvider(targetUserId));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(userToShow, isMe, colorScheme),
        body: postsAsyncValue.when(
          data: (posts) =>
              _buildContent(posts, userToShow, isMe, targetUserId, colorScheme),
          loading: () => _buildLoadingState(),
          error: (err, stack) => Center(
            child: Text('${LocaleKeys.errors_default_error.tr()}: $err'),
          ),
        ),
      ),
    );
  }

  // AppBar
  PreferredSizeWidget _buildAppBar(
    UserModel user,
    bool isMe,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      title: Text('@${user.userName}'),
      centerTitle: true,
      scrolledUnderElevation: 0.0,
      elevation: 0,
      actions: [
        if (isMe)
          IconButton(
            onPressed: () => NavigationService.toNamed(AppRoutes.settings),
            icon: const Icon(IconsaxPlusBold.setting),
          ),
      ],
    );
  }

  // Main Content with 3 Tabs
  Widget _buildContent(
    List posts,
    UserModel userToShow,
    bool isMe,
    String targetUserId,
    ColorScheme colorScheme,
  ) {
    final imagePosts = posts.where((post) {
      final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
      final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
      return hasImage && !hasVideo;
    }).toList();

    final textPosts = posts.where((post) {
      final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
      final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
      return !hasImage && !hasVideo;
    }).toList();

    final videoPosts = posts.where((post) {
      return post.videoUrl != null && post.videoUrl!.isNotEmpty;
    }).toList();

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: ProfileHeader(
              user: userToShow,
              isMe: isMe,
              postCount: posts.length,
            ),
          ),

          // TabBar (3 Tabs)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                indicatorWeight: 2.5, // 1.5'ten 2.5'e çıkarıldı
                indicatorSize: TabBarIndicatorSize.label, // ← EKLE
                labelColor: colorScheme.onSurface,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ), // ← EKLE
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                ), // ← EKLE
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on, size: 28)),
                  Tab(icon: Icon(Icons.text_fields, size: 28)),
                  Tab(icon: Icon(Icons.video_library, size: 28)),
                ],
              ),
              colorScheme.surface,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          // Grid Tab (Images)
          RefreshIndicator(
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            onRefresh: () => _handleRefresh(isMe, targetUserId),
            child: imagePosts.isEmpty
                ? _buildEmptyState(
                    LocaleKeys.feed_no_image_posts.tr(),
                    Icons.image_outlined,
                  )
                : _buildGridTab(imagePosts),
          ),

          // Text Tab (List)
          RefreshIndicator(
            backgroundColor: colorScheme.surface,
            onRefresh: () => _handleRefresh(isMe, targetUserId),
            child: textPosts.isEmpty
                ? _buildEmptyState(
                    LocaleKeys.feed_no_text_posts.tr(),
                    Icons.text_fields,
                  )
                : _buildTextTab(textPosts),
          ),

          // Video Tab (List)
          RefreshIndicator(
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            onRefresh: () => _handleRefresh(isMe, targetUserId),
            child: videoPosts.isEmpty
                ? _buildEmptyState(
                    LocaleKeys.feed_no_video_posts.tr(),
                    Icons.video_library_outlined,
                  )
                : _buildVideoTab(videoPosts),
          ),
        ],
      ),
    );
  }

  // Grid Tab
  Widget _buildGridTab(List imagePosts) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: imagePosts.length,
      itemBuilder: (context, index) {
        final post = imagePosts[index];
        return _buildGridItem(post);
      },
    );
  }

  // Grid Item
  Widget _buildGridItem(dynamic post) {
  return GestureDetector(
    onTap: () {
      HapticFeedback.mediumImpact();
      NavigationService.toNamed(
        AppRoutes.detailedPost,
        arguments: {'post': post},
      );
    },
    child: Hero(
      tag: 'post_image_${post.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: post.imageUrl!,
                fit: BoxFit.cover,
                memCacheHeight: 512,
                memCacheWidth: 512,
                maxHeightDiskCache: 1024,
                maxWidthDiskCache: 1024,
                cacheManager: CustomImageCacheManager(),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) =>  Container(
                  color: AppColors.cardColor,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary.withValues(alpha:  0.5),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.cardColor,
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error.withValues(alpha:  0.7),
                  ),
                ),
              ),
              // Subtle gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha:  0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // Text Tab (List style)
  Widget _buildTextTab(List textPosts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      itemCount: textPosts.length,
      itemBuilder: (context, index) {
        final post = textPosts[index];
        final stableIndex = post.id.hashCode.abs() % 5;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: TextFeedCard(
            key: ValueKey('text_${textPosts[index].id}'),
            post: textPosts[index],
            index: stableIndex,
          ),
        );
      },
    );
  }

  // Video Tab (List style)
  Widget _buildVideoTab(List videoPosts) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: videoPosts.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: _cardSpacing),
          child: VideoFeedCard(
            key: ValueKey('video_${videoPosts[index].id}'),
            post: videoPosts[index],
          ),
        );
      },
    );
  }

  // Empty State
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Refresh Handler
  Future<void> _handleRefresh(bool isMe, String targetUserId) async {
    if (!isMe) {
      await _checkAndFetchOtherUser();
    } else {
      await ref.read(userProvider.notifier).getUserById(targetUserId);
    }

    ref.invalidate(profilePostsProvider(targetUserId));
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: _cardSpacing),
        child: ShimmerFeedCard(),
      ),
    );
  }
}

// Sticky TabBar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _StickyTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
