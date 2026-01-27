import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/services/points_service.dart';

// ============================================================================
// LEADERBOARD STATE
// ============================================================================

class LeaderboardState {
  final List<Map<String, dynamic>> leaderboard;
  final String period; // 'all_time', 'weekly', 'monthly'
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    this.leaderboard = const [],
    this.period = 'all_time',
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<Map<String, dynamic>>? leaderboard,
    String? period,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      leaderboard: leaderboard ?? this.leaderboard,
      period: period ?? this.period,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================================================
// LEADERBOARD NOTIFIER
// ============================================================================

class LeaderboardNotifier extends Notifier<LeaderboardState> {
  final _pointsService = PointsService();

  @override
  LeaderboardState build() {
    _loadLeaderboard();
    return const LeaderboardState();
  }

  /// Leaderboard yükle
  Future<void> _loadLeaderboard() async {
    state = state.copyWith(isLoading: true);

    try {
      final leaderboard = await _pointsService.getLeaderboard(
        limit: 100,
        period: state.period,
      );

      state = state.copyWith(
        leaderboard: leaderboard,
        isLoading: false,
      );

      LogService.i('✅ Leaderboard yüklendi: ${leaderboard.length} kullanıcı');
    } catch (e) {
      LogService.e('❌ Leaderboard yükleme hatası', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Liderlik tablosu yüklenemedi',
      );
    }
  }

  /// Period değiştir
  Future<void> changePeriod(String period) async {
    if (state.period == period) return;

    state = state.copyWith(period: period);
    await _loadLeaderboard();
  }

  /// Yenile
  Future<void> refresh() async {
    await _loadLeaderboard();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final leaderboardProvider = NotifierProvider<LeaderboardNotifier, LeaderboardState>(() {
  return LeaderboardNotifier();
});
