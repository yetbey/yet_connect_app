import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/constants/supabase_tables.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';

import '../../config/routes/app_routes.dart';
import '../../features/feed/data/models/post_model.dart';
import 'navigation_service.dart';

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  LogService.i('📩 Background message: ${message.messageId}');
  await FCMService.instance.showNotification(message);
}

class FCMService {
  static final FCMService instance = FCMService._();
  FCMService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// FCM servisini başlat
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // İzin iste (iOS için zorunlu)
      final settings = await _requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        LogService.w('⚠️ Bildirim izni reddedildi');
        return;
      }

      // Local notifications başlat
      await _initializeLocalNotifications();

      // FCM token al ve kaydet
      await _handleFCMToken();

      // Foreground mesajları dinle
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background tap handler
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Uygulama kapalıyken tıklanan bildirimi al
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Background message handler kaydet
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _initialized = true;
      LogService.i('✅ FCM servisi başlatıldı');
    } catch (e) {
      LogService.e('❌ FCM başlatma hatası: $e');
    }
  }

  /// İzin iste
  Future<NotificationSettings> _requestPermission() async {
    return await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
      announcement: false,
    );
  }

  /// Local notifications başlat
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Android notification channel oluştur
    const androidChannel = AndroidNotificationChannel(
      'yet_connect_high_importance',
      'Önemli Bildirimler',
      description: 'Yet Connect uygulaması için yüksek öncelikli bildirimler',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// FCM Token yönetimi
  Future<void> _handleFCMToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveFCMToken(token);
        LogService.i('📱 FCM Token: ${token.substring(0, 20)}...');
      }

      // Token yenilenme dinleyicisi
      _fcm.onTokenRefresh.listen(_saveFCMToken);
    } catch (e) {
      LogService.e('❌ FCM token hatası: $e');
    }
  }

  /// Token'ı Supabase'e kaydet
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);

      LogService.i('✅ FCM token kaydedildi');
    } catch (e) {
      LogService.e('❌ Token kaydetme hatası: $e');
    }
  }

  /// Foreground mesajları işle
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    LogService.i('📨 Foreground message: ${message.notification?.title}');
    await showNotification(message);
  }

  /// Bildirimi göster
  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'yet_connect_high_importance',
      'Önemli Bildirimler',
      channelDescription: 'Yet Connect uygulaması için yüksek öncelikli bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Bildirim tıklama işlemleri
  void _handleNotificationTap(RemoteMessage message) {
    LogService.i('👆 Bildirim tıklandı: ${message.data}');
    _navigateToScreen(message.data);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateToScreen(data);
    }
  }

  /// Ekran yönlendirmesi
  Future<void> _navigateToScreen(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final postId = data['post_id'] as String?;
    final senderId = data['sender_id'] as String?;

    if ((type == 'like' || type == 'comment') && postId != null && postId.isNotEmpty) {
      final supabase = Supabase.instance.client;
      final response = await supabase.from(postsTable.tableName).select('''
            *,
            profiles:profiles!posts_user_id_fkey(*),
            post_likes(count),
            comments(count),
            my_likes:post_likes(user_id)
          ''').eq(postsTable.id, postId).single();
      final modJson = Map<String, dynamic>.from(response);
      final post = PostModel.fromJson(modJson);
        NavigationService.toNamed(
          AppRoutes.detailedPost,
          arguments: {'post': post},
        );
    } else if (type == 'follow' && senderId != null && senderId.isNotEmpty) {
        NavigationService.toNamed(
          AppRoutes.profile,
          arguments: {'userId': senderId},
        );
    }
  }

  /// Token'ı temizle (Logout)
  Future<void> clearToken() async {
    try {
      await _fcm.deleteToken();
      LogService.i('🗑️ FCM token silindi');
    } catch (e) {
      LogService.e('❌ Token silme hatası: $e');
    }
  }
}
