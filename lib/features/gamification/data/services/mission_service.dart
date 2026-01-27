import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/models/mission_model.dart';

class MissionService {
  final _supabase = Supabase.instance.client;

  /// Aktif görevleri al (tip bazlı)
  Future<List<MissionModel>> getMissions({
    String? type, // 'daily', 'weekly', 'special'
    String? userId,
  }) async {
    try {
      var query = _supabase
          .from('missions')
          .select()
          .eq('is_active', true);

      if (type != null) {
        query = query.eq('type', type);
      }

      final missionsData = await query.order('id', ascending: true);

      if (userId == null) {
        return (missionsData as List)
            .map((json) => MissionModel.fromJson(json))
            .toList();
      }

      // Kullanıcı ilerleme bilgilerini ekle
      final today = DateTime.now();
      final resetDate = type == 'daily'
          ? DateTime(today.year, today.month, today.day)
          : _getWeekStart(today);

      final missions = <MissionModel>[];

      for (var missionData in missionsData) {
        final missionId = missionData['id'] as int;

        // Kullanıcının bu görevdeki ilerlemesini al
        final progressData = await _supabase
            .from('user_mission_progress')
            .select()
            .eq('user_id', userId)
            .eq('mission_id', missionId)
            .gte('reset_at', resetDate.toIso8601String())
            .maybeSingle();

        final mission = MissionModel.fromJson({
          ...missionData,
          'current_progress': progressData?['current_progress'] ?? 0,
          'is_completed': progressData?['is_completed'] ?? false,
        });

        missions.add(mission);
      }

      return missions;
    } catch (e) {
      LogService.e('❌ Görevleri alma hatası', e);
      return [];
    }
  }

  /// Görev ilerlemesini güncelle
  Future<Map<String, dynamic>?> updateMissionProgress({
    required String userId,
    required int missionId,
    int increment = 1,
  }) async {
    try {
      final response = await _supabase.rpc('update_mission_progress', params: {
        'p_user_id': userId,
        'p_mission_id': missionId,
        'p_increment': increment,
      });

      final result = response as Map<String, dynamic>;

      if (result['is_completed'] == true) {
        LogService.i('🎉 Görev tamamlandı! +${result['points_earned']} puan');
      }

      return result;
    } catch (e) {
      LogService.e('❌ Görev güncelleme hatası', e);
      return null;
    }
  }

  /// Kullanıcının tamamladığı görevleri al
  Future<List<MissionModel>> getCompletedMissions({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('user_mission_progress')
          .select('*, missions(*)')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('completed_at', ascending: false)
          .limit(limit);

      return (response as List).map((data) {
        final missionData = data['missions'];
        return MissionModel.fromJson({
          ...missionData,
          'current_progress': data['current_progress'],
          'is_completed': true,
        });
      }).toList();
    } catch (e) {
      LogService.e('❌ Tamamlanan görevleri alma hatası', e);
      return [];
    }
  }

  /// Hafta başlangıcını hesapla (Pazartesi)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final daysToSubtract = weekday - 1; // Pazartesi = 1
    final weekStart = date.subtract(Duration(days: daysToSubtract));
    return DateTime(weekStart.year, weekStart.month, weekStart.day);
  }

  /// Günlük görevleri resetle (cron job için)
  Future<void> resetDailyMissions() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await _supabase
          .from('user_mission_progress')
          .delete()
          .lt('reset_at', yesterday.toIso8601String());

      LogService.i('✅ Günlük görevler resetlendi');
    } catch (e) {
      LogService.e('❌ Görev reset hatası', e);
    }
  }
}
