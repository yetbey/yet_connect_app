import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/core/utils/analytics_helper.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/features/feed/data/post_repository.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

// ============================================================================
// FEED STATE
// ============================================================================

/// Represents the state of the main feed with pagination and filter support.
///
/// This state object manages:
/// - List of posts currently loaded in the feed
/// - Loading state for UI feedback
/// - Pagination status (whether more posts are available)
/// - Filter state (all posts vs following-only)
class FeedState {
  /// List of posts currently displayed in the feed
  final List<PostModel> posts;

  /// Indicates whether posts are currently being fetched
  final bool isLoading;

  /// Indicates whether more posts are available for pagination
  final bool hasMore;

  /// Filter flag: true = following-only, false = all posts
  final bool isFollowingOnly;

  const FeedState({
    required this.posts,
    this.isLoading = false,
    this.hasMore = true,
    this.isFollowingOnly = false,
  });

  /// Creates a copy of this state with the given fields replaced
  FeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? hasMore,
    bool? isFollowingOnly,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isFollowingOnly: isFollowingOnly ?? this.isFollowingOnly,
    );
  }
}

// ============================================================================
// FEED NOTIFIER
// ============================================================================

/// Manages the main feed state with pagination and filtering capabilities.
///
/// Features:
/// - Infinite scroll pagination
/// - Pull-to-refresh support
/// - Filter between all posts and following-only posts
/// - Optimistic UI updates for better UX
/// - Comprehensive error handling and logging
class FeedNotifier extends Notifier<FeedState> {
  late final PostRepository _repository = ref.read(postRepositoryProvider);

  /// Number of posts to fetch per page
  static const int _limit = 10;

  @override
  FeedState build() {
    return const FeedState(posts: []);
  }

  /// Fetches posts from the repository with pagination support.
  ///
  /// Parameters:
  /// - [isRefresh]: If true, clears existing posts and starts fresh
  /// - [onlyFollowing]: Filter to show only followed users' posts
  /// - [onlyVideos]: Filter to show only video posts (currently unused)
  ///
  /// Behavior:
  /// - Prevents duplicate requests when already loading (unless refreshing)
  /// - Automatically enables refresh when filter changes
  /// - Supports infinite scroll by appending to existing posts
  /// - Updates hasMore flag based on returned post count
  Future<void> fetchPosts({
    bool isRefresh = false,
    bool? onlyFollowing,
    bool onlyVideos = false,
  }) async {
    final targetFilter = onlyFollowing ?? state.isFollowingOnly;

    // Force refresh when filter changes to prevent stale data
    if (targetFilter != state.isFollowingOnly) {
      isRefresh = true;
    }

    // Prevent duplicate requests (unless refreshing)
    if (state.isLoading && !isRefresh) return;

    // Reset state when refreshing
    if (isRefresh) {
      state = FeedState(
        posts: const [],
        isLoading: true,
        isFollowingOnly: targetFilter,
      );
    } else {
      // Stop pagination if no more posts available
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true);
    }

    // Log fetch operation for debugging
    ErrorHandler.log(
      'Fetching posts',
      data: {
        'isRefresh': isRefresh,
        'onlyFollowing': targetFilter,
        'currentPostCount': state.posts.length,
      },
    );

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final start = state.posts.length;
      final end = start + _limit - 1;

      final newPosts = await _repository.fetchFeed(
        start: start,
        end: end,
        onlyFollowing: targetFilter,
        currentUserId: currentUserId,
      );

      ErrorHandler.log(
        'Posts fetched successfully',
        data: {'count': newPosts.length, 'hasMore': newPosts.length >= _limit},
      );

