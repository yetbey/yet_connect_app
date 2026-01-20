// lib/features/chat/presentation/widgets/new_chat_sheet.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';

class NewChatSheet extends ConsumerStatefulWidget {
  const NewChatSheet({super.key});

  @override
  ConsumerState<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends ConsumerState<NewChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredFollowers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = ref.read(userProvider).currentUser?.id;
      if (currentUserId != null) {
        // ✅ Takipçilerinizi yükleyin (user_provider'dan)
        final followers = await ref
            .read(userProvider.notifier)
            .getFollowingList(currentUserId);

        if (mounted) {
          setState(() {
            _filteredFollowers = followers;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterFollowers(String query) {
    final currentUserId = ref.read(userProvider).currentUser?.id;
    if (currentUserId == null) return;

    setState(() {
      if (query.isEmpty) {
        _loadFollowers();
      } else {
        _filteredFollowers = _filteredFollowers.where((user) {
          final username = user.userName.toLowerCase();
          final fullName = user.fullName.toLowerCase();
          final searchQuery = query.toLowerCase();
          return username.contains(searchQuery) ||
              fullName.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _startChat(UserModel user) async {
    // ✅ Loading göster
    NavigationService.showLoadingDialog(message: 'Sohbet açılıyor...');

    try {
      // ✅ Chat başlat
      final chatId = await ref
          .read(chatListProvider.notifier)
          .startChat(user.id);

      // ✅ Loading kapat
      NavigationService.hideLoadingDialog();

      if (chatId != null && mounted) {
        // ✅ ÖNCE chat listesini yenile
        await ref.read(chatListProvider.notifier).fetchChats();

        // ✅ Sheet'i kapat
        if (mounted) {
          Navigator.of(context).pop();
        }

        // ✅ Kısa gecikme sonra chat detail'e git
        await Future.delayed(const Duration(milliseconds: 200));

        // ✅ Chat detail'e git
        NavigationService.toNamed(
          AppRoutes.chatDetail,
          arguments: {'chatId': chatId, 'otherUser': user},
        );
      }
    } catch (e) {
      NavigationService.hideLoadingDialog();
      NavigationService.showSnackbar('Sohbet başlatılamadı: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ✅ Header
          _buildHeader(theme, colorScheme),

          // ✅ Search Bar
          _buildSearchBar(theme, colorScheme),

          const Divider(height: 1),

          // ✅ Followers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFollowers.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildFollowersList(),
          ),
        ],
      ),
    );
  }

  // ✅ Header
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: Text(
                  'Yeni Mesaj',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance for close button
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Search Bar
  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: _filterFollowers,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Takipçi ara...',
          prefixIcon: const Icon(IconsaxPlusLinear.search_normal),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterFollowers('');
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ✅ Followers List
  Widget _buildFollowersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredFollowers.length,
      itemBuilder: (context, index) {
        final follower = _filteredFollowers[index];
        return _buildFollowerTile(follower);
      },
    );
  }

  // ✅ Follower Tile
  Widget _buildFollowerTile(UserModel user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: user.profileImageUrl != null
            ? CachedNetworkImageProvider(user.profileImageUrl!)
            : null,
        backgroundColor: colorScheme.primaryContainer,
        child: user.profileImageUrl == null
            ? Icon(Icons.person, color: colorScheme.onPrimaryContainer)
            : null,
      ),
      title: Text(
        user.fullName,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '@${user.userName}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(IconsaxPlusLinear.message, color: colorScheme.primary),
      onTap: () => _startChat(user),
    );
  }

  // ✅ Empty State
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconsaxPlusBold.user_search,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Henüz takipçin yok'
                : 'Kullanıcı bulunamadı',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Kullanıcıları takip etmeye başla'
                : 'Başka bir isim dene',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
