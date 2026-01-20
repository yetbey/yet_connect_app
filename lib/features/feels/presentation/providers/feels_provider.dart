import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';

// ============================================================================
// FEELS STATE
// ============================================================================
class FeelsState {
  final int currentStreak;
  final String? selectedMood;
  final List<Map<String, dynamic>> dailyMissions;
  final int weeklyPoints;
  final int weeklyPointsTarget;
  final Map<String, dynamic>? dailyChallenge;
  final List<Map<String, dynamic>> liveEvents;
  final Map<String, dynamic>? userStats;
  final bool isLoading;
  final String? error;

  const FeelsState({
    this.currentStreak = 0,
    this.selectedMood,
    this.dailyMissions = const [],
    this.weeklyPoints = 0,
    this.weeklyPointsTarget = 150,
    this.dailyChallenge,
    this.liveEvents = const [],
    this.userStats,
    this.isLoading = false,
    this.error,
  });

  FeelsState copyWith({
    int? currentStreak,
    String? selectedMood,
    List<Map<String, dynamic>>? dailyMissions,
    int? weeklyPoints,
    int? weeklyPointsTarget,
    Map<String, dynamic>? dailyChallenge,
    List<Map<String, dynamic>>? liveEvents,
    Map<String, dynamic>? userStats,
    bool? isLoading,
    String? error,
  }) {
    return FeelsState(
      currentStreak: currentStreak ?? this.currentStreak,
      selectedMood: selectedMood ?? this.selectedMood,
      dailyMissions: dailyMissions ?? this.dailyMissions,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      weeklyPointsTarget: weeklyPointsTarget ?? this.weeklyPointsTarget,
      dailyChallenge: dailyChallenge ?? this.dailyChallenge,
      liveEvents: liveEvents ?? this.liveEvents,
      userStats: userStats ?? this.userStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================================================
// FEELS NOTIFIER
// ============================================================================
class FeelsNotifier extends Notifier<FeelsState> {
  final _supabase = Supabase.instance.client;

  @override
  FeelsState build() {
    Future.microtask(() => _loadFeelsData());
    return const FeelsState();
  }

  /// Tüm Feels verilerini yükle
  Future<void> _loadFeelsData() async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.wait([
        _loadStreak(),
        _loadDailyMissions(),
        _loadWeeklyPoints(),
        _loadUserStats(),
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

  /// Kullanıcının günlük giriş serisini hesapla
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

  /// Günlük görevleri yükle
  Future<void> _loadDailyMissions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Bugünkü aktiviteleri çek
      final posts = await _supabase
          .from('posts')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', todayStart.toIso8601String());

      final likes = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId)
          .gte('created_at', todayStart.toIso8601String());

      final comments = await _supabase
          .from('comments')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', todayStart.toIso8601String());

      // Görevleri oluştur
      final missions = [
        {
          'title': 'İlk Gönderi',
          'progress': (posts.length / 1).clamp(0.0, 1.0),
          'current': posts.length,
          'target': 1,
          'reward': '10 XP',
          'icon': 'edit',
          'color': 0xFF667eea,
        },
        {
          'title': '5 Beğeni Yap',
          'progress': (likes.length / 5).clamp(0.0, 1.0),
          'current': likes.length,
          'target': 5,
          'reward': '5 XP',
          'icon': 'favorite',
          'color': 0xFFFF6B6B,
        },
        {
          'title': '3 Yorum At',
          'progress': (comments.length / 3).clamp(0.0, 1.0),
          'current': comments.length,
          'target': 3,
          'reward': '15 XP',
          'icon': 'comment',
          'color': 0xFF4FACFE,
        },
      ];

      state = state.copyWith(dailyMissions: missions);
      LogService.i('✅ Günlük görevler yüklendi');
    } catch (e) {
      LogService.e('❌ Günlük görev yükleme hatası', e);
    }
  }

  /// Haftalık puan ilerlemesini yükle
  Future<void> _loadWeeklyPoints() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);

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
      final points = (posts.length * 20) + (likes.length * 2) + (comments.length * 5);

      state = state.copyWith(weeklyPoints: points);
      LogService.i('✅ Haftalık puan yüklendi: $points');
    } catch (e) {
      LogService.e('❌ Haftalık puan yükleme hatası', e);
    }
  }

  /// Kullanıcı istatistiklerini yükle
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

  /// Mood (ruh hali) seçimini kaydet
  Future<void> selectMood(String mood) async {
    state = state.copyWith(selectedMood: mood);

    // TODO: Supabase'e mood kaydı eklenebilir
    // Şimdilik sadece local state'te tutalım
    LogService.i('✅ Mood seçildi: $mood');
  }

  /// Verileri yenile
  Future<void> refresh() async {
    await _loadFeelsData();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
final feelsProvider = NotifierProvider<FeelsNotifier, FeelsState>(() {
  return FeelsNotifier();
});
