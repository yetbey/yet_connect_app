import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/core/constants/scoring_constants.dart';
import 'package:yet_x_app/features/gamification/data/services/daily_challenge_service.dart';
import 'package:yet_x_app/features/gamification/data/services/points_service.dart';
import 'package:yet_x_app/features/gamification/data/services/mission_service.dart';

class ActivityTracker {
  static final _pointsService = PointsService();
  static final _missionService = MissionService();
  static final _dailyChallengeService = DailyChallengeService();
  static final _supabase = Supabase.instance.client;

  /// When a post is shared
  static Future<void> onPostCreated({List<String>? tags}) async {
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
        missionId: 1,
        increment: 1,
      );

      await _missionService.updateMissionProgress(
        userId: userId,
        missionId: 4,
        increment: 1,
      );

      // Günlük challenge etiketiyle eşleşiyorsa bonus puan ver
      if (tags != null && tags.isNotEmpty) {
        await _checkDailyChallengeReward(userId, tags);
      }

      LogService.i('✅ Post aktivitesi kaydedildi: +20 XP');
    } catch (e) {
      LogService.e('❌ Post aktivite kayıt hatası', e);
    }
  }

  static Future<void> _checkDailyChallengeReward(
      String userId,
      List<String> tags,
      ) async {
    try {
      final challenge = await _dailyChallengeService.getTodayChallenge();
      if (challenge == null) return;
      if (!tags.contains(challenge.tagName)) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final existingReward = await _supabase
          .from('point_history')
          .select('id')
          .eq('user_id', userId)
          .eq('source', 'daily_challenge')
          .gte('created_at', startOfDay.toIso8601String())
          .limit(1);

      if ((existingReward as List).isNotEmpty) {
        LogService.i('ℹ️ Günlük challenge ödülü bugün zaten verildi');
        return;
      }

      await _pointsService.addPoints(
        userId: userId,
        points: challenge.rewardPoints,
        source: 'daily_challenge',
        description: '${challenge.themeTitle} challenge\'ına katıldı',
      );

      LogService.i('🎉 Günlük challenge ödülü: +${challenge.rewardPoints} XP');
    } catch (e) {
      LogService.e('❌ Günlük challenge ödül hatası', e);
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
