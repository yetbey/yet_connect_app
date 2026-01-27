import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/features/feed/data/post_repository.dart';

// Reels State
class ReelsState {
  final List<PostModel> videos;
  final bool isLoading;
  final bool hasMore;
  final int currentIndex;

  const ReelsState({
    required this.videos,
    this.isLoading = false,
    this.hasMore = true,
    this.currentIndex = 0,
});

  ReelsState copyWith({
    List<PostModel>? videos,
    bool? isLoading,
    bool? hasMore,
    int? currentIndex,
}) {
    return ReelsState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

// Reels Notifier
class ReelsNotifier extends Notifier<ReelsState> {
  late final PostRepository _repository = ref.read(postRepositoryProvider);
  static const int _limit = 10;

  @override
  ReelsState build() {
    return const ReelsState(videos: []);
  }

  /// Sadece video_url olan reels videolarını yükle
  Future<void> fetchReels({bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;

    if (isRefresh) {
      state = const ReelsState(videos: [], isLoading: true);
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true);
    }

    ErrorHandler.log('Fetching reels', data: {
      'isRefresh': isRefresh,
      'currentCount': state.videos.length,
    });

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final start = state.videos.length;
      final end = start + _limit - 1;

      // Only has video_url
      final newVideos = await _repository.fetchFeed(start: start, end: end, onlyFollowing: false, currentUserId: currentUserId);

      // Video filter
      final filteredVideos = newVideos.where((post) => post.videoUrl != null && post.videoUrl!.isNotEmpty).toList();
      
      ErrorHandler.log('Reels fetched', data: {
        'count': filteredVideos.length,
        'hasMore': filteredVideos.length >= _limit,
      });

      state = state.copyWith(
        videos: isRefresh ? filteredVideos : [...state.videos, ...filteredVideos],
        isLoading: false,
        hasMore: filteredVideos.length >= _limit,
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Fetch Reels',
        severity: ErrorSeverity.medium,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// Update the video index
  void updateCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);

    // Sayfa sonuna yaklaşıldığında otomatik yükle
    if (index >= state.videos.length - 3 && state.hasMore && !state.isLoading) {
      fetchReels();
    }
  }

  /// Post GÜncelle
  void updateVideo(PostModel updatedPost) {
    final index = state.videos.indexWhere((v) => v.id == updatedPost.id);
    if (index != -1) {
      final newVideos = List<PostModel>.from(state.videos);
      newVideos[index] = updatedPost;
      state = state.copyWith(videos: newVideos);
    }
  }
}

final reelsProvider = NotifierProvider<ReelsNotifier, ReelsState>(() {
 return ReelsNotifier();
});