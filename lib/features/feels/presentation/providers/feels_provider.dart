import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/services/mission_service.dart';
import 'package:yet_x_app/features/gamification/data/services/points_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ============================================================================
// FEELS STATE
// ============================================================================
class FeelsState {
  final int currentStreak;
  final int? leaderboardPosition;
  final int? leaderboardWeeklyPoints;
  final String? selectedMood;
  final String? aiMessage;
  final bool isAiLoading;
  final List<Map<String, dynamic>> dailyMissions;
  final int weeklyPoints;
  final int weeklyPointsTarget;
  final Map<String, dynamic>? dailyChallenge;
  final List<Map<String, dynamic>> liveEvents;
  final Map<String, dynamic>? userStats;
  final bool isLoading;
  final String? error;
  final int completedMissionsCount;
  final int totalMissionsCount;

  const FeelsState({
    this.currentStreak = 0,
    this.leaderboardPosition,
    this.leaderboardWeeklyPoints,
    this.selectedMood,
    this.aiMessage,
    this.isAiLoading = false,
    this.dailyMissions = const [],
    this.weeklyPoints = 0,
    this.weeklyPointsTarget = 150,
    this.dailyChallenge,
    this.liveEvents = const [],
    this.userStats,
    this.isLoading = false,
    this.error,
    this.completedMissionsCount = 0,
    this.totalMissionsCount = 0,
  });

  FeelsState copyWith({
    int? currentStreak,
    int? leaderboardPosition,
    int? leaderboardWeeklyPoints,
    String? selectedMood,
    String? aiMessage,
    bool? isAiLoading,
    List<Map<String, dynamic>>? dailyMissions,
    int? weeklyPoints,
    int? weeklyPointsTarget,
    Map<String, dynamic>? dailyChallenge,
    List<Map<String, dynamic>>? liveEvents,
    Map<String, dynamic>? userStats,
    bool? isLoading,
    String? error,
    int? completedMissionsCount,
    int? totalMissionsCount,
  }) {
    return FeelsState(
      currentStreak: currentStreak ?? this.currentStreak,
      leaderboardPosition: leaderboardPosition ?? this.leaderboardPosition,
      leaderboardWeeklyPoints: leaderboardWeeklyPoints ?? this.leaderboardWeeklyPoints,
      selectedMood: selectedMood ?? this.selectedMood,
      aiMessage: aiMessage ?? this.aiMessage,
      isAiLoading: isAiLoading ?? this.isAiLoading,
      dailyMissions: dailyMissions ?? this.dailyMissions,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      weeklyPointsTarget: weeklyPointsTarget ?? this.weeklyPointsTarget,
      dailyChallenge: dailyChallenge ?? this.dailyChallenge,
      liveEvents: liveEvents ?? this.liveEvents,
      userStats: userStats ?? this.userStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      completedMissionsCount: completedMissionsCount ?? this.completedMissionsCount,
      totalMissionsCount: totalMissionsCount ?? this.totalMissionsCount,
    );
  }
}

// ============================================================================
// FEELS NOTIFIER
// ============================================================================
class FeelsNotifier extends Notifier<FeelsState> {
  final _supabase = Supabase.instance.client;
  final _pointsService = PointsService();
  final _missionService = MissionService();

  @override
  FeelsState build() {
    Future.microtask(() => _loadFeelsData());
    return const FeelsState();
  }

  Future<void> _loadFeelsData() async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.wait([
        _loadStreak(),
        _loadDailyMissions(),
        _loadWeeklyPoints(),
        _loadUserStats(),
        _loadLeaderboardPosition(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Load Feels Data',
        severity: ErrorSeverity.medium,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Veriler yüklenirken bir hata oluştu',
      );
    }
  }

  Future<void> _loadLeaderboardPosition() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final leaderboard = await _pointsService.getLeaderboard(
        limit: 1000,
        period: 'weekly',
      );

      final entry = leaderboard.firstWhere(
            (e) => e['user_id'] == userId,
        orElse: () => <String, dynamic>{},
      );

      if (entry.isNotEmpty){
        state = state.copyWith(
          leaderboardPosition: entry['rank_position'] as int?,
          leaderboardWeeklyPoints: entry['total_points'] as int?,
        );
      } else {
        state = state.copyWith(leaderboardWeeklyPoints: 0);
      }

