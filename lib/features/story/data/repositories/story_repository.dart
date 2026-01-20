import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/story/data/models/story_model.dart';

class StoryRepository {
  final SupabaseClient _supabase;

  StoryRepository(this._supabase);

  /// Takip edilen kullanıcıların story'lerini getir (gruplu)
  Future<List<UserStoryGroup>> getFollowingStories(String currentUserId) async {
    try {
      final response = await _supabase
          .from('stories')
          .select('''
          *,
          profiles!inner(id, username, full_name, profile_image_url),
          story_views!left(viewer_id)
        ''')
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: true); // ✅ Önce eskiden yeniye sırala

      final List<dynamic> data = response as List;

      // Story'leri kullanıcıya göre grupla
      final Map<String, List<StoryModel>> groupedStories = {};

      for (var item in data) {
        final story = StoryModel.fromJson({
          ...item,
          'username': item['profiles']['username'],
          'user_full_name': item['profiles']['full_name'],
          'user_profile_image': item['profiles']['profile_image_url'],
          'is_viewed_by_me': (item['story_views'] as List?)
              ?.any((view) => view['viewer_id'] == currentUserId) ?? false,
        });

        final userId = story.userId;
        if (!groupedStories.containsKey(userId)) {
          groupedStories[userId] = [];
        }
        groupedStories[userId]!.add(story); // ✅ Sırası korunarak ekleniyor
      }

      // UserStoryGroup'lara dönüştür
      final List<UserStoryGroup> storyGroups = [];
      groupedStories.forEach((userId, stories) {
        if (stories.isNotEmpty) {
          final hasUnseen = stories.any((s) => s.isViewedByMe == false);
          storyGroups.add(UserStoryGroup(
            userId: userId,
            username: stories.first.username ?? '',
            userFullName: stories.first.userFullName,
            userProfileImage: stories.first.userProfileImage,
            stories: stories, // ✅ Zaten created_at'e göre sıralı
            hasUnseenStories: hasUnseen,
            lastStoryTime: stories.last.createdAt, // ✅ Son story zamanı
          ));
        }
      });

      // İlk sırada görülmemiş story'ler, sonra en yeni story'ye göre sırala
      storyGroups.sort((a, b) {
        // Önce unseen story'leri öne al
        if (a.hasUnseenStories && !b.hasUnseenStories) return -1;
        if (!a.hasUnseenStories && b.hasUnseenStories) return 1;
        // Sonra en yeni story'ye göre sırala
        return b.lastStoryTime.compareTo(a.lastStoryTime);
      });

      LogService.i('✅ ${storyGroups.length} kullanıcının story\'si getirildi');
      return storyGroups;
    } catch (e) {
      LogService.e('❌ Story getirme hatası', e);
      rethrow;
    }
  }

  /// Belirli bir kullanıcının tüm story'lerini getir
  Future<List<StoryModel>> getUserStories(String userId, String? currentUserId) async {
    try {
      final response = await _supabase
          .from('stories')
          .select('''
          *,
          profiles!inner(username, full_name, profile_image_url),
          story_views!left(viewer_id)
        ''')
          .eq('user_id', userId)
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: true); // ✅ Eskiden yeniye

      final List<dynamic> data = response as List;

      return data.map((item) {
        return StoryModel.fromJson({
          ...item,
          'username': item['profiles']['username'],
          'user_full_name': item['profiles']['full_name'],
          'user_profile_image': item['profiles']['profile_image_url'],
          'is_viewed_by_me': currentUserId != null
              ? (item['story_views'] as List?)
              ?.any((view) => view['viewer_id'] == currentUserId) ?? false
              : false,
        });
      }).toList();
    } catch (e) {
      LogService.e('❌ Kullanıcı story\'leri getirme hatası', e);
      rethrow;
    }
  }

  /// Story oluştur
  Future<StoryModel> createStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
    File? thumbnailFile,
    int? duration,
  }) async {
    try {
      // 1. Medya dosyasını yükle
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'story_${userId}_$timestamp.${mediaType == 'video' ? 'mp4' : 'jpg'}';
      final storagePath = 'stories/$userId/$fileName';

      await _supabase.storage.from('media').upload(storagePath, mediaFile);

      final mediaUrl = _supabase.storage
          .from('media')
          .getPublicUrl(storagePath);

      // 2. Thumbnail yükle (video için)
      String? thumbnailUrl;
      if (thumbnailFile != null) {
        final thumbFileName = 'story_${userId}_${timestamp}_thumb.jpg';
        final thumbPath = 'stories/$userId/$thumbFileName';

        await _supabase.storage.from('media').upload(thumbPath, thumbnailFile);

        thumbnailUrl = _supabase.storage.from('media').getPublicUrl(thumbPath);
      }

      // 3. Story veritabanına kaydet
      final response = await _supabase
          .from('stories')
          .insert({
            'user_id': userId,
            'media_url': mediaUrl,
            'media_type': mediaType,
            'thumbnail_url': thumbnailUrl,
            'duration': duration,
            'created_at': DateTime.now().toIso8601String(),
            'expires_at': DateTime.now()
                .add(const Duration(hours: 24))
                .toIso8601String(),
          })
          .select()
          .single();

      LogService.i('✅ Story oluşturuldu: ${response['id']}');
      return StoryModel.fromJson(response);
    } catch (e) {
      LogService.e('❌ Story oluşturma hatası', e);
      rethrow;
    }
  }

  /// Story'yi görüntüle (view count artır)
  Future<void> viewStory(int storyId, String viewerId) async {
    try {
      // Story_views tablosuna ekle (duplicate kontrolü var)
      await _supabase.from('story_views').insert({
        'story_id': storyId,
        'viewer_id': viewerId,
        'viewed_at': DateTime.now().toIso8601String(),
      });

      // RPC ile view count artır
      await _supabase.rpc(
        'increment_story_view_count',
        params: {'story_id': storyId},
      );

      LogService.d('✅ Story görüntülendi: $storyId');
    } catch (e) {
      // Duplicate entry hatası önemsiz
      if (!e.toString().contains('duplicate')) {
        LogService.e('❌ Story view hatası', e);
      }
    }
  }

  /// Story'yi sil
  Future<void> deleteStory(int storyId, String userId) async {
    try {
      // Önce story bilgilerini al
      final story = await _supabase
          .from('stories')
          .select('media_url, thumbnail_url')
          .eq('id', storyId)
          .eq('user_id', userId)
          .single();

      // Storage'dan medyaları sil
      if (story['media_url'] != null) {
        final mediaPath = _extractStoragePath(story['media_url']);
        if (mediaPath != null) {
          await _supabase.storage.from('media').remove([mediaPath]);
        }
      }

      if (story['thumbnail_url'] != null) {
        final thumbPath = _extractStoragePath(story['thumbnail_url']);
        if (thumbPath != null) {
          await _supabase.storage.from('media').remove([thumbPath]);
        }
      }

      // Veritabanından sil
      await _supabase
          .from('stories')
          .delete()
          .eq('id', storyId)
          .eq('user_id', userId);

      LogService.i('✅ Story silindi: $storyId');
    } catch (e) {
      LogService.e('❌ Story silme hatası', e);
      rethrow;
    }
  }

  /// Story görüntüleyenlerini getir
  Future<List<Map<String, dynamic>>> getStoryViewers(int storyId) async {
    try {
      final response = await _supabase
          .from('story_views')
          .select('''
            viewed_at,
            profiles!inner(id, username, full_name, profile_image_url)
          ''')
          .eq('story_id', storyId)
          .order('viewed_at', ascending: false);

      return (response as List).map((item) {
        return {
          'user_id': item['profiles']['id'],
          'username': item['profiles']['username'],
          'full_name': item['profiles']['full_name'],
          'profile_image_url': item['profiles']['profile_image_url'],
          'viewed_at': item['viewed_at'],
        };
      }).toList();
    } catch (e) {
      LogService.e('❌ Story viewers getirme hatası', e);
      rethrow;
    }
  }

  String? _extractStoragePath(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final mediaIndex = segments.indexOf('media');
      if (mediaIndex != -1 && mediaIndex + 1 < segments.length) {
        return segments.sublist(mediaIndex + 1).join('/');
      }
    } catch (e) {
      LogService.w('Storage path çıkarma hatası: $e');
    }
    return null;
  }
}
