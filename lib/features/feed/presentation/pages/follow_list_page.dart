import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowerListPage extends ConsumerStatefulWidget {
  final String userId;
  final int initialTabIndex;

  const FollowerListPage({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<FollowerListPage> createState() => _FollowerListPageState();
}

class _FollowerListPageState extends ConsumerState<FollowerListPage> {
  // ✅ Provider'lardan veri alacağız, setState kullanmayacağız
  final _followersKey = GlobalKey(); // ✅ Widget key'leri ekle
  final _followingKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMyProfile = currentUserId == widget.userId;

    final tabs = ['Takipçi', 'Takip Edilen', 'Etiketler'];

    return DefaultTabController(
      initialIndex: widget.initialTabIndex,
      length: tabs.length,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) {
            FocusScope.of(context).unfocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Takip Listesi'),
            bottom: TabBar(
              tabs: [
                Tab(text: tabs[0]),
                Tab(text: tabs[1]),
                Tab(text: tabs[2]),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // TAB 1: Takipçi Listesi
              _buildFollowersTab(key: _followersKey),

              // TAB 2: Takip Edilen Listesi
              _buildFollowingTab(isMyProfile, key: _followingKey),

              // TAB 3: Etiketler Listesi
              _buildTagsTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Takipçiler tab'ı
  Widget _buildFollowersTab({Key? key}) {
    final userNotifier = ref.read(userProvider.notifier);

    return FutureBuilder<List<UserModel>>(
      key: key,
      future: userNotifier.getFollowersList(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return _buildEmptyState('Henüz takipçi yok', Icons.people_outline);
        }

        return _buildUserList(users, showUnfollowButton: false);
      },
    );
  }

  // ✅ Takip edilenler tab'ı
  Widget _buildFollowingTab(bool isMyProfile, {Key? key}) {
    final userNotifier = ref.read(userProvider.notifier);

    return FutureBuilder<List<UserModel>>(
      key: key,
      future: userNotifier.getFollowingList(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return _buildEmptyState(
            'Henüz takip edilen yok',
            Icons.person_add_outlined,
          );
        }

        return _buildUserList(users, showUnfollowButton: isMyProfile);
      },
    );
  }

  // ✅ Kullanıcı listesi
  Widget _buildUserList(
    List<UserModel> users, {
    bool showUnfollowButton = false,
  }) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isMyself = user.id == currentUserId;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          onTap: () async {
            await NavigationService.toNamed(
              AppRoutes.profile,
              arguments: {'userId': user.id},
            );
            // ✅ setState yerine widget'ı rebuild et
            if (mounted) {
              // Key değiştirerek rebuild tetikle
              setState(() {
                _followersKey.currentState?.setState(() {});
                _followingKey.currentState?.setState(() {});
              });
            }
          },
          leading:
              user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    user.profileImageUrl!,
                    cacheManager: CustomImageCacheManager(),
                  ),
                  radius: 24,
                )
              : const CircleAvatar(radius: 24, child: Icon(Icons.person)),
          title: Text(
            user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('@${user.userName}'),
          trailing: showUnfollowButton && !isMyself
              ? OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(userProvider.notifier)
                        .toggleFollowUser(user.id);
                    // ✅ setState yerine provider'ı refresh et
                    if (mounted) {
                      // Widget'ı rebuild et
                      setState(() {});
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Takipten Çık'),
                )
              : null,
        );
      },
    );
  }

  // ✅ Etiketler tab'ı
  Widget _buildTagsTab() {
    final tagFollowState = ref.watch(tagFollowProvider);

    return tagFollowState.when(
      data: (tagsSet) {
        final tags = tagsSet.toList();
        if (tags.isEmpty) {
          return _buildEmptyState(
            'Henüz etiket takip etmiyorsunuz',
            Icons.label_off_outlined,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tags.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final tag = tags[index];
            return _buildTagItem(tag);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Hata: $error'),
          ],
        ),
      ),
    );
  }

  // ✅ Etiket item
  Widget _buildTagItem(String tag) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(Icons.tag, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(
        '#$tag',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      trailing: OutlinedButton(
        onPressed: () async {
          await ref.read(tagFollowProvider.notifier).toggleFollow(tag);
          // ✅ Provider watch ettiği için otomatik güncellenir, setState gereksiz
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: const Text('Takipten Çık'),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  // ✅ Boş durum widget'ı
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
}
