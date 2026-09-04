import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/core/services/storage_service.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Geri butonu kaldırıldı
        title: const Text(
          'Arama',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildModernSearchBar(theme, colorScheme),
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildDefaultView(theme, colorScheme)
                : _buildSearchResults(theme, colorScheme),
          ),
        ],
      ),
    );
  }

  // Modern Search Bar with Glassmorphism (autofocus: false)
  Widget _buildModernSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false, // ← Otomatik klavye açılmasın
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Kullanıcı veya etiket ara...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(
                  IconsaxPlusLinear.search_normal_1,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
          ),
        ),
      ),
    );
  }

  // Default View (History)
  Widget _buildDefaultView(ThemeData theme, ColorScheme colorScheme) {
    final searchHistoryAsync = ref.watch(searchHistoryProvider);
    
    return searchHistoryAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return _buildEmptyState(
            icon: IconsaxPlusLinear.search_normal,
            title: 'Arama Yap',
            subtitle: 'Kullanıcı veya etiket arayın',
            colorScheme: colorScheme,
          );
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // History Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Son Aramalar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(searchHistoryProvider.notifier).clearAll();
                        },
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        label: Text(
                          'Temizle',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // History Items with Chips
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = history[index];
                      return _buildHistoryItem(item, theme, colorScheme);
                    },
                    childCount: history.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _buildEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Hata',
        subtitle: 'Geçmiş yüklenemedi',
        colorScheme: colorScheme,
      ),
    );
  }

  Widget _buildHistoryItem(SearchHistoryItem item, ThemeData theme, ColorScheme colorScheme) {
    final isUser = item.type == SearchType.user;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (isUser) {
                    NavigationService.toNamed(
                      AppRoutes.profile,
                      arguments: {'userId': item.id},
                    );
                  } else {
                    NavigationService.toNamed(
                      AppRoutes.tagPosts,
                      arguments: {'tag': item.name},
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Icon/Avatar
                      if (isUser)
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: item.imageUrl != null
                              ? CachedNetworkImageProvider(item.imageUrl!)
                              : null,
                          child: item.imageUrl == null
                              ? Icon(
                                  Icons.person_rounded,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 24,
                                )
                              : null,
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.3),
                                colorScheme.secondary.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                          child: Icon(
                            IconsaxPlusBold.hashtag,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                      
                      const SizedBox(width: 14),
                      
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUser ? item.name : '#${item.name}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref.read(searchHistoryProvider.notifier).removeItem(item.id);
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Search Results
  Widget _buildSearchResults(ThemeData theme, ColorScheme colorScheme) {
    final userAsync = ref.watch(searchUsersProvider(_searchQuery));
    final tagsAsync = ref.watch(tagSearchProvider(_searchQuery));

    return CustomScrollView(
      slivers: [
        // Users Section
        userAsync.when(
          data: (users) {
            if (users.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
            
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Kullanıcılar',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildUserCard(users[index], theme, colorScheme),
                        ],
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildUserCard(users[index], theme, colorScheme),
                    );
                  },
                  childCount: users.length,
                ),
              ),
            );
          },
          loading: () => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),

        // Tags Section
        tagsAsync.when(
          data: (tags) {
            if (tags.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
            
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(
                                  IconsaxPlusBold.hashtag,
                                  size: 20,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Etiketler',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.secondary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildTagCard(tags[index], theme, colorScheme),
                        ],
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildTagCard(tags[index], theme, colorScheme),
                    );
                  },
                  childCount: tags.length,
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildUserCard(UserModel user, ThemeData theme, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHigh.withValues(alpha: .6),
                colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(searchHistoryProvider.notifier).addUser(user);
                NavigationService.toNamed(
                  AppRoutes.profile,
                  arguments: {'userId': user.id},
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Hero(
                      tag: 'search_user_${user.id}',
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: user.profileImageUrl != null
                            ? CachedNetworkImageProvider(user.profileImageUrl!)
                            : null,
                        child: user.profileImageUrl == null
                            ? Text(
                                user.userName.isNotEmpty
                                    ? user.userName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName.isNotEmpty ? user.fullName : user.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.userName}',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagCard(dynamic tag, ThemeData theme, ColorScheme colorScheme) {
    final tagName = tag['name'] as String;
    final postCount = tag['post_count'] as int;
    final tagFollowState = ref.watch(tagFollowProvider);
    final isFollowing = tagFollowState.value?.contains(tagName) ?? false;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(searchHistoryProvider.notifier).addTag(tagName, postCount);
                NavigationService.toNamed(
                  AppRoutes.tagPosts,
                  arguments: {'tag': tagName},
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.secondary.withValues(alpha: 0.3),
                            colorScheme.tertiary.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      child: Icon(
                        IconsaxPlusBold.hashtag,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$tagName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$postCount gönderi',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(tagFollowProvider.notifier).toggleFollow(tagName);
                      },
                      icon: Icon(
                        isFollowing ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
                        color: isFollowing ? Colors.red : colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== SEARCH HISTORY MODELS =====
enum SearchType { user, tag }

class SearchHistoryItem {
  final String id;
  final String name;
  final SearchType type;
  final String? imageUrl;
  final String? subtitle;
  final DateTime timestamp;

  SearchHistoryItem({
    required this.id,
    required this.name,
    required this.type,
    this.imageUrl,
    this.subtitle,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'imageUrl': imageUrl,
        'subtitle': subtitle,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: SearchType.values.firstWhere((e) => e.name == json['type']),
      imageUrl: json['imageUrl'] as String?,
      subtitle: json['subtitle'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

// ===== SEARCH HISTORY PROVIDER =====
final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, AsyncValue<List<SearchHistoryItem>>>((ref) {
  return SearchHistoryNotifier(ref.read(storageServiceProvider));
});

class SearchHistoryNotifier extends StateNotifier<AsyncValue<List<SearchHistoryItem>>> {
  final StorageService _storage;
  static const String _historyKey = 'search_history_v2';
  static const int _maxHistoryCount = 20;

  SearchHistoryNotifier(this._storage) : super(const AsyncValue.loading()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final List? historyJson = await _storage.read(_historyKey);
      if (historyJson != null) {
        final items = historyJson
            .map((json) => SearchHistoryItem.fromJson(json as Map<String, dynamic>))
            .toList();
        items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        state = AsyncValue.data(items);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e) {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> addUser(UserModel user) async {
    final currentItems = state.value ?? [];
    final newItem = SearchHistoryItem(
      id: user.id,
      name: user.fullName.isNotEmpty ? user.fullName : user.userName,
      type: SearchType.user,
      imageUrl: user.profileImageUrl,
      subtitle: '@${user.userName}',
      timestamp: DateTime.now(),
    );
    await _addItem(newItem, currentItems);
  }

  Future<void> addTag(String tagName, int postCount) async {
    final currentItems = state.value ?? [];
    final newItem = SearchHistoryItem(
      id: tagName,
      name: tagName,
      type: SearchType.tag,
      subtitle: '$postCount gönderi',
      timestamp: DateTime.now(),
    );
    await _addItem(newItem, currentItems);
  }

  Future<void> _addItem(SearchHistoryItem newItem, List<SearchHistoryItem> currentItems) async {
    final updatedItems = currentItems.where((item) => item.id != newItem.id).toList();
    updatedItems.insert(0, newItem);
    
    if (updatedItems.length > _maxHistoryCount) {
      updatedItems.removeRange(_maxHistoryCount, updatedItems.length);
    }

    await _storage.write(_historyKey, updatedItems.map((item) => item.toJson()).toList());
    state = AsyncValue.data(updatedItems);
  }

  Future<void> removeItem(String id) async {
    final currentItems = state.value ?? [];
    final updatedItems = currentItems.where((item) => item.id != id).toList();
    await _storage.write(_historyKey, updatedItems.map((item) => item.toJson()).toList());
    state = AsyncValue.data(updatedItems);
  }

  Future<void> clearAll() async {
    await _storage.remove(_historyKey);
    state = const AsyncValue.data([]);
  }
}

// ===== EXISTING PROVIDERS (Keep your existing ones) =====
final searchUsersProvider = FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('id, username, full_name, profile_image_url, bio')
        .or('username.ilike.%$query%,full_name.ilike.%$query%')
        .limit(20);
    return (response as List).map((json) {
      return UserModel(
        id: json['id'] as String,
        userName: json['username'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        profileImageUrl: json['profile_image_url'] as String?,
        bio: json['bio'] as String?,
        email: '',
      );
    }).toList();
  } catch (e) {
    return [];
  }
});
