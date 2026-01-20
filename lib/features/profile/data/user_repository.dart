import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/core/services/database_service.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';

class UserRepository {
  final SupabaseClient _supabase;
  final DatabaseService _db;

  UserRepository(this._supabase, this._db);

  /// Kullanıcı profilini getir (Cache-first stratejisi)
  Future<UserModel> fetchProfile(String userId) async {
    try {
      // 1. Önce database'den hızlıca çek (offline kullanım için)
      final cachedUser = await _db.getUser(userId);
      if (cachedUser != null) {
        LogService.d('✅ Kullanıcı cache\'den geldi: ${cachedUser.userName}');
        // Arka planda güncelleme yap (kullanıcı görmeden)
        _updateUserInBackground(userId);
        return cachedUser;
      }

      // 2. Cache'de yoksa Supabase'den çek
      LogService.d('🌐 Kullanıcı internetten çekiliyor: $userId');
      final user = await _fetchFromSupabase(userId);

      // 3. Database'e kaydet
      await _db.saveUser(user, cacheDuration: const Duration(days: 7));

      return user;
    } catch (e) {
      LogService.e('❌ fetchProfile hatası', e);

      // 4. Her iki yerde de hata varsa son çare cached veriyi dön
      final cachedUser = await _db.getUser(userId);
      if (cachedUser != null) {
        LogService.w('⚠️ Hata sonrası cached kullanıcı döndürüldü');
        return cachedUser;
      }

      rethrow;
    }
  }

  /// Arka planda kullanıcıyı güncelle (UI bloklamadan)
  Future<void> _updateUserInBackground(String userId) async {
    try {
      final user = await _fetchFromSupabase(userId);
      await _db.saveUser(user, cacheDuration: const Duration(days: 7));
      LogService.d('🔄 Kullanıcı arka planda güncellendi: ${user.userName}');
    } catch (e) {
      // Sessizce hata yut, kullanıcı deneyimini bozma
      LogService.d('⚠️ Arka plan güncellemesi başarısız (önemli değil)');
    }
  }

  /// Supabase'den kullanıcı çek
  Future<UserModel> _fetchFromSupabase(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select('''
          *,
          followers:follows!following_id(follower_id),
          following:follows!follower_id(following_id)
        ''')
        .eq('id', userId)
        .maybeSingle();

    final userMap = Map<String, dynamic>.from(data!);

    if (_supabase.auth.currentUser?.id == userId) {
      userMap['email'] = _supabase.auth.currentUser?.email ?? '';
    }

    return UserModel.fromJson(userMap);
  }

  /// Local database'den kullanıcı getir (Provider için)
  Future<UserModel?> getLocalProfile(String userId) async {
    return await _db.getUser(userId);
  }

  // --- PROFİL GÜNCELLE ---
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;

    await _supabase.from('profiles').update(updates).eq('id', userId);

    // Cache'i de güncelle
    final user = await _db.getUser(userId);
    if (user != null) {
      final updatedUser = user.copyWith(
        fullName: fullName ?? user.fullName,
        bio: bio ?? user.bio,
      );
      await _db.saveUser(updatedUser);
    }
  }

  // --- PROFİL RESMİ GÜNCELLE ---
  Future<void> updateProfileImage(String userId, File imageFile) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName = '$userId/avatar.$fileExt';

    await _supabase.storage
        .from('uploads')
        .upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    final imageUrl = _supabase.storage.from('uploads').getPublicUrl(fileName);
    final finalUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';

    await _supabase
        .from('profiles')
        .update({'profile_image_url': finalUrl})
        .eq('id', userId);

    // Cache'i güncelle
    final user = await _db.getUser(userId);
    if (user != null) {
      final updatedUser = user.copyWith(profileImageUrl: finalUrl);
      await _db.saveUser(updatedUser);
    }
  }

  // --- KULLANICI ARAMA ---
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // İlk olarak online ara
      final data = await _supabase
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);

      return (data as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      // Hata varsa local database'den ara
      return await _db.searchUsers(query);
    }
  }

  // --- TAKİP ET / TAKİPTEN ÇIK ---
  Future<void> followUser(String currentUserId, String targetUserId) async {
    await _supabase.from('follows').insert({
      'follower_id': currentUserId,
      'following_id': targetUserId,
    });

    // Cache'i güncelle
    final user = await _db.getUser(currentUserId);
    if (user != null) {
      final following = List<String>.from(user.following)..add(targetUserId);
      await _db.saveUser(user.copyWith(following: following));
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId);

    // Cache'i güncelle
    final user = await _db.getUser(currentUserId);
    if (user != null) {
      final following = List<String>.from(user.following)..remove(targetUserId);
      await _db.saveUser(user.copyWith(following: following));
    }
  }

  // --- TAKİPÇİ / TAKİP EDİLEN LİSTESİ ---
  Future<List<UserModel>> getFollowers(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('profiles!follower_id (*)')
        .eq('following_id', userId);

    return (data as List)
        .map((e) => UserModel.fromJson(e['profiles']))
        .toList();
  }

  Future<List<UserModel>> getFollowing(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('profiles!following_id (*)')
        .eq('follower_id', userId);

    return (data as List)
        .map((e) => UserModel.fromJson(e['profiles']))
        .toList();
  }

  Future<List<UserModel>> getFeaturedUsers({int limit = 10}) async {
    try {
      // ✅ RPC function kullan veya manuel count yap
      final data = await _supabase.rpc(
        'get_featured_users',
        params: {'limit_count': limit},
      );

      return (data as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      LogService.e('Featured users fetch hatası', e);

      // ✅ RPC yoksa fallback: Basit query
      try {
        final data = await _supabase
            .from('profiles')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);

        return (data as List).map((e) => UserModel.fromJson(e)).toList();
      } catch (e2) {
        LogService.e('Featured users fallback hatası', e2);
        return [];
      }
    }
  }

  /// Önerilenler (Takip etmediğin aktif kullanıcılar)
  Future<List<UserModel>> getSuggestedUsers({
    required String currentUserId,
    int limit = 10,
  }) async {
    try {
      // Takip ettiklerini çek
      final followingData = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final List<String> followingIds = (followingData as List)
          .map((e) => e['following_id'].toString())
          .toList();
      followingIds.add(currentUserId); // Kendini de hariç tut

      // Takip etmediklerinden öner
      final data = await _supabase
          .from('profiles')
          .select('*, followers:follows!following_id(count)')
          .not('id', 'in', '(${followingIds.join(',')})')
          .order('followers.count', ascending: false)
          .limit(limit);

      return (data as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      LogService.e('Suggested users fetch hatası', e);
      return [];
    }
  }

}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    Supabase.instance.client,
    ref.read(databaseServiceProvider),
  );
});
