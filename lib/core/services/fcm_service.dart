import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/constants/supabase_tables.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'dart:async';
import 'dart:io' show Platform;
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
  StreamSubscription<String>? _tokenRefreshSub;
  String? _registeredToken;

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
      await syncToken();
      // Token yenilenme dinleyicisi (bir kez kurulur)
      _tokenRefreshSub ??= _fcm.onTokenRefresh.listen(_registerToken);
    } catch (e) {
      LogService.e('❌ FCM token hatası: $e');
    }
  }

  Future<void> syncToken({int retries = 3}) async {
    for (var attempt = 0; attempt < retries; attempt++) {
      try {
        final token = await _fcm.getToken();
        if (token != null) {
          await _registerToken(token);
          return;
        }
      } catch (e) {
        LogService.w('⚠️ FCM token alınamadı (deneme ${attempt + 1}/$retries): $e');
      }
      await Future.delayed(Duration(seconds: 2 << attempt)); // 2s, 4s, 8s
    }
    LogService.e('❌ FCM token senkronu başarısız oldu');
  }

  Future<void> _registerToken(String token) async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;

    try {
      await client.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': Platform.isIOS ? 'ios' : 'android',
      });
      _registeredToken = token;
      LogService.i('✅ FCM token kaydedildi');
    } catch (e) {
      LogService.e('❌ Token kaydetme hatası: $e');
    }
  }

  /// Çıkıştan ÖNCE çağır (oturum hâlâ açıkken).
  Future<void> unregisterToken() async {
    final client = Supabase.instance.client;

    // Firebase'e ulaşılamasa bile en son kaydettiğimiz token'ı kullan.
    String? token = _registeredToken;
    try {
      token = await _fcm.getToken() ?? token;
    } catch (e) {
      LogService.w('⚠️ Token alınamadı, kayıtlı olan kullanılacak: $e');
    }

    if (token != null && client.auth.currentUser != null) {
      try {
        await client.rpc('unregister_device_token', params: {'p_token': token});
        LogService.i('🗑️ Token sunucudan silindi');
      } catch (e) {
        LogService.e('❌ Token sunucudan silinemedi: $e');
      }
    }
    _registeredToken = null;

    // Cihazda yeni token üretmek önemli ama kritik değil.
    try {
      await _fcm.deleteToken();
    } catch (e) {
      LogService.w('⚠️ Cihaz token\'ı silinemedi (önemli değil): $e');
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
  Future<void> clearToken() => unregisterToken();
}
