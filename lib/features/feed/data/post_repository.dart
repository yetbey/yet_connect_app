import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/services/database_service.dart';
import 'package:yet_x_app/features/feed/data/datasources/post_local_data_source.dart';
import 'package:yet_x_app/features/feed/data/datasources/post_remote_data_source.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/core/utils/utils.dart'; // Utils için
import 'package:easy_localization/easy_localization.dart'; // LocaleKeys için
import 'package:yet_x_app/generated/locale_keys.g.dart'; // LocaleKeys için

class PostRepository {
  final PostLocalDataSource _localDataSource;
  final PostRemoteDataSource _remoteDataSource;
  final DatabaseService _dbService;

  PostRepository(
    this._localDataSource,
    this._remoteDataSource,
    this._dbService,
  );

  // --- AKIŞ (FEED) GETİR ---
  Future<List<PostModel>> fetchFeed({
    required int start,
    required int end,
    bool onlyFollowing = false,
    String? currentUserId,
    bool forceRefresh = false,
  }) async {
    try {
      final pageSize = end - start + 1;

      // 1. Force refresh değilse ve ilk sayfa ise cache'e bak
      if (!forceRefresh && start == 0 && !onlyFollowing) {
        final cachedPosts = await _localDataSource.getCachedFeed(
          limit: pageSize,
        );

        if (cachedPosts.isNotEmpty) {
          LogService.d('✅ ${cachedPosts.length} post cache\'den geldi');

          // Arka planda sessizce güncelle
          _updateFeedInBackground(start, end, currentUserId);

          return cachedPosts;
        }
      }

      // 2. Pagination durumu: Önce cache'e bak
      if (!forceRefresh && start > 0 && !onlyFollowing) {
        final totalCached = await _dbService.getCachedPostCount();

        // Cache'de yeterli veri varsa oradan getir
        if (totalCached >= end + 1) {
          final cachedPosts = await _dbService.getCachedPostsPaginated(
            offset: start,
            limit: pageSize,
          );

          if (cachedPosts.isNotEmpty) {
            LogService.d(
              '✅ Pagination: ${cachedPosts.length} post cache\'den geldi',
            );
            return cachedPosts.map((e) => PostModel.fromJsonLocal(e)).toList();
          }
        }
      }

      // 3. Cache yetersiz veya following feed ise network'ten çek
      final posts = await _remoteDataSource.fetchFeed(
        start: start,
        end: end,
        onlyFollowing: onlyFollowing,
        currentUserId: currentUserId,
      );

      // 4. Gelen veriyi cache'e ekle
      if (!onlyFollowing) {
        await _localDataSource.cachePosts(
          posts,
          replaceAll: start == 0, // İlk sayfa ise cache'i temizle
        );
        LogService.d(
          '💾 ${posts.length} post cache\'e ${start == 0 ? "replace ile" : "incremental"} eklendi',
        );
      }

      return posts;
    } catch (e) {
      LogService.e('❌ Feed fetch hatası', e);

      // Hata durumunda cache varsa kullanıcı boş ekran görmesin
      if (start == 0 && !onlyFollowing) {
        final cachedPosts = await _localDataSource.getCachedFeed();
        if (cachedPosts.isNotEmpty) {
          LogService.w('⚠️ Hata sonrası cached feed döndürüldü');
          Utils.showSnackBar(
            text: LocaleKeys.errors_network_error.tr(),
            isError: true,
          );
          return cachedPosts;
        }
      }

      rethrow;
    }
  }

  Future<void> _updateFeedInBackground(
    int start,
    int end,
    String? currentUserId,
  ) async {
    try {
      final posts = await _remoteDataSource.fetchFeed(
        start: start,
        end: end,
        currentUserId: currentUserId,
      );
      await _localDataSource.cachePosts(posts);
      LogService.d('🔄 Feed arka planda güncellendi');
    } catch (e) {
      LogService.d('⚠️ Arka plan feed güncellemesi başarısız: $e');
    }
  }

