import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/models/daily_challenge_model.dart';

class DailyChallengeService {
  final _supabase = Supabase.instance.client;

  /// Bugünün challenge'ını getir
  Future<DailyChallengeModel?> getTodayChallenge() async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('daily_challenges')
          .select()
          .eq('challenge_date', todayStr)
          .maybeSingle();

      if (response == null) return null;
      return DailyChallengeModel.fromJson(response);
    } catch (e) {
      LogService.e('❌ Günlük challenge yükleme hatası', e);
      return null;
    }
  }

  /// Bugün bu etiketle kaç post paylaşılmış (katılım sayısı)
  Future<int> getTodayParticipantCount(String tagName) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('posts')
          .select('id')
          .contains('tags', [tagName])
          .gte('created_at', startOfDay.toIso8601String())
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      LogService.e('❌ Katılım sayısı alma hatası', e);
      return 0;
    }
  }

  /// Kullanıcı bugün bu challenge'a katılmış mı
  Future<bool> hasUserParticipatedToday(String tagName, String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('posts')
          .select('id')
          .eq('user_id', userId)
          .contains('tags', [tagName])
          .gte('created_at', startOfDay.toIso8601String())
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      LogService.e('❌ Katılım kontrolü hatası', e);
      return false;
    }
  }
}