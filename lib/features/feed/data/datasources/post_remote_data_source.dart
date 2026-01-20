import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';

abstract class PostRemoteDataSource {
  Future<List<PostModel>> fetchFeed({
    required int start,
    required int end,
    bool onlyFollowing = false,
    String? currentUserId,
  });

  Future<List<PostModel>> fetchUserPosts(String userId, String? currentUserId);

  Future<PostModel> createPost({
    required String caption,
    required String userId,
    File? imageFile,
    File? videoFile,
    Alignment alignment = Alignment.center,
    List<String>? tags,
  });

  Future<void> updatePost({
    required String postId,
    String? caption,
    List<String>? tags,
  });

  Future<void> deletePost(String postId);

  Future<Map<String, dynamic>> toggleLike(String postId, String userId);

  Future<List<Map<String, dynamic>>> getLikes(String postId);

  // --- Etiket Metodları ---
  Future<List<Map<String, dynamic>>> getPostsByTag(
    String tag, {
    int limit = 20,
  });

  Future<List<Map<String, dynamic>>> getPopularTags({int limit = 20});

  Future<List<Map<String, dynamic>>> searchTags(String query);

  Future<List<String>> getFollowedTags(String userId);

  Future<void> followTag(String userId, String tagName);

  Future<void> unfollowTag(String userId, String tagName);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final SupabaseClient _supabase;

  PostRemoteDataSourceImpl(this._supabase);

