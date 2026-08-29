import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/core/constants/scoring_constants.dart';
import 'package:yet_x_app/features/gamification/data/services/points_service.dart';
import 'package:yet_x_app/features/gamification/data/services/mission_service.dart';

class ActivityTracker {
  static final _pointsService = PointsService();
  static final _missionService = MissionService();
  static final _supabase = Supabase.instance.client;

  /// When a post is shared
  static Future<void> onPostCreated() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _pointsService.addPoints(
        userId: userId,
        points: ScoringConstants.postPoints,
        source: 'post',
        description: 'Gönderi paylaştı',
      );

      await _missionService.updateMissionProgress(
        userId: userId,
        missionId: 1, // "İlk Gönderi" görevi
        increment: 1,
      );

      // Haftalık görev (20 post)
      await _missionService.updateMissionProgress(
        userId: userId,
        missionId: 4, // "Aktif Kullanıcı" görevi
        increment: 1,
      );

      LogService.i('✅ Post aktivitesi kaydedildi: +20 XP');
    } catch (e) {
      LogService.e('❌ Post aktivite kayıt hatası', e);
    }
  }

  /// When a post is liked
  static Future<void> onLikeCreated() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _pointsService.addPoints(
        userId: userId,
        points: ScoringConstants.likePoints,
        source: 'like',
        description: 'Beğeni yaptı',
      );

      await _missionService.updateMissionProgress(
        userId: userId,
        missionId: 2, // "5 Beğeni Yap" görevi
        increment: 1,
      );

      LogService.i('✅ Like aktivitesi kaydedildi: +2 XP');
    } catch (e) {
      LogService.e('❌ Like aktivite kayıt hatası', e);
    }
  }

  /// When a post is comment
  static Future<void> onCommentCreated() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _pointsService.addPoints(
        userId: userId,
        points: ScoringConstants.commentPoints,
        source: 'comment',
        description: 'Yorum yaptı',
      );

      await _missionService.updateMissionProgress(
        userId: userId,
        missionId: 3, // "3 Yorum At" görevi
        increment: 1,
      );

      // Haftalık görev (50 yorum)
      await _missionService.updateMissionProgress(
        userId: userId,
        missionId: 5, // "Sosyal Kelebek" görevi
        increment: 1,
      );

      LogService.i('✅ Comment aktivitesi kaydedildi: +5 XP');
    } catch (e) {
      LogService.e('❌ Comment aktivite kayıt hatası', e);
    }
  }

  /// Streak (daily streak) bonus
  static Future<void> onStreakMilestone(int streakDays) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Her 7 günde bir bonus
    if (streakDays % 7 == 0) {
      try {
        final bonusPoints = streakDays * 5; // 7 gün = 35 puan, 14 gün = 70 puan...

        await _pointsService.addPoints(
          userId: userId,
          points: bonusPoints,
          source: 'streak',
          description: '$streakDays günlük seri bonusu',
        );

        LogService.i('✅ Streak bonusu: +$bonusPoints XP');
      } catch (e) {
        LogService.e('❌ Streak bonus hatası', e);
      }
    }
  }

  /// Haftalık en çok takipçi kazanan ödülü
  static Future<void> onWeeklyTopFollower(int position) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      int points = 0;

      if (position == 1) {
        points = ScoringConstants.weeklyTop1;
      } else if (position == 2) {
        points = ScoringConstants.weeklyTop2;
      } else if (position == 3) {
        points = ScoringConstants.weeklyTop3;
      }

      if (points > 0) {
        await _pointsService.addPoints(
          userId: userId,
          points: points,
          source: 'weekly_top',
          description: 'Haftanın en çok takipçi kazananı #$position',
        );

        LogService.i('✅ Haftalık ödül: +$points XP');
      }
    } catch (e) {
      LogService.e('❌ Haftalık ödül hatası', e);
    }
  }
}
