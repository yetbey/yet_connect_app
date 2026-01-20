import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/constants/app_colors.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🌙 Arka Plan Bildirimi: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification Channel for Android 8+ it is necessary
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_important_channel', // id
        'High Importance Notifications', // title
        description: 'Önemli bildirimlerin gösterildiği kanal', // description
        importance: Importance.max,
        playSound: true,
      );

  /// Start Service
  Future<void> init() async {
    try {
      final NotificationSettings
      settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional:
            false, // ios için sessiz deneme izni - tam izin lazım bu o yüzden false
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        LogService.i('✅ Bildirim izni verildi.');
      } else {
        LogService.w('⚠️ Bildirim izni verilmedi veya kısıtlı.');
        return;
      }

      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        LogService.i('🔥 FCM Token: $fcmToken');
        _saveTokenToDatabase(fcmToken);
      }

      // Token yenilenirse dinle
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

      // Local Notifications ayarları
      await _setupLocalNotifications();

      // Arka planda handler tanımla
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Ön plan dinleyici
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Bildirime tıklama
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      LogService.e('❌ NotificationService init hatası', e);
    }
  }

  /// Local Notifications
  Future<void> _setupLocalNotifications() async {
    // Android Ayarı
    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Ayarı
    const darwinInitSettings = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: darwinInitSettings,
    );

    // Kanalı Android sistemine kaydet
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Uygulama içindeyken üstten çıkan bildirime tıklanırsa burası çalışır
        if (details.payload != null) {
          _handleDeepLink(details.payload!);
        }
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    LogService.i('☀️ Ön Plan Bildirimi: ${message.notification?.title}');

    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            color: AppColors.primary, // App color
          ),
        ),
        payload: message.data['route'], // Deep Link için payload taşıma
      );
    }
    // ref.read(notificationProvider.notifier).incrementBadge();
  }

  void _handleNotificationTap(RemoteMessage message) {
    LogService.i('👆 Bildirime tıklandı: ${message.data}');
    if (message.data.containsKey('route')) {
      _handleDeepLink(message.data['route']);
    }
  }

  void _handleDeepLink(String routePath) {
    // Burada NavigationService kullanarak yönlendirme yapacağız.
    // Örnek: "/post/123" veya "/chat/456"
    LogService.i('🔗 Yönlendiriliyor: $routePath');
    // NavigationService.instance.pushNamed(routePath); // Bunu daha sonra bağlayacağız
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 'profiles' tablosunda 'fcm_token' sütunu olduğunu varsayıyoruz.
      // Yoksa veritabanında oluşturacağız.
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);

      LogService.i('💾 FCM Token veritabanına kaydedildi.');
    } catch (e) {
      LogService.e('❌ Token kaydetme hatası', e);
    }
  }
}

// Global Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