      // Update state with new posts
      state = state.copyWith(
        posts: isRefresh ? newPosts : [...state.posts, ...newPosts],
        isLoading: false,
        hasMore: newPosts.length >= _limit,
      );
    } catch (e, stackTrace) {
      // Log error with context for troubleshooting
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Fetch Posts',
        severity: ErrorSeverity.medium,
        userAction: 'Loading feed',
        metadata: {
          'isRefresh': isRefresh,
          'onlyFollowing': targetFilter,
          'postCount': state.posts.length,
        },
      );

      Utils.showSnackBar(text: ErrorHandler.getErrorMessage(e), isError: true);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Removes a post from the feed (typically after deletion).
  ///
  /// This is used for optimistic UI updates when a post is deleted.
  void removePost(String postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
  }

  /// Adds a new post to the beginning of the feed.
  ///
  /// Used when a user creates a new post to show it immediately.
  void prependPost(PostModel post) {
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  /// Updates a specific post in the feed with new data.
  ///
  /// Commonly used for:
  /// - Like/unlike optimistic updates
  /// - Comment count updates
  /// - Post edit updates
  void updatePostInList(PostModel updatedPost) {
    final index = state.posts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      final newPosts = List<PostModel>.from(state.posts);
      newPosts[index] = updatedPost;
      state = state.copyWith(posts: newPosts);
    }
  }
}

/// Global provider for the main feed
final feedProvider = NotifierProvider<FeedNotifier, FeedState>(() {
  return FeedNotifier();
});

// ============================================================================
// PROFILE POSTS PROVIDER
// ============================================================================

/// Manages posts for a specific user profile.
///
/// This is a family provider that creates separate state for each user ID.
/// Auto-disposes when no longer needed to save memory.
class ProfilePostsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<PostModel>, String> {
  @override
  Future<List<PostModel>> build(String userId) async {
    ErrorHandler.log('Fetching user posts', data: {'userId': userId});

    try {
      final repository = ref.read(postRepositoryProvider);
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      return await repository.fetchUserPosts(userId, currentUserId);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Fetch User Posts',
        severity: ErrorSeverity.medium,
        metadata: {'userId': userId},
      );
      rethrow;
    }
  }

  /// Removes a post from the user's profile posts
  void removePost(String postId) {
    state.whenData((posts) {
      state = AsyncData(posts.where((p) => p.id != postId).toList());
    });
  }
}

/// Provider for fetching posts of a specific user
final profilePostsProvider = AsyncNotifierProvider.autoDispose
    .family<ProfilePostsNotifier, List<PostModel>, String>(() {
  return ProfilePostsNotifier();
});

// ============================================================================
// POST ACTIONS NOTIFIER
// ============================================================================

/// Handles all post-related actions (create, update, delete, like).
///
/// State represents loading status (true = action in progress).
/// This prevents duplicate actions and provides UI feedback.
class PostActionsNotifier extends Notifier<bool> {
  late final PostRepository _repository = ref.read(postRepositoryProvider);

  @override
  bool build() => false;

  // ==========================================================================
  // CREATE POST
  // ==========================================================================

  /// Creates a new post with optional media and tags.
  ///
  /// Validation:
  /// - At least one of caption, image, or video must be provided
  /// - User must be authenticated
  ///
  /// Features:
  /// - Uploads media files to storage
  /// - Adds post to database
  /// - Updates feed with new post (optimistic)
  /// - Logs analytics event
  /// - Shows success/error feedback
  ///
  /// Returns true if successful, false otherwise
  Future<bool> createPost(
      String caption, {
        File? imageFile,
        File? videoFile,
        Alignment alignment = Alignment.center,
        List<String>? tags,
      }) async {
    // Validate input
    if (caption.isEmpty && imageFile == null && videoFile == null) {
      Utils.showSnackBar(text: LocaleKeys.infos_add_some_content.tr(), isError: true);
      return false;
    }

    state = true;

    ErrorHandler.log(
      'Creating post',
      data: {
        'hasCaption': caption.isNotEmpty,
        'hasImage': imageFile != null,
        'hasVideo': videoFile != null,
        'tagCount': tags?.length ?? 0,
      },
    );

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      final newPost = await _repository.createPost(
        caption: caption,
        userId: userId,
        imageFile: imageFile,
        videoFile: videoFile,
        alignment: alignment,
        tags: tags,
      );

      // Optimistically add to feed
      ref.read(feedProvider.notifier).prependPost(newPost);

      ErrorHandler.log(
        'Post created successfully',
        data: {'postId': newPost.id},
      );

      // Determine content type for analytics
      String contentType = 'text';
      if (imageFile != null) contentType = 'image';
      if (videoFile != null) contentType = 'video';

      await AnalyticsHelper.logPostCreated(
        postId: newPost.id,
        contentType: contentType,
        tagCount: tags?.length,
      );

      Utils.showSnackBar(text: LocaleKeys.feed_post_shared.tr(), isError: false);
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Create Post',
        severity: ErrorSeverity.high,
        userAction: 'Creating new post',
        metadata: {
          'hasImage': imageFile != null,
          'hasVideo': videoFile != null,
          'captionLength': caption.length,
          'tagCount': tags?.length ?? 0,
        },
      );