      LogService.i('✅ Leaderboard pozisyonu yüklendi: #${entry['rank_position']}');
    } catch (e) {
      LogService.e('❌ Leaderboard pozisyonu yükleme hatası', e);
    }
  }

  Future<void> _loadStreak() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Son 30 günde paylaşılan postları çek
      final response = await _supabase
          .from('posts')
          .select('created_at')
          .eq('user_id', userId)
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          )
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        state = state.copyWith(currentStreak: 0);
        return;
      }

      // Ardışık günleri hesapla
      int streak = 0;
      DateTime? lastDate;

      for (var post in response) {
        final postDate = DateTime.parse(post['created_at'] as String);
        final postDay = DateTime(postDate.year, postDate.month, postDate.day);

        if (lastDate == null) {
          // İlk post
          final today = DateTime.now();
          final todayDay = DateTime(today.year, today.month, today.day);

          // Bugün veya dün paylaşım yapılmış mı kontrol et
          final diff = todayDay.difference(postDay).inDays;
          if (diff <= 1) {
            streak = 1;
            lastDate = postDay;
          } else {
            break; // Seri kopmuş
          }
        } else {
          // Bir önceki günle karşılaştır
          final diff = lastDate.difference(postDay).inDays;
          if (diff == 1) {
            streak++;
            lastDate = postDay;
          } else if (diff == 0) {
            // Aynı gün, devam et
            continue;
          } else {
            break; // Seri kopmuş
          }
        }
      }

      state = state.copyWith(currentStreak: streak);
      LogService.i('✅ Streak yüklendi: $streak');
    } catch (e) {
      LogService.e('❌ Streak yükleme hatası', e);
    }
  }

  Future<void> _loadDailyMissions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Yeni mission service'den görevleri al
      final missions = await _missionService.getMissions(
        type: 'daily',
        userId: userId,
      );

      final missionsList = missions
          .where((mission) => !mission.isCompleted)
          .map((mission) {
        return {
          'title': mission.title,
          'progress': mission.progress,
          'current': mission.currentProgress,
          'target': mission.target,
          'reward': '${mission.rewardPoints} XP',
          'icon': mission.icon ?? 'check_circle',
          'color': mission.colorValue.value,
        };
      }).toList();

      state = state.copyWith(
        dailyMissions: missionsList,
        completedMissionsCount: missions.length - missionsList.length,
        totalMissionsCount: missions.length,
      );
      LogService.i('✅ Günlük görevler yüklendi (${missionsList.length}/${missions.length})');
    } catch (e) {
      LogService.e('❌ Günlük görev yükleme hatası', e);
    }
  }

  Future<void> _loadWeeklyPoints() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final weekStart = DateTime.now().subtract(
        Duration(days: DateTime.now().weekday - 1),
      );
      final weekStartDay = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );

      // Bu haftaki aktiviteleri say
      final posts = await _supabase
          .from('posts')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', weekStartDay.toIso8601String());

      final likes = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId)
          .gte('created_at', weekStartDay.toIso8601String());

      final comments = await _supabase
          .from('comments')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', weekStartDay.toIso8601String());

      // Puan hesapla (Post: 20, Like: 2, Comment: 5)
      final points =
          (posts.length * 20) + (likes.length * 2) + (comments.length * 5);

      state = state.copyWith(weeklyPoints: points);
      LogService.i('✅ Haftalık puan yüklendi: $points');
    } catch (e) {
      LogService.e('❌ Haftalık puan yükleme hatası', e);
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Toplam post sayısı
      final postsCount = await _supabase
          .from('posts')
          .count()
          .eq('user_id', userId);

      // Toplam beğeni sayısı (kullanıcının postlarına gelen)
      final likesResponse = await _supabase
          .from('post_likes')
          .select('post_id, posts!inner(user_id)')
          .eq('posts.user_id', userId);

      // Takipçi ve takip sayıları
      final followersCount = await _supabase
          .from('follows')
          .count()
          .eq('following_id', userId);

      final followingCount = await _supabase
          .from('follows')
          .count()
          .eq('follower_id', userId);

      final stats = {
        'posts': postsCount,
        'likes': likesResponse.length,
        'followers': followersCount,
        'following': followingCount,
      };

      state = state.copyWith(userStats: stats);
      LogService.i('✅ Kullanıcı istatistikleri yüklendi');
    } catch (e) {
      LogService.e('❌ İstatistik yükleme hatası', e);
    }
  }

  Future<void> selectMood(String mood) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(
      selectedMood: mood,
      isAiLoading: true,
      aiMessage: null,
    );

    try {
      await _supabase.from('profiles').update({
        'current_mood': mood,
      }).eq('id', userId);
      LogService.i('✅ Mood Supabase\'e kaydedildi: $mood');

      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty){
        throw Exception('Gemini Api Key bulunamadı!');
      }

      final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: apiKey);
      final prompt = '''
      Sen 'YET Connect' adlı sosyal medya uygulamasının samimi, zeki ve enerji dolu yapay zeka asistanısın. 
      Kullanıcı şu an "$mood" hissediyor.
      Görev: Kullanıcının bu ruh haline uygun, ona iyi hissettirecek veya empati kuracak kısa, dostça bir mesaj yaz.
      Kurallar: 
      - En fazla 2 cümle olsun.
      - Çok robotik konuşma, samimi bir arkadaş gibi ol.
      - Sonuna mutlaka uygun bir emoji ekle.
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      final aiText = response.text?.trim() ?? "Şu an ne diyeceğimi bilemedim ama yanındayım! 💛";

      state = state.copyWith(
        isAiLoading: false,
        aiMessage: aiText,
      );

    } catch (e) {
      LogService.e('❌ Mood kaydetme/AI hatası', e);
      state = state.copyWith(
        isAiLoading: false,
        aiMessage: "Şu an bağlantımda bir sorun var ama $mood hissettiğini not aldım! ✨",
      );
    }
  }

  /// Verileri yenile
  Future<void> refresh() async {
    await _loadFeelsData();
  }

  // Görev tamamlama ve Puan ekleme
  Future<void> trackActivity(String activityType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Aktivite tipine göre görev ID'lerini belirle
      int? missionId;

      if (activityType == 'post') {
        missionId = 1; // "İlk Gönderi" görevi
      } else if (activityType == 'like') {
        missionId = 2; // "5 Beğeni Yap" görevi
      } else if (activityType == 'comment') {
        missionId = 3; // "3 Yorum At" görevi
      }

      if (missionId != null) {
        // Görev ilerlemesini güncelle
        await _missionService.updateMissionProgress(
          userId: userId,
          missionId: missionId,
          increment: 1,
        );

        // Günlük görevleri yeniden yükle
        await _loadDailyMissions();
      }
    } catch (e) {
      LogService.e('❌ Aktivite takip hatası', e);
    }
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
final feelsProvider = NotifierProvider<FeelsNotifier, FeelsState>(() {
  return FeelsNotifier();
});
