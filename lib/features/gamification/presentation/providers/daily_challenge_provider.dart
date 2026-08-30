import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/models/daily_challenge_model.dart';
import 'package:yet_x_app/features/gamification/data/services/daily_challenge_service.dart';

// ============================================================================
// DAILY CHALLENGE STATE
// ============================================================================
class DailyChallengeState {
  final DailyChallengeModel? challenge;
  final int participantCount;
  final bool hasParticipated;
  final bool isLoading;
  final String? error;

  const DailyChallengeState({
    this.challenge,
    this.participantCount = 0,
    this.hasParticipated = false,
    this.isLoading = false,
    this.error,
  });

  DailyChallengeState copyWith({
    DailyChallengeModel? challenge,
    int? participantCount,
    bool? hasParticipated,
    bool? isLoading,
    String? error,
  }) {
    return DailyChallengeState(
      challenge: challenge ?? this.challenge,
      participantCount: participantCount ?? this.participantCount,
      hasParticipated: hasParticipated ?? this.hasParticipated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================================================
// DAILY CHALLENGE NOTIFIER
// ============================================================================
class DailyChallengeNotifier extends Notifier<DailyChallengeState> {
  final _service = DailyChallengeService();
  final _supabase = Supabase.instance.client;

  @override
  DailyChallengeState build() {
    Future.microtask(() => _loadChallenge());
    return const DailyChallengeState();
  }

  Future<void> _loadChallenge() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final challenge = await _service.getTodayChallenge();

      if (challenge == null) {
        state = state.copyWith(isLoading: false, challenge: null);
        return;
      }

      final userId = _supabase.auth.currentUser?.id;

      final results = await Future.wait([
        _service.getTodayParticipantCount(challenge.tagName),
        if (userId != null)
          _service.hasUserParticipatedToday(challenge.tagName, userId)
        else
          Future.value(false),
      ]);

      state = state.copyWith(
        challenge: challenge,
        participantCount: results[0] as int,
        hasParticipated: results[1] as bool,
        isLoading: false,
      );

      LogService.i('✅ Günlük challenge yüklendi: ${challenge.themeTitle}');
    } catch (e) {
      LogService.e('❌ Günlük challenge provider hatası', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Challenge yüklenemedi',
      );
    }
  }

  Future<void> refresh() async {
    await _loadChallenge();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
final dailyChallengeProvider =
NotifierProvider<DailyChallengeNotifier, DailyChallengeState>(() {
  return DailyChallengeNotifier();
});