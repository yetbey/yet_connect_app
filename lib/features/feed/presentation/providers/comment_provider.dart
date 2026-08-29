import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/analytics_helper.dart';
import 'package:yet_x_app/features/feed/data/models/comment_model.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/features/feels/presentation/providers/feels_provider.dart';
import 'package:yet_x_app/features/gamification/data/services/activity_tracker.dart';
import 'package:yet_x_app/features/gamification/presentation/providers/points_provider.dart'; // ✅ EKLE

class CommentsState {
  final List<CommentModel> comments;
  final bool isLoading;

  CommentsState({required this.comments, this.isLoading = false});

  CommentsState copyWith({List<CommentModel>? comments, bool? isLoading}) {
    return CommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CommentsNotifier extends FamilyNotifier<CommentsState, String> {
  final _supabase = Supabase.instance.client;

  @override
  CommentsState build(String postId) {
    return CommentsState(comments: []);
  }

  Future<void> fetchComments() async {
    final postId = arg;
    state = state.copyWith(isLoading: true);

    // ✅ Breadcrumb log
    ErrorHandler.log('Fetching comments', data: {'postId': postId});

    try {
      final data = await _supabase
          .from('comments')
          .select('''
            *, profiles(*)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final List<CommentModel> fetchedComments = (data as List)
          .map((json) => CommentModel.fromJson(json))
          .toList();

      ErrorHandler.log('Comments fetched', data: {'count': fetchedComments.length});
      state = state.copyWith(comments: fetchedComments, isLoading: false);
    } catch (e, stackTrace) {
      // ✅ Log error
      LogService.e('Yorumlar getirilirken bir hata oluştu.', e, stackTrace);

      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Fetch Comments',
        severity: ErrorSeverity.medium,
        userAction: 'Loading comments',
        metadata: {'postId': postId},
      );

      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addComment(String content) async {
    final postId = arg;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || content.isEmpty) return;

    // ✅ Breadcrumb log
    ErrorHandler.log('Adding comment', data: {
      'postId': postId,
      'contentLength': content.length,
    });

    try {
      final response = await _supabase
          .from('comments')
          .insert({'post_id': postId, 'user_id': userId, 'content': content})
          .select('''
            *, profiles(*)
          ''')
          .single();

      final newComment = CommentModel.fromJson(response);
      state = state.copyWith(comments: [...state.comments, newComment]);

      ErrorHandler.log('Comment added successfully');
      await AnalyticsHelper.logCommentAdded(postId);

      await ActivityTracker.onCommentCreated();

      ref.read(pointsProvider.notifier).refreshPoints();
      ref.read(feelsProvider.notifier).refresh();

    } catch (e, stackTrace) {
      // ✅ Log error
      LogService.e('Yorum eklenirken bir hata oluştu.', e, stackTrace);

      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Add Comment',
        severity: ErrorSeverity.medium,
        userAction: 'Posting comment',
        metadata: {
          'postId': postId,
          'contentLength': content.length,
        },
      );
    }
  }
}

final commentsProvider =
NotifierProvider.family<CommentsNotifier, CommentsState, String>(() {
  return CommentsNotifier();
});