  // --- KULLANICI GÖNDERİLERİNİ GETİR ---
  Future<List<PostModel>> fetchUserPosts(
    String userId,
    String? currentUserId,
  ) async {
    try {
      // Önce local cache kontrolü
      final cachedPosts = await _localDataSource.getUserPosts(userId);
      if (cachedPosts.isNotEmpty) {
        LogService.d('✅ Kullanıcı postları cache\'den geldi');
        _updateUserPostsInBackground(userId, currentUserId);
        return cachedPosts;
      }

      // Yoksa remote
      final posts = await _remoteDataSource.fetchUserPosts(
        userId,
        currentUserId,
      );
      await _localDataSource.cachePosts(posts);
      return posts;
    } catch (e) {
      LogService.e('❌ Kullanıcı postları fetch hatası', e);
      final cachedPosts = await _localDataSource.getUserPosts(userId);
      if (cachedPosts.isNotEmpty) return cachedPosts;
      rethrow;
    }
  }

  Future<void> _updateUserPostsInBackground(
    String userId,
    String? currentUserId,
  ) async {
    try {
      final posts = await _remoteDataSource.fetchUserPosts(
        userId,
        currentUserId,
      );
      await _localDataSource.cachePosts(posts);
    } catch (_) {}
  }

  // --- CRUD İŞLEMLERİ ---
  Future<PostModel> createPost({
    required String caption,
    required String userId,
    File? imageFile,
    File? videoFile,
    Alignment alignment = Alignment.center,
    List<String>? tags,
  }) async {
    // Önce sunucuya gönder
    final post = await _remoteDataSource.createPost(
      caption: caption,
      userId: userId,
      imageFile: imageFile,
      videoFile: videoFile,
      alignment: alignment,
      tags: tags,
    );
    // Başarılı olursa locale kaydet
    await _localDataSource.cachePosts([post]);
    return post;
  }

  Future<void> updatePost({
    required String postId,
    String? caption,
    List<String>? tags,
  }) async {
    await _remoteDataSource.updatePost(
      postId: postId,
      caption: caption,
      tags: tags,
    );
    // Not: Update sonrası tüm feed'i yenilemek yerine sadece ilgili postu local'de güncellemek daha performanslı olur ama şimdilik feed yenileme stratejisi kullanıyoruz.
  }

  Future<void> deletePost(String postId) async {
    await _remoteDataSource.deletePost(postId);
    await _localDataSource.deletePost(postId);
  }

  // --- ETKİLEŞİMLER ---
  Future<Map<String, dynamic>> toggleLike(String postId, String userId) async {
    // Network çağrısını yap
    final result = await _remoteDataSource.toggleLike(postId, userId);

    // ✅ Local cache'i güncelle
    await _dbService.updatePostInCache(
      postId: postId,
      likes: result['like_count'],
      isLiked: result['is_liked'],
    );

    LogService.d('✅ Like işlemi sonrası cache güncellendi');

    return result;
  }

  Future<List<Map<String, dynamic>>> getLikes(String postId) async {
    return await _remoteDataSource.getLikes(postId);
  }

  // --- ETİKET İŞLEMLERİ (Sadece Remote) ---
  Future<List<Map<String, dynamic>>> getPostsByTag(
    String tag, {
    int limit = 20,
  }) {
    return _remoteDataSource.getPostsByTag(tag, limit: limit);
  }

  Future<List<Map<String, dynamic>>> getPopularTags({int limit = 20}) {
    return _remoteDataSource.getPopularTags(limit: limit);
  }

  Future<List<Map<String, dynamic>>> searchTags(String query) {
    return _remoteDataSource.searchTags(query);
  }

  Future<List<String>> getFollowedTags() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    return _remoteDataSource.getFollowedTags(userId);
  }

  Future<void> followTag(String tagName) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await _remoteDataSource.followTag(userId, tagName);
  }

  Future<void> unfollowTag(String tagName) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await _remoteDataSource.unfollowTag(userId, tagName);
  }
}

// ✅ PROVIDER TANIMI
final postRepositoryProvider = Provider<PostRepository>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  final supabase = Supabase.instance.client;

  return PostRepository(
    PostLocalDataSourceImpl(dbService),
    PostRemoteDataSourceImpl(supabase),
    dbService,
  );
});
