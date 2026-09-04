import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/models/live_event_model.dart';

class LiveEventService {
  final _supabase = Supabase.instance.client;

  /// Şu an 'live' durumda olan etkinliği getir
  Future<LiveEventModel?> getCurrentLiveEvent() async {
    try {
      final response = await _supabase
          .from('live_events')
          .select()
          .eq('status', 'live')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return LiveEventModel.fromJson(response);
    } catch (e) {
      LogService.e('❌ Canlı etkinlik alma hatası', e);
      return null;
    }
  }

  /// Bir etkinliğin geçmiş mesajlarını (profil bilgisiyle) getir
  Future<List<Map<String, dynamic>>> getInitialMessages(
      String eventId, {
        int limit = 50,
      }) async {
    try {
      final response = await _supabase
          .from('live_event_messages')
          .select('*, profiles(username, full_name, profile_image_url)')
          .eq('event_id', eventId)
          .order('created_at', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      LogService.e('❌ Canlı etkinlik mesajları alma hatası', e);
      return [];
    }
  }

  /// Mesajları gerçek zamanlı dinle (yeni mesaj eklenince/silinince tüm liste gelir)
  Stream<List<Map<String, dynamic>>> streamMessages(String eventId) {
    return _supabase
        .from('live_event_messages')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .order('created_at');
  }

  /// Mesaj gönder
  Future<void> sendMessage({
    required String eventId,
    required String userId,
    required String message,
  }) async {
    await _supabase.from('live_event_messages').insert({
      'event_id': eventId,
      'user_id': userId,
      'message': message,
    });
  }

  /// Tek bir kullanıcının profilini getir (stream'den gelen mesajlarda
  /// profil bilgisi olmadığı için cache'e eklemek amacıyla kullanılır)
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      return await _supabase
          .from('profiles')
          .select('username, full_name, profile_image_url')
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      LogService.e('❌ Profil alma hatası', e);
      return null;
    }
  }
}