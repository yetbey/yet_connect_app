// lib/features/chat/presentation/pages/chat_list_page.dart

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/chat/data/chat_repository.dart';
import 'package:yet_x_app/features/chat/presentation/widgets/chat_tile.dart';
import 'package:yet_x_app/features/chat/presentation/widgets/new_chat_sheet.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/features/chat/data/models/chat_model.dart';
import 'package:yet_x_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/storage_service.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ChatModel> _filteredChats = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  bool _showSearchHistory = false;
  Timer? _debounce;

  static const _headerPadding = EdgeInsets.fromLTRB(20, 20, 20, 10);
  static const _searchPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
  static const _listPadding = EdgeInsets.only(top: 8, bottom: 80);
  static const _searchHistoryKey = 'cache_chat_search_history';
  static const _maxSearchHistoryCount = 5;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _loadSearchHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatListProvider.notifier).fetchChats();
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa her açıldığında chatleri yeniden yükle
    if (mounted) {
      Future.microtask(() {
        ref.read(chatListProvider.notifier).fetchChats();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      setState(() {
        _showSearchHistory = false;
      });
    }
  }

  Future<void> _loadSearchHistory() async {
    final storage = ref.read(storageServiceProvider);
    final List<dynamic>? history = await storage.read(_searchHistoryKey);
    if (history != null) {
      setState(() {
        _searchHistory = history.cast<String>();
      });
    }
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.isEmpty) return;
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > _maxSearchHistoryCount) {
        _searchHistory = _searchHistory.sublist(0, _maxSearchHistoryCount);
      }
    });
    await storage.write(_searchHistoryKey, _searchHistory);
  }

  Future<void> _clearSearchHistory() async {
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _searchHistory.clear();
    });
    await storage.remove(_searchHistoryKey);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _showSearchHistory = _searchHistory.isNotEmpty && _searchFocusNode.hasFocus;
        _filteredChats = [];
      });
      return;
    }

    _debounce = Timer(_debounceDuration, () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    final allChats = ref.read(chatListProvider);
    final lowerQuery = query.toLowerCase();

    setState(() {
      _isSearching = true;
      _showSearchHistory = false;
      _filteredChats = allChats.where((chat) {
        final userName = chat.otherUserName?.toLowerCase() ?? '';
        final lastMessage = chat.lastMessage?.toLowerCase() ?? '';
        return userName.contains(lowerQuery) || lastMessage.contains(lowerQuery);
      }).toList();

      _filteredChats.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime(2000);
        final bTime = b.lastMessageAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    });

    _saveSearchQuery(query);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
      _showSearchHistory = false;
      _filteredChats = [];
    });
  }

  void _searchFromHistory(String query) {
    _searchController.text = query;
    _searchFocusNode.unfocus();
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chatList = ref.watch(chatListProvider);
    final notifier = ref.read(chatListProvider.notifier);
    final sortedChatList = _sortChatsByTimestamp(chatList);
    final displayList = _isSearching ? _filteredChats : sortedChatList;

    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          if (_searchController.text.isEmpty) {
            setState(() {
              _showSearchHistory = false;
            });
          }
        }
      },
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) {
            FocusScope.of(context).unfocus();
          }
        },
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, colorScheme),
                _buildSearchBar(theme, colorScheme),
                Expanded(
                  child: _showSearchHistory
                      ? _buildSearchHistory(theme, colorScheme)
                      : displayList.isEmpty
                          ? _buildEmptyState(colorScheme, chatList.isEmpty)
                          : RefreshIndicator(
                              onRefresh: () => notifier.fetchChats(),
                              color: colorScheme.primary,
                              backgroundColor: colorScheme.surface,
                              strokeWidth: 3.0,
                              displacement: 60,
                              child: ListView.builder(
                                padding: _listPadding,
                                itemCount: displayList.length,
                                cacheExtent: 800,
                                addRepaintBoundaries: true,
                                addAutomaticKeepAlives: false,
                                itemBuilder: (context, index) {
                                  final chat = displayList[index];
                                  return RepaintBoundary(
                                    child: ChatTile(
                                      key: ValueKey(chat.id),
                                      chat: chat,
                                      onTap: () {
                                        _searchFocusNode.unfocus();
                                        _navigateToChatDetail(chat);
                                      },
                                      searchQuery: _searchController.text,
                                      onDelete: (deleteForBoth) async {
                                        final myId = ref.read(userProvider).currentUser?.id;
                                        if (myId == null) return;

                                        try {
                                          if (deleteForBoth) {
                                            await ref.read(chatRepositoryProvider).deleteChatForBoth(chat.id);
                                          } else {
                                            await ref.read(chatRepositoryProvider).deleteChatForMe(chat.id, myId);
                                          }

                                          await ref.read(chatListProvider.notifier).fetchChats();

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(LocaleKeys.chat_delete_success.tr()),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(LocaleKeys.chat_delete_error.tr()),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  );
                                },
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

  List<ChatModel> _sortChatsByTimestamp(List<ChatModel> chats) {
    final sortedList = List<ChatModel>.from(chats);
    sortedList.sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime(2000);
      final bTime = b.lastMessageAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return sortedList;
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: _headerPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            LocaleKeys.chat_messages.tr(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useSafeArea: true,
                builder: (context) => const NewChatSheet(),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                IconsaxPlusBold.edit,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: _searchPadding,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(_searchFocusNode.hasFocus ? 24 : 16),
          border: Border.all(
            color: _searchFocusNode.hasFocus
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.1),
            width: _searchFocusNode.hasFocus ? 2 : 1,
          ),
          boxShadow: _searchFocusNode.hasFocus
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: theme.textTheme.titleMedium!.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: LocaleKeys.chat_search_chats.tr(),
            hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(128)),
            prefixIcon: Icon(
              IconsaxPlusLinear.search_normal,
              color: colorScheme.onSurfaceVariant,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onTap: () {
            if (_searchController.text.isEmpty && _searchHistory.isNotEmpty) {
              setState(() {
                _showSearchHistory = true;
              });
            }
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _searchFocusNode.unfocus();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchHistory(ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocaleKeys.chat_search_history.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _clearSearchHistory();
                    _searchFocusNode.unfocus();
                    setState(() {
                      _showSearchHistory = false;
                    });
                  },
                  child: Text(
                    LocaleKeys.common_clear.tr(),
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final query = _searchHistory[index];
                return ListTile(
                  leading: Icon(
                    IconsaxPlusLinear.clock,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(query),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.arrow_outward,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _searchFromHistory(query),
                  ),
                  onTap: () => _searchFromHistory(query),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isInitialEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching
                ? IconsaxPlusBold.search_status
                : IconsaxPlusBold.message_question,
            size: 60,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching
                ? LocaleKeys.chat_no_results.tr()
                : LocaleKeys.chat_no_chats.tr(),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isSearching) ...[
            const SizedBox(height: 8),
            Text(
              LocaleKeys.chat_try_different_keyword.tr(),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToChatDetail(ChatModel chat) {
    final otherUser = UserModel(
      id: chat.otherUserId ?? '',
      userName: chat.otherUserName ?? LocaleKeys.auth_user.tr(),
      fullName: chat.otherUserName ?? LocaleKeys.auth_user.tr(),
      email: '',
      profileImageUrl: chat.otherUserImage,
    );

    NavigationService.toNamed(
      AppRoutes.chatDetail,
      arguments: {'chatId': chat.id, 'otherUser': otherUser},
    );
  }
}
