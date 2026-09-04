import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/models/rank_model.dart';
import 'package:yet_x_app/features/gamification/data/models/user_points_model.dart';
import 'package:yet_x_app/features/gamification/data/services/points_service.dart';

// State
class PointsState {
  final bool isLoading;
  final String? error;
  final List<RankModel> allRanks;
  final UserPointsModel? userPoints;
  final RankModel? currentRank;
  final RankModel? nextRank;
  final int pointsToNextRank;

  PointsState({
    this.isLoading = false,
    this.error,
    this.allRanks = const [],
    this.userPoints,
    this.currentRank,
    this.nextRank,
    this.pointsToNextRank = 0,
  });

  PointsState copyWith({
    bool? isLoading,
    String? error,
    List<RankModel>? allRanks,
    UserPointsModel? userPoints,
    RankModel? currentRank,
    RankModel? nextRank,
    int? pointsToNextRank,
  }) {
    return PointsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      allRanks: allRanks ?? this.allRanks,
      userPoints: userPoints ?? this.userPoints,
      currentRank: currentRank ?? this.currentRank,
      nextRank: nextRank ?? this.nextRank,
      pointsToNextRank: pointsToNextRank ?? this.pointsToNextRank,
    );
  }
}

// Provider
final pointsProvider = NotifierProvider<PointsNotifier, PointsState>(() {
  return PointsNotifier();
});

// Notifier
class PointsNotifier extends Notifier<PointsState> {
  final _supabase = Supabase.instance.client;
  final _pointsService = PointsService();

  @override
  PointsState build() {
    // ✅ İlk state'i döndür
    final initialState = PointsState();

    // ✅ Asenkron yüklemeyi Future.microtask ile başlat
    Future.microtask(() => _loadUserPoints());

    return initialState;
  }

  Future<void> _loadUserPoints() async {
    final userId = _supabase.auth.currentUser?.id;
    LogService.i('🔍 POINTS PROVIDER: User ID: $userId');

    if (userId == null) {
      LogService.i('❌ POINTS PROVIDER: User ID null!');
      return;
    }

    // ✅ Artık state güvenle kullanılabilir
    state = state.copyWith(isLoading: true);

    try {
      // Rütbeleri yükle
      LogService.i('📥 POINTS PROVIDER: Fetching ranks...');
      final ranks = await _pointsService.getAllRanks();
      LogService.i('✅ POINTS PROVIDER: Ranks loaded: ${ranks.length}');

      // Kullanıcı puanlarını al
      LogService.i('📥 POINTS PROVIDER: Fetching user points...');
      final userPoints = await _pointsService.getUserPoints(userId);
      LogService.i('✅ POINTS PROVIDER: User points: ${userPoints?.totalPoints}');

      if (userPoints == null) {
        LogService.i('⚠️ POINTS PROVIDER: User points null, creating default...');

        // ✅ Kullanıcı kaydı yoksa oluştur
        await _pointsService.addPoints(
          userId: userId,
          points: 0,
          source: 'system',
          description: 'Hesap oluşturuldu',
        );

        // Tekrar dene
        final newUserPoints = await _pointsService.getUserPoints(userId);
        if (newUserPoints == null) {
          state = state.copyWith(
            isLoading: false,
            error: 'Puan bilgisi oluşturulamadı',
          );
          return;
        }

        _updateStateWithPoints(ranks, newUserPoints);
        return;
      }

      _updateStateWithPoints(ranks, userPoints);

    } catch (e, stack) {
      LogService.e('❌ POINTS PROVIDER: Error loading points', e, stack);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _updateStateWithPoints(List<RankModel> ranks, UserPointsModel userPoints) {
    // Mevcut rütbeyi bul
    final currentRank = ranks.firstWhere(
          (rank) => rank.name == userPoints.rank,
      orElse: () => ranks.first,
    );
    LogService.i('✅ POINTS PROVIDER: Current rank: ${currentRank.displayName}');

    // Bir sonraki rütbeyi bul
    final currentRankIndex = ranks.indexOf(currentRank);
    final nextRank = currentRankIndex < ranks.length - 1
        ? ranks[currentRankIndex + 1]
        : null;

    // Bir sonraki rütbeye kaç puan kaldığını hesapla
    final pointsToNextRank = nextRank != null
        ? nextRank.minPoints - userPoints.totalPoints
        : 0;

    state = PointsState(
      isLoading: false,
      allRanks: ranks,
      userPoints: userPoints,
      currentRank: currentRank,
      nextRank: nextRank,
      pointsToNextRank: pointsToNextRank,
    );

    LogService.i('✅ POINTS PROVIDER: State updated - ${userPoints.totalPoints} XP, ${currentRank.displayName}');
  }

  // Puanları yenile
  Future<void> refreshPoints() async {
    await _loadUserPoints();
  }

  // Puan ekle
  Future<void> addPoints({
    required int points,
    required String source,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _pointsService.addPoints(
        userId: userId,
        points: points,
        source: source,
        description: description,
      );

      // Puanları yenile
      await refreshPoints();
    } catch (e, stack) {
      LogService.e('❌ Error adding points', e, stack);
    }
  }
}
