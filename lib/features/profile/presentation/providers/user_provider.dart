import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/analytics_helper.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/features/profile/data/user_repository.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:yet_x_app/core/services/storage_service.dart';

class UserState {
  final UserModel? currentUser;
  final bool isLoading;
  final bool isFollowingLoading;
  final List<UserModel> recentSearches;

  UserState({
    this.currentUser,
    this.isLoading = false,
    this.isFollowingLoading = false,
    this.recentSearches = const [],
  });

  UserState copyWith({
    UserModel? currentUser,
    bool? isLoading,
    bool? isFollowingLoading,
    List<UserModel>? recentSearches,
  }) {
    return UserState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      isFollowingLoading: isFollowingLoading ?? this.isFollowingLoading,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  late final UserRepository _repository = ref.read(userRepositoryProvider);
  late final StorageService _storage;
  final _supabase = Supabase.instance.client;

  @override
  UserState build() {
    _storage = ref.read(storageServiceProvider);
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _loadLocalUser(userId);
      _loadRecentSearches(userId);
    }
    return UserState();
  }

  Future<void> _loadLocalUser(String userId) async {
    try {
      final localUser = await _repository.getLocalProfile(userId);
      if (localUser != null) {
        state = state.copyWith(currentUser: localUser, isLoading: false);
      }
      fetchMyProfile();
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Load Local User',
        severity: ErrorSeverity.low,
        metadata: {'userId': userId},
      );
    }
  }

  String _getStorageKey(String userId) => 'cache_recent_searches_$userId';

  Future<void> _loadRecentSearches(String userId) async {
    try {
      final List<dynamic>? stored = await _storage.read(_getStorageKey(userId));
      if (stored != null && stored.isNotEmpty) {
        final searches = stored
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(recentSearches: searches);
      }
    } catch (e) {
      // Sessizce geç, critical değil
    }
  }

  Future<void> addRecentSearch(UserModel user) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final current = List<UserModel>.from(state.recentSearches);
    current.removeWhere((u) => u.id == user.id);
    current.insert(0, user);
    if (current.length > 10) current.removeLast();

    state = state.copyWith(recentSearches: current);
    await _storage.write(
      _getStorageKey(userId),
      current.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> removeRecentSearch(String targetUserId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final current = List<UserModel>.from(state.recentSearches);
    current.removeWhere((u) => u.id == targetUserId);
    state = state.copyWith(recentSearches: current);

    await _storage.write(
      _getStorageKey(userId),
      current.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> clearRecentSearches() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(recentSearches: []);
    await _storage.remove(_getStorageKey(userId));
  }

  // --- VERİTABANI İŞLEMLERİ ---

  void setUser(UserModel user) {
    state = state.copyWith(currentUser: user);
  }

  void clearUserData() {
    state = UserState();
  }

  Future<void> fetchMyProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (state.currentUser == null) {
      state = state.copyWith(isLoading: true);
    }

    ErrorHandler.log('Fetching user profile', data: {'userId': userId});

    try {
      final user = await _repository.fetchProfile(userId);
      state = state.copyWith(currentUser: user, isLoading: false);
      ErrorHandler.log('User profile fetched successfully');
    } catch (e, stackTrace) {
      // ✅ Log error
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Fetch User Profile',
        severity: ErrorSeverity.medium,
        userAction: 'Loading profile',
        metadata: {'userId': userId},
      );

      if (state.currentUser == null) {
        Utils.showSnackBar(
          text: ErrorHandler.getErrorMessage(e),
          isError: true,
        );
      }
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateUserProfile({String? fullName, String? bio}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true);

    ErrorHandler.log('Updating user profile', data: {
      'userId': userId,
      'hasFullName': fullName != null,
      'hasBio': bio != null,
    });

    try {
      await _repository.updateProfile(
        userId: userId,
        fullName: fullName,
        bio: bio,
      );
      await fetchMyProfile();

      ErrorHandler.log('Profile updated successfully');
      await AnalyticsHelper.logProfileUpdated();
      Utils.showSnackBar(text: 'profile_updated'.tr(), isError: false);
    } catch (e, stackTrace) {
      // ✅ Log error
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Update Profile',
        severity: ErrorSeverity.medium,
        userAction: 'Updating profile info',
        metadata: {'userId': userId},
      );

      Utils.showSnackBar(text: ErrorHandler.getErrorMessage(e), isError: true);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateProfileImage(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true);

    ErrorHandler.log('Updating profile image', data: {'userId': userId});

    try {
      await _repository.updateProfileImage(userId, imageFile);
      await fetchMyProfile();

      ErrorHandler.log('Profile image updated successfully');
      await AnalyticsHelper.logProfileImageUpdated();
      Utils.showSnackBar(text: 'profile_image_updated'.tr(), isError: false);
    } catch (e, stackTrace) {
      // ✅ Log error
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Update Profile Image',
        severity: ErrorSeverity.high,
        userAction: 'Uploading profile picture',
        metadata: {'userId': userId},
      );

      Utils.showSnackBar(text: 'image_not_load'.tr(), isError: true);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleFollowUser(String targetUserId) async {
    final currentUser = state.currentUser;
    if (currentUser == null) return;
    if (currentUser.id == targetUserId) return;

    // Optimistic Update
    final currentFollowing = List<String>.from(currentUser.following);
    final isAlreadyFollowing = currentFollowing.contains(targetUserId);

    if (isAlreadyFollowing) {
      currentFollowing.remove(targetUserId);
    } else {
      currentFollowing.add(targetUserId);
    }

    state = state.copyWith(
      currentUser: currentUser.copyWith(following: currentFollowing),
      isFollowingLoading: true,
    );

    ErrorHandler.log('Toggling follow', data: {
      'targetUserId': targetUserId,
      'newState': !isAlreadyFollowing,
    });

    try {
      if (isAlreadyFollowing) {
        await _repository.unfollowUser(currentUser.id, targetUserId);
        await AnalyticsHelper.logUserUnfollowed(targetUserId);
      } else {
        await _repository.followUser(currentUser.id, targetUserId);
        await AnalyticsHelper.logUserFollowed(targetUserId);
      }

      await fetchMyProfile();
      ErrorHandler.log('Follow toggled successfully');
    } catch (e, stackTrace) {
      // Rollback on error
      final revertedFollowing = List<String>.from(currentUser.following);
      state = state.copyWith(
        currentUser: currentUser.copyWith(following: revertedFollowing),
      );

      // ✅ Log error
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Toggle Follow',
        severity: ErrorSeverity.medium,
        userAction: isAlreadyFollowing ? 'Unfollowing user' : 'Following user',
        metadata: {'targetUserId': targetUserId},
      );

      Utils.showSnackBar(text: 'follow_error'.tr(), isError: true);
    } finally {
      state = state.copyWith(isFollowingLoading: false);
    }
  }

  Future<UserModel?> getUserById(String id) async {
    try {
      return await _repository.fetchProfile(id);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Get User By ID',
        severity: ErrorSeverity.low,
        metadata: {'userId': id},
      );
      return null;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    ErrorHandler.log('Searching users', data: {'query': query});
    await AnalyticsHelper.logSearch(query, 'user');

    try {
      return await _repository.searchUsers(query);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Search Users',
        severity: ErrorSeverity.low,
        metadata: {'query': query},
      );
      return [];
    }
  }

  Future<List<UserModel>> getFollowersList(String userId) async {
    try {
      return await _repository.getFollowers(userId);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Get Followers',
        severity: ErrorSeverity.low,
        metadata: {'userId': userId},
      );
      return [];
    }
  }

  Future<List<UserModel>> getFollowingList(String userId) async {
    try {
      return await _repository.getFollowing(userId);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Get Following',
        severity: ErrorSeverity.low,
        metadata: {'userId': userId},
      );
      return [];
    }
  }

  bool isFollowingUser(String targetUserId) {
    return state.currentUser?.isFollowing(targetUserId) ?? false;
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});

final featuredUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  try {
    final repository = ref.watch(userRepositoryProvider);
    return await repository.getFeaturedUsers(limit: 10);
  } catch (e, stackTrace) {
    ErrorHandler.logError(
      e,
      stackTrace: stackTrace,
      context: 'Fetch Featured Users',
      severity: ErrorSeverity.low,
    );
    return [];
  }
});

final suggestedUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  try {
    final repository = ref.watch(userRepositoryProvider);
    final currentUserId = ref.watch(userProvider).currentUser?.id;
    if (currentUserId == null) return [];

    return await repository.getSuggestedUsers(
      currentUserId: currentUserId,
      limit: 10,
    );
  } catch (e, stackTrace) {
    ErrorHandler.logError(
      e,
      stackTrace: stackTrace,
      context: 'Fetch Suggested Users',
      severity: ErrorSeverity.low,
    );
    return [];
  }
});
