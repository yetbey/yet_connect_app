import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/features/story/data/models/story_model.dart';
import 'package:yet_x_app/features/story/data/repositories/story_repository.dart';
import 'dart:io';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository(Supabase.instance.client);
});

// Following story'leri
final followingStoriesProvider = FutureProvider<List<UserStoryGroup>>((ref) async {
  final repository = ref.watch(storyRepositoryProvider);
  final currentUser = ref.watch(userProvider).currentUser; // ✅ .currentUser

  if (currentUser == null) return [];

  return repository.getFollowingStories(currentUser.id);
});

// Belirli kullanıcının story'leri
final userStoriesProvider = FutureProvider.family<List<StoryModel>, String>((ref, userId) async {
  final repository = ref.watch(storyRepositoryProvider);
  final currentUser = ref.watch(userProvider).currentUser; // ✅ .currentUser

  return repository.getUserStories(userId, currentUser?.id);
});

// Story oluşturma state'i
class CreateStoryState {
  final bool isLoading;
  final String? error;
  final StoryModel? createdStory;

  const CreateStoryState({
    this.isLoading = false,
    this.error,
    this.createdStory,
  });

  CreateStoryState copyWith({
    bool? isLoading,
    String? error,
    StoryModel? createdStory,
  }) {
    return CreateStoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdStory: createdStory ?? this.createdStory,
    );
  }
}

class CreateStoryNotifier extends StateNotifier<CreateStoryState> {
  final StoryRepository _repository;

  CreateStoryNotifier(this._repository) : super(const CreateStoryState());

  Future<void> createStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
    File? thumbnailFile,
    int? duration,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final story = await _repository.createStory(
        userId: userId,
        mediaFile: mediaFile,
        mediaType: mediaType,
        thumbnailFile: thumbnailFile,
        duration: duration,
      );

      state = state.copyWith(isLoading: false, createdStory: story);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const CreateStoryState();
  }
}

final createStoryProvider = StateNotifierProvider<CreateStoryNotifier, CreateStoryState>((ref) {
  final repository = ref.watch(storyRepositoryProvider);
  return CreateStoryNotifier(repository);
});
