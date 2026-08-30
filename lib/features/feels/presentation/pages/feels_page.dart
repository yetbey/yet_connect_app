import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:yet_x_app/core/constants/app_colors.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/features/feed/data/post_repository.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/features/gamification/data/models/announcement_model.dart';
import 'package:yet_x_app/features/gamification/presentation/pages/leaderboard_page.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/features/feels/presentation/providers/feels_provider.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:yet_x_app/features/gamification/presentation/providers/announcement_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class FeelsPage extends ConsumerStatefulWidget {
  const FeelsPage({super.key});

  @override
  ConsumerState<FeelsPage> createState() => _FeelsPageState();
}

class _FeelsPageState extends ConsumerState<FeelsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnimController;
  late Animation<double> _headerAnimation;
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    testFirebaseConnection();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );

    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_showTitle) {
        setState(() => _showTitle = true);
      } else if (_scrollController.offset <= 100 && _showTitle) {
        setState(() => _showTitle = false);
      }
    });
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _scrollController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  void testFirebaseConnection() async {
    try {
      final ref = FirebaseDatabase.instance.ref('test');
      await ref.set({
        'message': 'Scrabble test',
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('✅ Firebase Realtime Database çalışıyor!');

      final snapshot = await ref.get();
      if (snapshot.exists) {
        print('📖 Okunan veri: ${snapshot.value}');
      }
    } catch (e) {
      print('❌ Firebase hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(popularTagsProvider);
            ref.invalidate(followedTagsProvider);
            ref.invalidate(featuredUsersProvider);
            ref.read(feelsProvider.notifier).refresh();
            await ref.read(feedProvider.notifier).fetchPosts(isRefresh: true);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ✨ App Bar
              _buildSliverAppBar(theme, colorScheme),

              // 1️⃣ Hero Banner
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerAnimation,
                  child: _buildHeroBanner(context),
                ),
              ),

              // 🔥 Streak Counter
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildStreakCounter(context),
                ),
              ),

              // 🎨 Mood Tracker
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildMoodTracker(context),
                ),
              ),

              // 🎯 Daily Missions
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildDailyMissions(context),
                ),
              ),

              // 2️⃣ Announcements
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildAnnouncementBanners(context),
                ),
              ),

              // 🎁 Weekly Rewards
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildWeeklyRewards(context),
                ),
              ),

              // 📸 Daily Photo Challenge
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildDailyPhotoChallenge(context),
                ),
              ),

              // 🎉 Live Events
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildLiveEvents(context),
                ),
              ),

              // 🎲 Random Discovery
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildRandomDiscovery(context),
                ),
              ),

              // 🎪 Mini Games
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildMiniGames(context),
                ),
              ),

              // 3️⃣ Weekly Top Users
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildWeeklyTopUsers(context),
                ),
              ),

              // 🏆 Leaderboard
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildLeaderboard(context),
                ),
              ),

              // 📊 Personal Stats
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildPersonalStats(context),
                ),
              ),

              // 4️⃣ Popular Tags
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildPopularTagsGrid(context),
                ),
              ),

              // 5️⃣ Followed Tags
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildFollowedTags(context),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  Widget _buildSliverAppBar(ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface.withValues(
        alpha: _showTitle ? 1 : 0,
      ),
      title: AnimatedOpacity(
        opacity: _showTitle ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          '✨ Feels',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 1️⃣ HERO BANNER
  // ============================================================================

  Widget _buildHeroBanner(BuildContext context) {
    final currentUser = ref.watch(userProvider).currentUser;
    final firstName = currentUser?.fullName.split(' ').first ?? 'Kullanıcı';

    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF26A69A), Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Merhaba $firstName! 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bugün ne hissediyorsun?',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      NavigationService.toNamed(AppRoutes.createPost);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text(
                      'Gönderi Paylaş',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 🔥 STREAK COUNTER
  // ============================================================================

  Widget _buildStreakCounter(BuildContext context) {
    final feelsState = ref.watch(feelsProvider);
    final currentStreak = feelsState.currentStreak;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStreak > 0
                      ? '$currentStreak Günlük Seri! 🔥'
                      : 'Seri Başlat!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  currentStreak > 0
                      ? 'Devam et! 🎉'
                      : 'Bugün paylaşım yap',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              currentStreak > 0 ? Icons.trending_up : Icons.rocket_launch,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🎨 MOOD TRACKER
  // ============================================================================

  Widget _buildMoodTracker(BuildContext context) {
    final feelsState = ref.watch(feelsProvider);
    final selectedMood = feelsState.selectedMood;
    final aiMessage = feelsState.aiMessage; // YENİ
    final isAiLoading = feelsState.isAiLoading; // YENİ

    final moods = [
      {'emoji': '😊', 'label': 'Mutlu', 'color': const Color(0xFF4FACFE)},
      {'emoji': '😎', 'label': 'Havalı', 'color': const Color(0xFFB06AB3)},
      {'emoji': '🤔', 'label': 'Düşünceli', 'color': const Color(0xFF667eea)},
      {'emoji': '😴', 'label': 'Yorgun', 'color': const Color(0xFF764ba2)},
      {'emoji': '🔥', 'label': 'Enerjik', 'color': const Color(0xFFFF6B6B)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.mood, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Bugün nasıl hissediyorsun?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: moods.length,
            itemBuilder: (context, index) {
              final mood = moods[index];
              final isSelected = selectedMood == mood['label'];

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(feelsProvider.notifier).selectMood(mood['label'] as String);
                },
                child: Container(
                  width: 75,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      colors: [
                        mood['color'] as Color,
                        (mood['color'] as Color).withValues(alpha: 0.7),
                      ],
                    )
                        : null,
                    color: isSelected
                        ? null
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mood['emoji'] as String,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mood['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // YENİ: YAPAY ZEKA MESAJ KUTUSU
        if (isAiLoading || aiMessage != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.secondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isAiLoading
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YET AI düşünüyor...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        color: AppColors.primary,
                        minHeight: 2,
                      ),
                    ],
                  )
                      : DefaultTextStyle(
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          aiMessage ?? '',
                          speed: const Duration(milliseconds: 50),
                        ),
                      ],
                      totalRepeatCount: 1,
                      displayFullTextOnTap: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================================
  // 🎯 DAILY MISSIONS
  // ============================================================================

  Widget _buildDailyMissions(BuildContext context) {
    final feelsState = ref.watch(feelsProvider);
    final missions = feelsState.dailyMissions;

    if (missions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 26),
              const SizedBox(width: 8),
              Text(
                'Günlük Görevler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...missions.map((mission) => _buildMissionCard(mission)),
      ],
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final IconData icon;
    switch (mission['icon']) {
      case 'edit':
        icon = Icons.edit;
        break;
      case 'favorite':
        icon = Icons.favorite;
        break;
      case 'comment':
        icon = Icons.comment;
        break;
      default:
        icon = Icons.check_circle;
    }

    final color = Color(mission['color'] as int);
    final progress = mission['progress'] as double;
    final current = mission['current'] as int;
    final target = mission['target'] as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${mission['title']} ($current/$target)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mission['reward'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 2️⃣ ANNOUNCEMENTS
  // ============================================================================

  Widget _buildAnnouncementBanners(BuildContext context) {
    final announcementsState = ref.watch(announcementsProvider);
    final announcements = announcementsState.announcements;

    if (announcementsState.isLoading && announcements.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.campaign, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Duyurular',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAnnouncementCard(
                  title: announcement.title,
                  description: announcement.description,
                  gradient: [announcement.startColor, announcement.endColor],
                  icon: announcement.iconData,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _handleAnnouncementTap(announcement);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: SmoothPageIndicator(
            controller: _bannerController,
            count: announcements.length,
            effect: WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: AppColors.primary,
              dotColor: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }

  void _handleAnnouncementTap(AnnouncementModel announcement) {
    switch (announcement.actionType) {
      case 'tag':
        if (announcement.actionValue != null) {
          NavigationService.toNamed(
            AppRoutes.tagPosts,
            arguments: {'tag': announcement.actionValue},
          );
        }
        break;

      case 'post':
        if (announcement.actionValue != null) {
          _openPostDetail(announcement.actionValue!);
        }
        break;

      case 'url':
        if (announcement.actionValue != null) {
          _openExternalUrl(announcement.actionValue!);
        }
        break;

      default:
      // 'none' → hiçbir şey yapma
        break;
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPostDetail(String postId) async {
    final repository = ref.read(postRepositoryProvider);
    final post = await repository.getPostById(postId);

    if (!mounted) return;

    if (post != null) {
      NavigationService.toNamed(
        AppRoutes.detailedPost,
        arguments: {'post': post},
      );
    }
  }

  Widget _buildAnnouncementCard({
    required String title,
    required String description,
    required List<Color> gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 🎁 WEEKLY REWARDS
  // ============================================================================

  Widget _buildWeeklyRewards(BuildContext context) {
    final feelsState = ref.watch(feelsProvider);
    final currentPoints = feelsState.weeklyPoints;
    final targetPoints = feelsState.weeklyPointsTarget;
    final progress = (currentPoints / targetPoints).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB06AB3), Color(0xFF4568DC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB06AB3).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Haftalık Ödül',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currentPoints/$targetPoints puan - ${currentPoints >= targetPoints ? 'Tebrikler! 🎉' : 'Rozet kazan!'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              strokeWidth: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 📸 DAILY PHOTO CHALLENGE
  // ============================================================================

  Widget _buildDailyPhotoChallenge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF512F).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            // TODO: Show challenge details
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Günün Challenge\'ı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tema: Gün Batımı 🌅',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 🎉 LIVE EVENTS
  // ============================================================================

  Widget _buildLiveEvents(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E3192).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            // TODO: Join live event
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'CANLI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '156 kişi izliyor',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Haftalık Soru-Cevap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Moderatörlerimizle canlı sohbet!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 🎲 RANDOM DISCOVERY
  // ============================================================================

  Widget _buildRandomDiscovery(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final repository = ref.read(postRepositoryProvider);
          final post = await repository.getRandomPost();

          if (!context.mounted) return;

          if (post != null) {
            NavigationService.toNamed(
              AppRoutes.detailedPost,
              arguments: {'post': post},
            );
          } else {
            Utils.showSnackBar(
              text: 'Henüz gösterilecek gönderi yok',
              isError: true,
            );
          }
        },
        icon: const Icon(Icons.shuffle_rounded, size: 28),
        label: const Text(
          'Şansını Dene - Rastgele Keşfet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  // ============================================================================
  // 🎪 MINI GAMES
  // ============================================================================

  Widget _buildMiniGames(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.gamepad, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 8),
              Text(
                '🎮 Mini Oyunlar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              // Scrabble Oyunu
              _buildGameCard(
                context: context,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                icon: Icons.grid_on_rounded,
                title: 'Scrabble',
                subtitle: '4 Kişilik Online',
                badge: 'YENİ',
                badgeColor: Colors.red,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  NavigationService.toNamed(AppRoutes.scrabbleLobby);
                },
              ),

              // Gelecekteki oyunlar için placeholder'lar
              _buildGameCard(
                context: context,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                ),
                icon: Icons.psychology,
                title: 'Kelime Oyunu',
                subtitle: 'Yakında',
                badge: 'YAKINDA',
                badgeColor: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Çok yakında!')),
                  );
                },
              ),

              _buildGameCard(
                context: context,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                ),
                icon: Icons.quiz,
                title: 'Trivia',
                subtitle: 'Geliştiriliyor',
                badge: 'YAKINDA',
                badgeColor: Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Çok yakında!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required Gradient gradient,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 8),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Dekoratif pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GameCardPatternPainter(),
                  ),
                ),

                // İçerik
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon ve Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor ?? Colors.red,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: (badgeColor ?? Colors.red)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const Spacer(),

                      // Başlık
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Alt başlık
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Oyna butonu
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Oyna',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ============================================================================
  // 3️⃣ WEEKLY TOP USERS
  // ============================================================================

  // ============================================================================
// 3️⃣ WEEKLY TOP USERS - GÜNCELLENMIŞ
// ============================================================================
  Widget _buildWeeklyTopUsers(BuildContext context) {
    final featuredAsync = ref.watch(featuredUsersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    'Haftanın Yıldızları',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  // TODO: Navigate to full leaderboard
                  Utils.showSnackBar(
                    text: 'Tam liste yakında gelecek!',
                    isError: false,
                  );
                },
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
        ),
        featuredAsync.when(
          data: (users) {
            if (users.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Henüz öne çıkan kullanıcı yok'),
                ),
              );
            }

            return SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildTopUserCard(user, index + 1);
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Yüklenemedi',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopUserCard(UserModel user, int rank) {
    final colors = [
      [const Color(0xFFFFD700), const Color(0xFFFF8C00)], // Gold
      [const Color(0xFFC0C0C0), const Color(0xFF808080)], // Silver
      [const Color(0xFFCD7F32), const Color(0xFF8B4513)], // Bronze
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // Blue
    ];

    final gradient = colors[(rank - 1).clamp(0, colors.length - 1)];

    final medals = ['🥇', '🥈', '🥉', '🏅', '🏅'];
    final medal = medals[(rank - 1).clamp(0, medals.length - 1)];

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient[0].withValues(alpha: 0.2),
            gradient[1].withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gradient[0].withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            NavigationService.toNamed(
              AppRoutes.profile,
              arguments: user.id,
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16), // 20'den 16'ya düşürdük
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ Eklendi
              children: [
                // Rank Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, // 12'den 10'a
                    vertical: 4,    // 6'dan 4'e
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        medal,
                        style: const TextStyle(fontSize: 14), // 16'dan 14'e
                      ),
                      const SizedBox(width: 4), // 6'dan 4'e
                      Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13, // 14'den 13'e
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12), // 16'dan 12'ye

                // Profile Image
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: gradient),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 40, // 45'den 40'a düşürdük
                        backgroundImage: user.profileImageUrl != null
                            ? CachedNetworkImageProvider(
                          user.profileImageUrl!,
                          cacheManager: CustomImageCacheManager(),
                        )
                            : null,
                        child: user.profileImageUrl == null
                            ? Text(
                          user.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28, // 32'den 28'e
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5), // 6'dan 5'e
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 14, // 16'dan 14'e
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10), // 12'den 10'a

                // User Info
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 15, // 16'dan 15'e
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3), // 4'den 3'e
                Text(
                  '@${user.userName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontSize: 11, // ✅ Küçülttük
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12), // ✅ Spacer yerine fixed height

                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        '${user.followers.length}',
                        'Takipçi',
                        Icons.people,
                        gradient[0],
                      ),
                      Container(
                        width: 1,
                        height: 25,
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                      _buildStatItem(
                        '${user.following.length}',
                        'Takip',
                        Icons.person_add,
                        gradient[1],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color), // 18'den 16'ya
          const SizedBox(height: 2), // 4'den 2'ye
          Text(
            value,
            style: TextStyle(
              fontSize: 15, // 16'dan 15'e
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9, // 10'dan 9'a
              color: color.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  // ============================================================================
  // 🏆 LEADERBOARD
  // ============================================================================

  Widget _buildLeaderboard(BuildContext context) {
    final currentUser = ref.watch(userProvider).currentUser;
    final feelsState = ref.watch(feelsProvider);
    final position = feelsState.leaderboardPosition;
    final weeklyPoints = feelsState.leaderboardWeeklyPoints ?? feelsState.weeklyPoints;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD89B), Color(0xFF19547B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD89B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Liderlik Tablosu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      position != null
                      ? 'Bu hafta $weeklyPoints puanla #$position. sıradasın'
                          : 'Bu hafta henüz puan kazanmadın',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      position != null ? '#$position' : '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LeaderboardPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF19547B),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Tüm Sıralamayı Gör',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumView() {
    // TODO: Bu veriler API'dan gelecek
    final topUsers = [
      {'name': 'Ahmet Y.', 'points': 1250, 'rank': 2},
      {'name': 'Mehmet K.', 'points': 1580, 'rank': 1},
      {'name': 'Ayşe D.', 'points': 980, 'rank': 3},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumPlace(topUsers[0], 2),
          _buildPodiumPlace(topUsers[1], 1),
          _buildPodiumPlace(topUsers[2], 3),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(Map<String, dynamic> user, int rank) {
    final colors = rank == 1
        ? [const Color(0xFFFFD700), const Color(0xFFFFAA00)]
        : rank == 2
        ? [const Color(0xFFC0C0C0), const Color(0xFF999999)]
        : [const Color(0xFFCD7F32), const Color(0xFF8B4513)];

    final height = rank == 1
        ? 100.0
        : rank == 2
        ? 80.0
        : 70.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              user['name'].toString().substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '${user['points']} XP',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors[0].withValues(alpha: 0.7),
                colors[1].withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // 📊 PERSONAL STATS
  // ============================================================================

  Widget _buildPersonalStats(BuildContext context) {
    final feelsState = ref.watch(feelsProvider);
    final currentUser = ref.watch(userProvider).currentUser;
    final userStats = feelsState.userStats;

    if (userStats == null) {
      return const SizedBox.shrink();
    }

    final stats = [
      {
        'label': 'Gönderiler',
        'value': userStats['posts']?.toString() ?? '0',
        'icon': Icons.photo_library,
        'color': const Color(0xFF667eea),
      },
      {
        'label': 'Beğeniler',
        'value': userStats['likes']?.toString() ?? '0',
        'icon': Icons.favorite,
        'color': const Color(0xFFFF6B6B),
      },
      {
        'label': 'Takipçi',
        'value': userStats['followers']?.toString() ?? '0',
        'icon': Icons.people,
        'color': const Color(0xFF4FACFE),
      },
      {
        'label': 'Takip',
        'value': userStats['following']?.toString() ?? '0',
        'icon': Icons.person_add,
        'color': const Color(0xFFB06AB3),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: AppColors.primary, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    'İstatistiklerim',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (currentUser != null) {
                    NavigationService.toNamed(
                      AppRoutes.profile,
                      arguments: currentUser.id,
                    );
                  }
                },
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: const Text('Profil'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: stats.map((stat) {
              return TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (stats.indexOf(stat) * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (stat['color'] as Color).withValues(alpha: 0.15),
                        (stat['color'] as Color).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (stat['color'] as Color).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        stat['icon'] as IconData,
                        color: stat['color'] as Color,
                        size: 28,
                      ),
                      const Spacer(),
                      Text(
                        stat['value'] as String,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: stat['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat['label'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient[0].withValues(alpha: 0.15),
            gradient[1].withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradient[0].withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: gradient[0],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 4️⃣ POPULAR TAGS
  // ============================================================================

  Widget _buildPopularTagsGrid(BuildContext context) {
    final popularAsync = ref.watch(popularTagsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: AppColors.primary, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    'Trendler',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Popüler',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        popularAsync.when(
          data: (tags) {
            if (tags.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Henüz trend etiket yok')),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tags.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tag = entry.value;
                  final tagName = tag['name'] as String;
                  final postCount = tag['post_count'] as int? ?? 0;

                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 150 + (index * 40)),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 15 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildPopularTagChip(tagName, postCount, index),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Yüklenemedi')),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularTagChip(String tag, int count, int index) {
    final colors = [
      [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFFB06AB3), const Color(0xFF4568DC)],
      [const Color(0xFFFF512F), const Color(0xFFDD2476)],
      [const Color(0xFF2E3192), const Color(0xFF1BFFFF)],
    ];

    final gradient = colors[index % colors.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient[0].withValues(alpha: 0.15),
            gradient[1].withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradient[0].withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            NavigationService.toNamed(
              AppRoutes.tagPosts,
              arguments: {'tag': tag},
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$tag',
                  style: TextStyle(
                    color: gradient[0],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: gradient[0].withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: gradient[0],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  // ============================================================================
  // 5️⃣ FOLLOWED TAGS
  // ============================================================================

  Widget _buildFollowedTags(BuildContext context) {
    final followedAsync = ref.watch(followedTagsProvider);

    return followedAsync.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Takip Ettiğin Etiketler',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 45,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('#${tags[index]}'),
                      avatar: const Icon(Icons.tag, size: 16),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      onPressed: () {
                        NavigationService.toNamed(
                          AppRoutes.tagPosts,
                          arguments: {'tag': tags[index]},
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

// ============================================================================
// DOT PATTERN PAINTER
// ============================================================================

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for game card pattern
class _GameCardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    const spacing = 15.0;
    const radius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