      Utils.showSnackBar(text: ErrorHandler.getErrorMessage(e), isError: true);
      return false;
    } finally {
      state = false;
    }
  }

  // ==========================================================================
  // UPDATE POST
  // ==========================================================================

  /// Updates an existing post's caption and/or tags.
  ///
  /// Note: Media files cannot be changed after post creation.
  ///
  /// Side effects:
  /// - Refreshes main feed
  /// - Invalidates user profile posts cache
  /// - Shows success/error feedback
  ///
  /// Returns true if successful, false otherwise
  Future<bool> updatePost({
    required String postId,
    String? caption,
    List<String>? tags,
  }) async {
    state = true;

    ErrorHandler.log(
      'Updating post',
      data: {
        'postId': postId,
        'hasCaption': caption != null,
        'tagCount': tags?.length ?? 0,
      },
    );

    try {
      await _repository.updatePost(
        postId: postId,
        caption: caption,
        tags: tags,
      );

      // Refresh feed to show updated post
      ref.read(feedProvider.notifier).fetchPosts(isRefresh: true);

      // Invalidate profile cache if this is user's own post
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null) {
        ref.invalidate(profilePostsProvider(currentUserId));
      }

      ErrorHandler.log('Post updated successfully');
      Utils.showSnackBar(text: LocaleKeys.feed_post_updated.tr(), isError: false);
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Update Post',
        severity: ErrorSeverity.medium,
        userAction: 'Updating post',
        metadata: {'postId': postId},
      );

      Utils.showSnackBar(text: ErrorHandler.getErrorMessage(e), isError: true);
      return false;
    } finally {
      state = false;
    }
  }

  // ==========================================================================
  // DELETE POST
  // ==========================================================================

  /// Permanently deletes a post and its associated media files.
  ///
  /// Process:
  /// 1. Deletes post from database (cascades to likes/comments)
  /// 2. Deletes associated media files from storage
  /// 3. Removes from feed state
  /// 4. Invalidates profile posts cache
  /// 5. Logs analytics event
  /// 6. Navigates back to previous screen
  ///
  /// Note: This operation cannot be undone
  Future<void> deletePost(String postId) async {
    ErrorHandler.log('Deleting post', data: {'postId': postId});

    try {
      LogService.i('🗑️ Post deletion started: $postId');

      await _repository.deletePost(postId);
      LogService.i('✅ Repository deletion completed');

      await AnalyticsHelper.logPostDeleted(postId);

      // Remove from feed
      ref.read(feedProvider.notifier).removePost(postId);

      // Invalidate all profile post caches
      ref.invalidate(profilePostsProvider);

      LogService.i('✅ Provider state updated');

      ErrorHandler.log('Post deleted successfully');
      Utils.showSnackBar(text: LocaleKeys.feed_post_deleted.tr(), isError: false);
      NavigationService.back();
    } catch (e, stackTrace) {
      LogService.e('❌ Post deletion error: $postId', e);
      LogService.e('Stack trace:', stackTrace);

      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Delete Post',
        severity: ErrorSeverity.high,
        userAction: 'Deleting post',
        metadata: {'postId': postId},
      );

      Utils.showSnackBar(text: ErrorHandler.getErrorMessage(e), isError: true);
    }
  }

  // ==========================================================================
  // TOGGLE LIKE
  // ==========================================================================

  /// Toggles like status for a post with optimistic UI update.
  ///
  /// Implementation details:
  /// - Immediately updates UI (optimistic update)
  /// - Makes backend call to persist change
  /// - Updates with actual backend values on success
  /// - Rolls back on failure
  /// - Logs analytics event for new likes
  ///
  /// This approach provides instant feedback while maintaining data consistency.
  Future<void> toggleLike(PostModel post) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final wasLiked = post.isLikedByCurrentUser;
    final oldLikes = post.likes;

    // Optimistic update for instant UI feedback
    final updatedPost = post.copyWith(
      isLikedByCurrentUser: !wasLiked,
      likes: wasLiked ? oldLikes - 1 : oldLikes + 1,
    );
    ref.read(feedProvider.notifier).updatePostInList(updatedPost);

    ErrorHandler.log(
      'Toggling like',
      data: {'postId': post.id, 'newState': !wasLiked},
    );

    try {
      // Get actual like count from backend
      final result = await _repository.toggleLike(post.id, userId);

      // Update with backend values to ensure consistency
      final finalPost = post.copyWith(
        isLikedByCurrentUser: result['is_liked'] as bool,
        likes: result['like_count'] as int,
      );
      ref.read(feedProvider.notifier).updatePostInList(finalPost);

      // Log analytics only for new likes
      if (result['is_liked'] as bool) {
        await AnalyticsHelper.logPostLiked(post.id);
      }
    } catch (e, stackTrace) {
      // Rollback optimistic update on error
      ref.read(feedProvider.notifier).updatePostInList(post);

      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Toggle Like',
        severity: ErrorSeverity.low,
        userAction: wasLiked ? 'Unliking post' : 'Liking post',
        metadata: {'postId': post.id},
      );

      Utils.showSnackBar(text: LocaleKeys.feed_no_likes_yet.tr(), isError: true);
    }
  }

  // ==========================================================================
  // GET POST LIKES
  // ==========================================================================

  /// Fetches the list of users who liked a specific post.
  ///
  /// Returns list of user profile data.
  /// Throws exception on error (caller should handle).
  Future<List<Map<String, dynamic>>> getPostLikeUsers(String postId) async {
    try {
      return await _repository.getLikes(postId);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Fetch Post Likes',
        severity: ErrorSeverity.low,
        metadata: {'postId': postId},
      );
      rethrow;
    }
  }
}

