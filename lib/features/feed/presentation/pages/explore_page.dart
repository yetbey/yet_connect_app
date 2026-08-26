// ============================================================================
// HOME / EXPLORE FEED PAGE - MODERN VERSION (Fixed)
// ============================================================================

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/features/feed/presentation/providers/video_feed_provider.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/image_feed_card.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/shimmer_feed_card.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/text_feed_card.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/video_feed_card.dart';
import 'package:yet_x_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/widgets/pulse_animation.dart';
import '../../../story/presentation/providers/story_provider.dart';
import '../../../story/presentation/widgets/story_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  late final ScrollController _scrollController;
  bool _showFab = false;
  List<String> _dynamicCategories = [];
  bool _categoriesLoaded = false;
  Timer? _fabDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).fetchPosts();
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final followedTags = await ref.read(followedTagsProvider.future);
      setState(() {
        _dynamicCategories = [
          LocaleKeys.feed_all.tr(),
          LocaleKeys.feed_following.tr(),
          ...followedTags,
        ];
        _categoriesLoaded = true;
      });
    } catch (_) {
      setState(() {
        _dynamicCategories = [
          LocaleKeys.feed_all.tr(),
          LocaleKeys.feed_following.tr(),
        ];
        _categoriesLoaded = true;
      });
    }
  }

  void _onCategorySelected(int index) {
    if (_selectedIndex == index) return;

    // Stop all videos
    ref.read(videoFeedProvider.notifier).stopAll();

    setState(() {
      _selectedIndex = index;
    });

    // Scroll to top
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    _loadPostsForIndex(index);
  }

  void _loadPostsForIndex(int index) {
    if (index == 0) {
      final currentState = ref.read(feedProvider);
      if (currentState.isFollowingOnly || currentState.posts.isEmpty) {
        ref
            .read(feedProvider.notifier)
            .fetchPosts(isRefresh: true, onlyFollowing: false);
      }
    } else if (index == 1) {
      final currentState = ref.read(feedProvider);
      if (!currentState.isFollowingOnly || currentState.posts.isEmpty) {
        ref
            .read(feedProvider.notifier)
            .fetchPosts(isRefresh: true, onlyFollowing: true);
      }
    } else {
      final selectedTag = _dynamicCategories[index];
      ref.invalidate(postsByTagProvider(selectedTag));
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_selectedIndex == 0 || _selectedIndex == 1) {
        ref.read(feedProvider.notifier).fetchPosts();
      }
    }

    _fabDebounce?.cancel();
    _fabDebounce = Timer(const Duration(milliseconds: 100), () {
      final offset = _scrollController.offset;
      final shouldShow = offset > 300;
      if (_showFab != shouldShow) {
        setState(() {
          _showFab = shouldShow;
        });
      }
    });
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildPostsForCategory(int index) {
    if (!_categoriesLoaded) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (index > 1) {
      final selectedTag = _dynamicCategories[index];
      final tagPosts = ref.watch(postsByTagProvider(selectedTag));
      return tagPosts.when(
        data: (posts) {
          if (posts.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sell_outlined,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleKeys.feed_no_posts_the_tag.tr(),
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildPostsList(posts);
        },
        loading: () => SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ShimmerFeedCard(),
            ),
            childCount: 3,
          ),
        ),
        error: (e, _) =>
            SliverFillRemaining(child: Center(child: Text('Error: $e'))),
      );
    }

    final allPosts = ref.watch(feedProvider.select((state) => state.posts));
    final isLoading = ref.watch(
      feedProvider.select((state) => state.isLoading),
    );
    final isFollowingOnly = ref.watch(
      feedProvider.select((state) => state.isFollowingOnly),
    );

    if (isLoading && allPosts.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ShimmerFeedCard(),
          ),
          childCount: 3,
        ),
      );
    } else if (allPosts.isEmpty) {
      if (index == 1 && isFollowingOnly) {
        return SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    LocaleKeys.feed_not_following_yet.tr(),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    LocaleKeys.feed_start_following_to_see_interesting.tr(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return SliverFillRemaining(
        child: Center(
          child: Text(
            LocaleKeys.feed_no_image_posts.tr(),
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    } else {
      return _buildPostsList(allPosts);
    }
  }

  Widget _buildFeedCard(PostModel post, int index) {
    final hasImage = post.imageUrl?.isNotEmpty ?? false;
    final hasVideo = post.videoUrl?.isNotEmpty ?? false;

    if (hasImage) {
      return ImageFeedCard(key: ValueKey(post.id), post: post);
    } else if (hasVideo) {
      return VideoFeedCard(key: ValueKey(post.id), post: post);
    } else {
      return TextFeedCard(key: ValueKey(post.id), post: post, index: index);
    }
  }

  SliverList _buildPostsList(List<PostModel> posts) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final post = posts[index];
          return RepaintBoundary(
            child: _buildFeedCard(post, index),
          );
        },
        childCount: posts.length,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(followedTagsProvider, (previous, next) {
      next.whenData((followedTags) {
        final newCategories = [
          LocaleKeys.feed_all.tr(),
          LocaleKeys.feed_following.tr(),
          ...followedTags,
        ];

        if (_dynamicCategories.length != newCategories.length) {
          setState(() {
            _dynamicCategories = newCategories;
            _categoriesLoaded = true;
          });
        }
      });
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          bottom: false,
          child: _categoriesLoaded && _dynamicCategories.isNotEmpty
              ? RefreshIndicator(
            color: theme.primaryColor,
            backgroundColor: theme.colorScheme.surface,
            onRefresh: () async {
              ref.invalidate(followedTagsProvider);
              ref.invalidate(followingStoriesProvider);

              if (_selectedIndex > 1) {
                final selectedTag = _dynamicCategories[_selectedIndex];
                ref.invalidate(postsByTagProvider(selectedTag));
              } else {
                await ref.read(feedProvider.notifier).fetchPosts(
                  isRefresh: true,
                  onlyFollowing: _selectedIndex == 1,
                );
              }

              await _loadCategories();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              cacheExtent: 1000,
              slivers: [
                //  Modern App Bar
                SliverAppBar(
                  expandedHeight: 150,
                  automaticallyImplyLeading: false,
                  floating: true,
                  pinned: true,
                  snap: false,
                  elevation: 0,
                  backgroundColor: theme.colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            theme.dividerColor.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final expandRatio = (constraints.maxHeight - kToolbarHeight) / (150 - kToolbarHeight);

                      return FlexibleSpaceBar(
                        titlePadding: EdgeInsets.zero,
                        background: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border(
                              bottom: BorderSide(
                                color: theme.dividerColor.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Bar
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 2, 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        LocaleKeys.navigation_feed.tr(),
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => NavigationService.toNamed(AppRoutes.createPost),
                                      visualDensity: VisualDensity.compact,
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.add_rounded, color: theme.primaryColor, size: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      onPressed: () => NavigationService.push(
                                        const NotificationsPage(userId: ''),
                                        type: PageTransitionType.rightToLeft,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.notifications_outlined, color: theme.primaryColor, size: 22),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ✅ FIX: Pills bar kaybolsun ama yenisi çıkmasın
                              if (expandRatio > 0.3)
                                _ModernCategoryPills(
                                  categories: _dynamicCategories,
                                  selectedIndex: _selectedIndex,
                                  onCategorySelected: _onCategorySelected,
                                ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),

                        // ✅ FIX: title null - Hiçbir şey gösterme!
                        title: null,
                      );
                    },
                  ),
                ),


                const SliverToBoxAdapter(
                  child: StoryBar(),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                _buildPostsForCategory(_selectedIndex),
              ],
            ),
          )
              : const Center(child: CircularProgressIndicator()),
        ),
        floatingActionButton: _showFab
            ? PulseAnimation(
          duration: const Duration(milliseconds: 1500),
          minScale: 0.95,
          maxScale: 1.08,
          child: FloatingActionButton.small(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _scrollToTop();
            },
            backgroundColor: theme.primaryColor,
            elevation: 8,
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        )
            : null,
      ),
    );
  }
}

// ============================================================================
// MODERN CATEGORY PILLS
// ============================================================================

class _ModernCategoryPills extends StatefulWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  const _ModernCategoryPills({
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  State<_ModernCategoryPills> createState() => _ModernCategoryPillsState();
}

class _ModernCategoryPillsState extends State<_ModernCategoryPills> {
  late ScrollController _scrollController;
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    for (int i = 0; i < widget.categories.length; i++) {
      _itemKeys[i] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ModernCategoryPills oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedItem();
      });
    }
  }

  void _scrollToSelectedItem() {
    final selectedKey = _itemKeys[widget.selectedIndex];
    if (selectedKey?.currentContext == null) return;

    final renderBox =
    selectedKey!.currentContext!.findRenderObject() as RenderBox;
    final itemPosition = renderBox.localToGlobal(Offset.zero).dx;
    final itemWidth = renderBox.size.width;
    final screenWidth = MediaQuery.of(context).size.width;
    final centerOffset = (screenWidth / 2) - (itemWidth / 2);
    final targetScroll = _scrollController.offset + itemPosition - centerOffset;

    _scrollController.animateTo(
      targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.95),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = widget.selectedIndex == index;
          return GestureDetector(
            key: _itemKeys[index],
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onCategorySelected(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isSelected
                    ? null
                    : (isDark
                    ? Colors.grey[800]?.withValues(alpha: 0.6)
                    : Colors.grey[200]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.5)
                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.categories[index].toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[200] : Colors.grey[800]),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
