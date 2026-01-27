import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/services/points_service.dart';
import 'package:yet_x_app/features/gamification/data/services/mission_service.dart';

class ActivityTracker {
  static final _pointsService = PointsService();
  static final _missionService = MissionService();
  static final _supabase = Supabase.instance.client;

  /// Post paylaştığında
  static Future<void> onPostCreated() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Puan ekle
      await _pointsService.addPoints(
        userId: userId,
        points: 20,
        source: 'post',
        description: 'Gönderi paylaştı',
      );

      // Görev ilerlemesini güncelle
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

  /// Beğeni yaptığında
  static Future<void> onLikeCreated() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Puan ekle
      await _pointsService.addPoints(
        userId: userId,
        points: 2,
        source: 'like',
        description: 'Beğeni yaptı',
      );

      // Görev ilerlemesini güncelle
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

  /// Yorum yaptığında
  static Future<void> onCommentCreated() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Puan ekle
      await _pointsService.addPoints(
        userId: userId,
        points: 5,
        source: 'comment',
        description: 'Yorum yaptı',
      );

      // Görev ilerlemesini güncelle
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

  /// Streak (günlük seri) bonusu
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
        points = 100;
      } else if (position == 2) {
        points = 50;
      } else if (position == 3) {
        points = 25;
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
