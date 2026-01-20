// lib/core/utils/analytics_helper.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsHelper {
  static final _analytics = FirebaseAnalytics.instance;

  // --- USER EVENTS ---

  static Future<void> logSignUp(String method) async {
    if (!kReleaseMode) return;
    await _analytics.logSignUp(signUpMethod: method);
  }

  static Future<void> logLogin(String method) async {
    if (!kReleaseMode) return;
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logLogout() async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(name: 'logout');
  }

  // --- POST EVENTS ---

  static Future<void> logPostCreated({
    required String postId,
    required String contentType, // 'text', 'image', 'video'
    int? tagCount,
  }) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'post_created',
      parameters: <String, Object>{
        'post_id': postId,
        'content_type': contentType,
        'tag_count': tagCount ?? 0,
      },
    );
  }

  static Future<void> logPostLiked(String postId) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'post_liked',
      parameters: <String, Object>{'post_id': postId},
    );
  }

  static Future<void> logPostShared(String postId) async {
    if (!kReleaseMode) return;
    await _analytics.logShare(
      contentType: 'post',
      itemId: postId,
      method: 'app_share',
    );
  }

  static Future<void> logPostDeleted(String postId) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'post_deleted',
      parameters: <String, Object>{'post_id': postId},
    );
  }

  // --- COMMENT EVENTS ---

  static Future<void> logCommentAdded(String postId) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'comment_added',
      parameters: <String, Object>{'post_id': postId},
    );
  }

  // --- SOCIAL EVENTS ---

  static Future<void> logUserFollowed(String targetUserId) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'user_followed',
      parameters: <String, Object>{'target_user_id': targetUserId},
    );
  }

  static Future<void> logUserUnfollowed(String targetUserId) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'user_unfollowed',
      parameters: <String, Object>{'target_user_id': targetUserId},
    );
  }

  // --- PROFILE EVENTS ---

  static Future<void> logProfileViewed(String userId) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'profile_viewed',
      parameters: <String, Object>{'user_id': userId},
    );
  }

  static Future<void> logProfileUpdated() async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(name: 'profile_updated');
  }

  static Future<void> logProfileImageUpdated() async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(name: 'profile_image_updated');
  }

  // --- SEARCH EVENTS ---

  static Future<void> logSearch(String query, String type) async {
    if (!kReleaseMode) return;
    await _analytics.logSearch(
      searchTerm: query,
      parameters: <String, Object>{'search_type': type}, // 'user', 'tag', 'post'
    );
  }

  // --- TAG EVENTS ---

  static Future<void> logTagFollowed(String tag) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'tag_followed',
      parameters: <String, Object>{'tag_name': tag},
    );
  }

  static Future<void> logTagViewed(String tag) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'tag_viewed',
      parameters: <String, Object>{'tag_name': tag},
    );
  }

  // --- CHAT EVENTS ---

  static Future<void> logMessageSent(String chatId) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: <String, Object>{'chat_id': chatId},
    );
  }

  static Future<void> logChatOpened(String chatId) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'chat_opened',
      parameters: <String, Object>{'chat_id': chatId},
    );
  }

  // --- NAVIGATION EVENTS ---

  static Future<void> logScreenView(String screenName) async {
    if (!kReleaseMode) return;
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // --- APP EVENTS ---

  static Future<void> logAppOpen() async {
    if (!kReleaseMode) return;
    await _analytics.logAppOpen();
  }

  static Future<void> logTutorialComplete() async {
    if (!kReleaseMode) return;
    await _analytics.logTutorialComplete();
  }

  // --- ERROR EVENTS ---

  static Future<void> logError({
    required String errorType,
    required String context,
    String? severity,
  }) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: 'app_error',
      parameters: <String, Object>{
        'error_type': errorType,
        'context': context,
        'severity': severity ?? 'medium',
      },
    );
  }

  // --- CUSTOM EVENTS ---

  static Future<void> logCustomEvent(
      String eventName,
      Map<String, Object>? parameters, // ✅ Object olarak değiştirdik
      ) async {
    if (!kReleaseMode) return;
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }

  // --- USER PROPERTIES ---

  static Future<void> setUserId(String userId) async {
    if (!kReleaseMode) return;
    await _analytics.setUserId(id: userId);
  }

  static Future<void> setUserProperty(String name, String value) async {
    if (!kReleaseMode) return;
    await _analytics.setUserProperty(name: name, value: value);
  }

  static Future<void> clearUserId() async {
    if (!kReleaseMode) return;
    await _analytics.setUserId(id: null);
  }
}