  // --- AKIŞ (FEED) GETİR ---
  @override
  Future<List<PostModel>> fetchFeed({
    required int start,
    required int end,
    bool onlyFollowing = false,
    String? currentUserId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_feed_posts',
        params: {
          'p_user_id': currentUserId ?? '00000000-0000-0000-0000-000000000000',
          'p_start_index': start,
          'p_end_index': end,
          'p_only_following': onlyFollowing,
        },
      );

      return _parseRpcPosts(response as List);
    } catch (e) {
      ErrorHandler.logError(
        e,
        context: 'Fetch Feed',
        severity: ErrorSeverity.high,
      );
      rethrow;
    }
  }

  // --- KULLANICI GÖNDERİLERİ ---
  @override
  Future<List<PostModel>> fetchUserPosts(
    String userId,
    String? currentUserId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_user_posts',
        params: {
          'p_target_user_id': userId,
          'p_current_user_id':
              currentUserId ?? '00000000-0000-0000-0000-000000000000',
          'p_limit': 50,
        },
      );

      return _parseRpcPosts(response as List);
    } catch (e) {
      ErrorHandler.logError(
        e,
        context: 'Fetch User Posts',
        severity: ErrorSeverity.medium,
      );
      rethrow;
    }
  }

  // --- GÖNDERİ OLUŞTUR ---
  @override
  Future<PostModel> createPost({
    required String caption,
    required String userId,
    File? imageFile,
    File? videoFile,
    Alignment alignment = Alignment.center,
    List<String>? tags,
  }) async {
    String? imageUrl;
    String? videoUrl;

    // Resim Yükleme
    if (imageFile != null) {
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '$userId/img_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await _supabase.storage.from('uploads').upload(fileName, imageFile);
      imageUrl = _supabase.storage.from('uploads').getPublicUrl(fileName);
    }

    // Video Yükleme
    if (videoFile != null) {
      final fileExt = videoFile.path.split('.').last;
      final fileName =
          '$userId/vid_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await _supabase.storage.from('uploads').upload(fileName, videoFile);
      videoUrl = _supabase.storage.from('uploads').getPublicUrl(fileName);
    }

    final response = await _supabase
        .from('posts')
        .insert({
          'caption': caption,
          'image_url': imageUrl,
          'video_url': videoUrl,
          'user_id': userId,
          'alignment_x': alignment.x,
          'alignment_y': alignment.y,
          'tags': tags ?? [],
        })
        .select('''
        *,
        profiles:profiles!posts_user_id_fkey(*),
        post_likes(count),
        comments(count)
      ''')
        .single();

    final modifiedREsponse = Map<String, dynamic>.from(response);
    modifiedREsponse['my_likes'] = [];
    return PostModel.fromJson(modifiedREsponse);
  }

  // --- GÜNCELLE ---
  @override
  Future<void> updatePost({
    required String postId,
    String? caption,
    List<String>? tags,
  }) async {
    final updateData = <String, dynamic>{};
    if (caption != null) updateData['caption'] = caption;
    if (tags != null) updateData['tags'] = tags;

    if (updateData.isNotEmpty) {
      await _supabase.from('posts').update(updateData).eq('id', postId);
    }
  }

  // --- SİL ---
  @override
  Future<void> deletePost(String postId) async {
    // Önce post verisini çek (dosya yolları ve tagler için)
    final postData = await _supabase
        .from('posts')
        .select('image_url, video_url')
        .eq('id', postId)
        .maybeSingle();

    if (postData == null) return;

    // Storage'dan medya dosyalarını sil
    if (postData['image_url'] != null) {
      try {
        final imageUrl = postData['image_url'] as String;
        // URL'den path'i ayrıştır: .../uploads/userid/filename.jpg -> userid/filename.jpg
        final path = Uri.parse(imageUrl).path.split('/uploads/').last;
        await _supabase.storage.from('uploads').remove([path]);
      } catch (e, stacktrace) {
        ErrorHandler.logError(
          e,
          stackTrace: stacktrace,
          context: 'Image Url Uploads',
          severity: ErrorSeverity.low,
        );
      }
    }

    if (postData['video_url'] != null) {
      try {
        final videoUrl = postData['video_url'] as String;
        final path = Uri.parse(videoUrl).path.split('/uploads/').last;
        await _supabase.storage.from('uploads').remove([path]);
      } catch (e, stacktrace) {
        ErrorHandler.logError(
          e,
          stackTrace: stacktrace,
          context: 'Video Url Uploads',
          severity: ErrorSeverity.low,
        );
      }
    }

    await _supabase.from('posts').delete().eq('id', postId);
  }

  // --- BEĞENİ İŞLEMLERİ ---
  @override
  Future<Map<String, dynamic>> toggleLike(String postId, String userId) async {
    try {
      final response = await _supabase.rpc(
        'toggle_post_like',
        params: {'p_post_id': int.parse(postId), 'p_user_id': userId},
      );

      return {
        'is_liked': response['is_liked'] as bool,
        'like_count': response['like_count'] as int,
      };
    } catch (e) {
      ErrorHandler.logError(
        e,
        context: 'Toggle Post Lİkes',
        severity: ErrorSeverity.medium,
      );
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLikes(String postId) async {
    final data = await _supabase
        .from('post_likes')
        .select('profiles(*)')
        .eq('post_id', postId);

    return (data as List)
        .map((e) => e['profiles'] as Map<String, dynamic>)
        .toList();
  }

  // --- ETİKET İŞLEMLERİ ---
  @override
  Future<List<Map<String, dynamic>>> getPostsByTag(
    String tag, {
    int limit = 20,
  }) async {
    // Current User ID'yi al (beğeni durumu için)
    /* final currentUserId = _supabase.auth.currentUser?.id; */

    final response = await _supabase
        .from('posts')
        .select('''
            *,
            profiles:profiles!posts_user_id_fkey(*),
            post_likes(count),
            comments(count),
            my_likes:post_likes(user_id)
          ''')
        .contains('tags', [tag])
        .order('created_at', ascending: false)
        .limit(limit);

    // Ham veriyi döndür, PostModel dönüşümü Repository veya Provider'da yapılabilir
    // Ancak tutarlılık için burada da helper kullanmıyoruz çünkü dönüş tipi List<Map>
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> getPopularTags({int limit = 20}) async {
    final response = await _supabase
        .from('tags')
        .select('name, post_count')
        .order('post_count', ascending: false)
        .limit(limit);

    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> searchTags(String query) async {
    final response = await _supabase
        .from('tags')
        .select('name, post_count')
        .ilike('name', '%$query%')
        .order('post_count', ascending: false)
        .limit(10);

    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Future<List<String>> getFollowedTags(String userId) async {
    final response = await _supabase
        .from('tag_follows')
        .select('tag_name')
        .eq('user_id', userId);

    return (response as List).map((e) => e['tag_name'] as String).toList();
  }

  @override
  Future<void> followTag(String userId, String tagName) async {
    await _supabase.from('tag_follows').insert({
      'user_id': userId,
      'tag_name': tagName,
    });
  }

  @override
  Future<void> unfollowTag(String userId, String tagName) async {
    await _supabase
        .from('tag_follows')
        .delete()
        .eq('user_id', userId)
        .eq('tag_name', tagName);
  }

  // --- YARDIMCI METODLAR ---
  List<PostModel> _parseRpcPosts(List data) {
    return data.map((row) {
      // Top likers parsing
      List<LikerPreview> topLikers = [];
      if (row['top_likers'] != null) {
        final likersJson = row['top_likers'];
        if (likersJson is List) {
          topLikers = likersJson
              .map((l) => LikerPreview.fromJson(l as Map<String, dynamic>))
              .toList();
        }
      }

      return PostModel(
        id: row['id'].toString(),
        userId: row['user_id'].toString(),
        caption: row['caption'],
        imageUrl: row['image_url'],
        videoUrl: row['video_url'],
        createdAt: row['created_at'] != null
            ? DateTime.parse(row['created_at'])
            : DateTime.now(),
        username: row['username'] ?? 'Kullanıcı',
        userFullName: row['full_name'],
        userProfileImage: row['profile_image_url'],
        alignmentX: (row['alignment_x'] as num?)?.toDouble(),
        alignmentY: (row['alignment_y'] as num?)?.toDouble(),
        likes: (row['like_count'] ?? 0) as int,
        isLikedByCurrentUser: row['is_liked_by_user'] ?? false,
        commentCount: (row['comment_count'] ?? 0) as int,
        tags: row['tags'] != null ? List<String>.from(row['tags']) : [],
        topLikers: topLikers,  // YENİ
      );
    }).toList();
  }
}