/// Global provider for post actions
final postActionsProvider = NotifierProvider<PostActionsNotifier, bool>(() {
  return PostActionsNotifier();
});

// ============================================================================
// TAG PROVIDERS
// ============================================================================

/// Provider that fetches tags followed by the current user.
///
/// Used to display followed tags in category navigation.
final followedTagsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final repository = ref.watch(postRepositoryProvider);
    return await repository.getFollowedTags();
  } catch (e, stackTrace) {
    ErrorHandler.logError(
      e,
      stackTrace: stackTrace,
      context: 'Fetch Followed Tags',
      severity: ErrorSeverity.low,
    );
    rethrow;
  }
});

/// Provider that fetches trending/popular tags.
///
/// Returns tags sorted by post count (most popular first).
/// Limited to top 20 tags.
final popularTagsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final repository = ref.watch(postRepositoryProvider);
    return await repository.getPopularTags(limit: 20);
  } catch (e, stackTrace) {
    ErrorHandler.logError(
      e,
      stackTrace: stackTrace,
      context: 'Fetch Popular Tags',
      severity: ErrorSeverity.low,
    );
    rethrow;
  }
});

/// Family provider that fetches posts for a specific tag.
///
/// Transforms raw JSON data into PostModel objects with like status.
final postsByTagProvider =
FutureProvider.family<List<PostModel>, String>((ref, tag) async {
  ErrorHandler.log('Fetching posts by tag', data: {'tag': tag});

  try {
    final repository = ref.watch(postRepositoryProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final response = await repository.getPostsByTag(tag);

    // Transform JSON to PostModel with like status
    return response.map((json) {
      final myLikes = json['my_likes'] as List? ?? [];
      final isLiked = myLikes.any((like) => like['user_id'] == currentUserId);

      // Modify JSON to match PostModel.fromJson expectations
      final modifiedJson = Map<String, dynamic>.from(json);
      modifiedJson['my_likes'] = isLiked ? [{}] : [];

      return PostModel.fromJson(modifiedJson);
    }).toList();
  } catch (e, stackTrace) {
    ErrorHandler.logError(
      e,
      stackTrace: stackTrace,
      context: 'Fetch Posts By Tag',
      severity: ErrorSeverity.medium,
      metadata: {'tag': tag},
    );
    rethrow;
  }
});

// ============================================================================
// TAG FOLLOW NOTIFIER
// ============================================================================

/// Manages tag follow/unfollow state for the current user.
///
/// Maintains a set of followed tag names and provides methods to:
/// - Toggle follow status
/// - Check if a tag is followed
/// - Reload followed tags
class TagFollowNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  final PostRepository _repository;

  TagFollowNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadFollowedTags();
  }

  /// Loads followed tags from repository
  Future<void> _loadFollowedTags() async {
    try {
      final tags = await _repository.getFollowedTags();
      state = AsyncValue.data(tags.toSet());
    } catch (e, stack) {
      ErrorHandler.logError(
        e,
        stackTrace: stack,
        context: 'Load Followed Tags',
        severity: ErrorSeverity.low,
      );
      state = AsyncValue.error(e, stack);
    }
  }

  /// Toggles follow status for a tag.
  ///
  /// Optimistically updates state, then syncs with backend.
  /// Reloads on error to ensure consistency.
  Future<void> toggleFollow(String tagName) async {
    final currentTags = state.value ?? {};
    final isFollowing = currentTags.contains(tagName);

    ErrorHandler.log(
      'Toggling tag follow',
      data: {'tag': tagName, 'newState': !isFollowing},
    );

    try {
      if (isFollowing) {
        await _repository.unfollowTag(tagName);
        state = AsyncValue.data(currentTags..remove(tagName));
      } else {
        await _repository.followTag(tagName);
        state = AsyncValue.data(currentTags..add(tagName));
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Toggle Tag Follow',
        severity: ErrorSeverity.medium,
        userAction: isFollowing ? 'Unfollowing tag' : 'Following tag',
        metadata: {'tag': tagName},
      );

      // Reload to sync with backend on error
      await _loadFollowedTags();
    }
  }

  /// Checks if a tag is currently followed by the user
  bool isFollowing(String tagName) {
    return state.value?.contains(tagName) ?? false;
  }
}

/// Provider for tag follow state management
final tagFollowProvider =
StateNotifierProvider<TagFollowNotifier, AsyncValue<Set<String>>>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return TagFollowNotifier(repository);
});

/// Family provider for searching tags by query string.
///
/// Returns empty list for empty queries.
/// Results are sorted by popularity (post count).
final tagSearchProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];

  try {
    final repository = ref.watch(postRepositoryProvider);
    return await repository.searchTags(query);
  } catch (e, stackTrace) {
    ErrorHandler.logError(
      e,
      stackTrace: stackTrace,
      context: 'Search Tags',
      severity: ErrorSeverity.low,
      metadata: {'query': query},
    );
    rethrow;
  }
});
