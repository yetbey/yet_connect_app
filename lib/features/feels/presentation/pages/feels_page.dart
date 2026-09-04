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
import 'package:yet_x_app/features/gamification/presentation/providers/daily_challenge_provider.dart';
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
            ref.invalidate(announcementsProvider);
            ref.invalidate(dailyChallengeProvider);
            ref.read(feelsProvider.notifier).refresh();
            await ref.read(feedProvider.notifier).fetchPosts(isRefresh: true);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // App Bar
              _buildSliverAppBar(theme, colorScheme),

              // Hero Banner
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerAnimation,
                  child: _buildHeroBanner(context),
                ),
              ),

              // Today's Summary (Streak + Points + Ranking)
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildTodayStatsRow(context),
                ),
              ),

              // Mood Tracker
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildMoodTracker(context),
                ),
              ),

              // Daily Missions
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildDailyMissions(context),
                ),
              ),

              // Announcements
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildAnnouncementBanners(context),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildQuickActions(context),
                ),
              ),

              // Mini Games
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildMiniGames(context),
                ),
              ),

              // Weekly Top Users
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildWeeklyTopUsers(context),
                ),
              ),

              // Leaderboard
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildLeaderboard(context),
                ),
              ),

              // Personal Stats
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildPersonalStats(context),
                ),
              ),

              // Popular Tags
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_headerAnimation),
                  child: _buildPopularTagsGrid(context),
                ),
              ),

              // Followed Tags
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
    final currentUser = ref.watch(userProvider).currentUser;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface.withValues(alpha: _showTitle ? 1 : 0),
      leadingWidth: 52,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            if (currentUser != null) {
              NavigationService.toNamed(AppRoutes.profile, arguments: currentUser.id);
            }
          },
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: currentUser?.profileImageUrl != null
                ? CachedNetworkImageProvider(
              currentUser!.profileImageUrl!,
              cacheManager: CustomImageCacheManager(),
            )
                : null,
            child: currentUser?.profileImageUrl == null
                ? Text(
              (currentUser?.fullName.isNotEmpty ?? false)
                  ? currentUser!.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            )
                : null,
          ),
        ),
      ),
      title: AnimatedOpacity(
        opacity: _showTitle ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          '✨ Feels',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pushNamed(AppRoutes.search);
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {
            HapticFeedback.selectionClick();
            if (currentUser != null) {
              NavigationService.toNamed(
                AppRoutes.notifications,
                arguments: {'userId': currentUser.id},
              );
            }
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: AnimatedOpacity(
          opacity: _showTitle ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
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

  Widget _buildTodayStatsRow(BuildContext context) {
    final feelsState = ref.watch(feelsProvider);
    final currentStreak = feelsState.currentStreak;
    final weeklyPoints = feelsState.weeklyPoints;
    final weeklyTarget = feelsState.weeklyPointsTarget;
    final leaderboardPosition = feelsState.leaderboardPosition;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip(
              context: context,
              icon: Icons.local_fire_department,
              accentColor: const Color(0xFFFF6B6B),
              value: '$currentStreak',
              label: currentStreak > 0 ? 'Gün Serisi' : 'Seri Başlat',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pushNamed(AppRoutes.createPost);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatChip(
              context: context,
              icon: Icons.card_giftcard,
              accentColor: AppColors.primary,
              value: '$weeklyPoints',
              label: 'Puan / $weeklyTarget',
              onTap: () {
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatChip(
              context: context,
              icon: Icons.emoji_events,
              accentColor: const Color(0xFF4FACFE),
              value: leaderboardPosition != null
                  ? '#$leaderboardPosition'
                  : '—',
              label: 'Sıralama',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required BuildContext context,
    required IconData icon,
    required Color accentColor,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  ref
                      .read(feelsProvider.notifier)
                      .selectMood(mood['label'] as String);
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
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
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
    final completedCount = feelsState.completedMissionsCount;
    final totalCount = feelsState.totalMissionsCount;

    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    // Hepsi tamamlandıysa kutlama kartı göster
    if (missions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.celebration, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugünlük görevlerin bitti! 🎉',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completedCount görev tamamladın, yarın yeni görevler seni bekliyor.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
              if (completedCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$completedCount tamamlandı',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
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
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
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
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHigh,
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

  // ============================================================================
  // 📸 DAILY PHOTO CHALLENGE & 🎉 LIVE EVENTS % 🎲 RANDOM DISCOVERY
  // ============================================================================

  Widget _buildQuickActions(BuildContext context) {
    final challengeState = ref.watch(dailyChallengeProvider);
    final challenge = challengeState.challenge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Hızlı Aksiyonlar',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              if (challenge != null)
                _buildActionCard(
                  context: context,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                  ),
                  icon: Text(
                    challenge.themeEmoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: 'Günün Challenge\'ı',
                  subtitle: challenge.themeTitle,
                  footer:
                      '${challengeState.participantCount} katılım · +${challenge.rewardPoints} XP',
                  badge: challengeState.hasParticipated ? 'KATILDIN' : null,
                  badgeColor: Colors.green,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pushNamed(AppRoutes.createPost);
                    Utils.showSnackBar(
                      text:
                          'Etikete #${challenge.tagName} ekleyerek katıl! ${challenge.themeEmoji}',
                      isError: false,
                    );
                  },
                ),
              _buildActionCard(
                context: context,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                ),
                icon: const Icon(Icons.circle, color: Colors.white, size: 22),
                title: 'Canlı Etkinlik',
                subtitle: 'Haftalık Soru-Cevap',
                footer: '156 kişi izliyor',
                badge: 'CANLI',
                badgeColor: Colors.red,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // TODO: Canlı etkinliğe katılma akışı buraya
                },
              ),
              _buildActionCard(
                context: context,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                icon: const Icon(
                  Icons.shuffle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                title: 'Rastgele Keşfet',
                subtitle: 'Şansını dene',
                footer: 'Yeni bir gönderi bul',
                onTap: () async {
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required Gradient gradient,
    required Widget icon,
    required String title,
    required String subtitle,
    required String footer,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 6),
            blurRadius: 16,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: icon,
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
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    footer,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Çok yakında!')));
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Çok yakında!')));
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
            color: Colors.black.withValues(alpha: 0.2),
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
                  child: CustomPaint(painter: _GameCardPatternPainter()),
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
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: Colors.white, size: 32),
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
                                        .withValues(alpha: 0.5),
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
                          color: Colors.white.withValues(alpha: 0.9),
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
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Oyna',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
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
            ],
          ),
        ),
        featuredAsync.when(
          data: (users) {
            if (users.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Henüz öne çıkan kullanıcı yok')),
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
        border: Border.all(color: gradient[0].withValues(alpha: 0.4), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            NavigationService.toNamed(AppRoutes.profile, arguments: user.id);
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
                    vertical: 4, // 6'dan 4'e
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.5),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
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

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
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
    final feelsState = ref.watch(feelsProvider);
    final theme = Theme.of(context);
    final position = feelsState.leaderboardPosition;
    final weeklyPoints = feelsState.leaderboardWeeklyPoints ?? feelsState.weeklyPoints;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardPage()),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liderlik Tablosu',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      position != null
                          ? 'Bu hafta $weeklyPoints puanla #$position. sıradasın'
                          : 'Bu hafta henüz puan kazanmadın',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
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
                  const Icon(Icons.analytics, color: AppColors.primary, size: 24),
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
                    NavigationService.toNamed(AppRoutes.profile, arguments: currentUser.id);
                  }
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Profilim'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  context: context,
                  icon: Icons.photo_library,
                  accentColor: const Color(0xFF667eea),
                  value: userStats['posts']?.toString() ?? '0',
                  label: 'Gönderi',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  context: context,
                  icon: Icons.favorite,
                  accentColor: const Color(0xFFFF6B6B),
                  value: userStats['likes']?.toString() ?? '0',
                  label: 'Beğeni',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  context: context,
                  icon: Icons.people,
                  accentColor: const Color(0xFF4FACFE),
                  value: userStats['followers']?.toString() ?? '0',
                  label: 'Takipçi',
                  onTap: () {
                    if (currentUser != null) {
                      NavigationService.toNamed(
                        AppRoutes.followList,
                        arguments: {'userId': currentUser.id, 'initialTabIndex': 0},
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  context: context,
                  icon: Icons.person_add,
                  accentColor: const Color(0xFFB06AB3),
                  value: userStats['following']?.toString() ?? '0',
                  label: 'Takip',
                  onTap: () {
                    if (currentUser != null) {
                      NavigationService.toNamed(
                        AppRoutes.followList,
                        arguments: {'userId': currentUser.id, 'initialTabIndex': 1},
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
                  const Icon(
                    Icons.trending_up,
                    color: AppColors.primary,
                    size: 26,
                  ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: AppColors.primary,
                    ),
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
    final opacity = (0.18 - (index * 0.012)).clamp(0.06, 0.18);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            NavigationService.toNamed(AppRoutes.tagPosts, arguments: {'tag': tag});
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$tag',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.primary,
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
      ..color = Colors.white.withValues(alpha: 0.1)
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
