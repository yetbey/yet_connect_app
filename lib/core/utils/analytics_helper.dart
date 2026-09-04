// lib/core/utils/analytics_helper.dart

import 'package:yet_x_app/core/utils/logger_service.dart';

class AnalyticsHelper {
  static void _track(String event, [Map<String, dynamic>? params]) {
    LogService.d('📊 [Analytics] $event ${params ?? ''}');
  }

  // --- USER EVENTS ---
  static Future<void> logSignUp(String method) async => _track('sign_up', {'method': method});
  static Future<void> logLogin(String method) async => _track('login', {'method': method});
  static Future<void> logLogout() async => _track('logout');

  // --- POST EVENTS ---
  static Future<void> logPostCreated({
    required String postId,
    required String contentType,
    int? tagCount,
  }) async => _track('post_created', {
    'post_id': postId,
    'content_type': contentType,
    'tag_count': tagCount ?? 0,
  });

  static Future<void> logPostLiked(String postId) async =>
      _track('post_liked', {'post_id': postId});

  static Future<void> logPostShared(String postId) async =>
      _track('post_shared', {'post_id': postId});

  static Future<void> logPostDeleted(String postId) async =>
      _track('post_deleted', {'post_id': postId});

  // --- COMMENT EVENTS ---
  static Future<void> logCommentAdded(String postId) async =>
      _track('comment_added', {'post_id': postId});

  // --- SOCIAL EVENTS ---
  static Future<void> logUserFollowed(String targetUserId) async =>
      _track('user_followed', {'target_user_id': targetUserId});

  static Future<void> logUserUnfollowed(String targetUserId) async =>
      _track('user_unfollowed', {'target_user_id': targetUserId});

  // --- PROFILE EVENTS ---
  static Future<void> logProfileViewed(String userId) async =>
      _track('profile_viewed', {'user_id': userId});

  static Future<void> logProfileUpdated() async => _track('profile_updated');
  static Future<void> logProfileImageUpdated() async => _track('profile_image_updated');

  // --- SEARCH EVENTS ---
  static Future<void> logSearch(String query, String type) async =>
      _track('search', {'query': query, 'type': type});

  // --- TAG EVENTS ---
  static Future<void> logTagFollowed(String tag) async =>
      _track('tag_followed', {'tag_name': tag});

  static Future<void> logTagViewed(String tag) async =>
      _track('tag_viewed', {'tag_name': tag});

  // --- CHAT EVENTS ---
  static Future<void> logMessageSent(String chatId) async =>
      _track('message_sent', {'chat_id': chatId});

  static Future<void> logChatOpened(String chatId) async =>
      _track('chat_opened', {'chat_id': chatId});

  // --- NAVIGATION EVENTS ---
  static Future<void> logScreenView(String screenName) async =>
      _track('screen_view', {'screen': screenName});

  // --- APP EVENTS ---
  static Future<void> logAppOpen() async => _track('app_open');
  static Future<void> logTutorialComplete() async => _track('tutorial_complete');

  // --- ERROR EVENTS ---
  static Future<void> logError({
    required String errorType,
    required String context,
    String? severity,
  }) async => _track('app_error', {
    'error_type': errorType,
    'context': context,
    'severity': severity ?? 'medium',
  });

  // --- CUSTOM EVENTS ---
  static Future<void> logCustomEvent(
      String eventName,
      Map<String, Object>? parameters,
      ) async => _track(eventName, parameters);

  // --- USER PROPERTIES ---
  static Future<void> setUserId(String userId) async =>
      LogService.d('📊 [Analytics] setUserId: $userId');

  static Future<void> setUserProperty(String name, String value) async =>
      LogService.d('📊 [Analytics] setUserProperty: $name=$value');

  static Future<void> clearUserId() async =>
      LogService.d('📊 [Analytics] clearUserId');
}