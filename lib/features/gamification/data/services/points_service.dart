import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/models/rank_model.dart';
import 'package:yet_x_app/features/gamification/data/models/user_points_model.dart';
import 'package:yet_x_app/features/gamification/data/models/point_history_model.dart';

class PointsService {
  final _supabase = Supabase.instance.client;

  /// Kullanıcıya puan ekle
  Future<Map<String, dynamic>?> addPoints({
    required String userId,
    required int points,
    required String source,
    String? description,
    int? missionId,
  }) async {
    try {
      final response = await _supabase.rpc('add_user_points', params: {
        'p_user_id': userId,
        'p_points': points,
        'p_source': source,
        'p_description': description,
        'p_mission_id': missionId,
      });

      LogService.i('✅ Puan eklendi: $points ($source)');
      return response as Map<String, dynamic>;
    } catch (e) {
      LogService.e('❌ Puan ekleme hatası', e);
      return null;
    }
  }

  /// Kullanıcının puan bilgisini al
  Future<UserPointsModel?> getUserPoints(String userId) async {
    try {
      final response = await _supabase
          .from('user_points')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Kullanıcı kaydı yoksa oluştur
        await _supabase.from('user_points').insert({
          'user_id': userId,
          'total_points': 0,
          'rank': 'rookie',
          'level': 1,
        });

        return UserPointsModel(
          userId: userId,
          totalPoints: 0,
          rank: 'rookie',
          level: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return UserPointsModel.fromJson(response);
    } catch (e) {
      LogService.e('❌ Kullanıcı puanı alma hatası', e);
      return null;
    }
  }

  /// Tüm rütbeleri al
  Future<List<RankModel>> getAllRanks() async {
    try {
      final response = await _supabase
          .from('ranks')
          .select()
          .order('min_points', ascending: true);

      return (response as List)
          .map((json) => RankModel.fromJson(json))
          .toList();
    } catch (e) {
      LogService.e('❌ Rütbeleri alma hatası', e);
      return [];
    }
  }

  /// Belirli bir puana göre rütbe al
  Future<RankModel?> getRankByPoints(int points) async {
    try {
      final response = await _supabase
          .from('ranks')
          .select()
          .lte('min_points', points)
          .order('min_points', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return RankModel.fromJson(response);
    } catch (e) {
      LogService.e('❌ Rütbe alma hatası', e);
      return null;
    }
  }

  /// Puan geçmişini al
  Future<List<PointHistoryModel>> getPointHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('point_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => PointHistoryModel.fromJson(json))
          .toList();
    } catch (e) {
      LogService.e('❌ Puan geçmişi alma hatası', e);
      return [];
    }
  }

  /// Leaderboard al
  Future<List<Map<String, dynamic>>> getLeaderboard({
    int limit = 100,
    String period = 'all_time', // 'all_time', 'weekly', 'monthly'
  }) async {
    try {
      final response = await _supabase.rpc('get_leaderboard', params: {
        'p_limit': limit,
        'p_period': period,
      });

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      LogService.e('❌ Leaderboard alma hatası', e);
      return [];
    }
  }

  /// Kullanıcının leaderboard'daki sırasını al
  Future<int?> getUserRankPosition(String userId, {String period = 'all_time'}) async {
    try {
      final leaderboard = await getLeaderboard(limit: 1000, period: period);
      final index = leaderboard.indexWhere((user) => user['user_id'] == userId);
      return index >= 0 ? index + 1 : null;
    } catch (e) {
      LogService.e('❌ Kullanıcı sırası alma hatası', e);
      return null;
    }
  }
}
