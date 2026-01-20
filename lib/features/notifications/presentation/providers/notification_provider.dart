import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/notifications/data/models/notification_model.dart';

final notificationProvider =
StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final int unreadCount;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.unreadCount = 0,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    int? unreadCount,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState()) {
    _initialize();
  }

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  Future<void> _initialize() async {
    await loadNotifications();
    _listenToRealtimeNotifications();
  }

  /// Bildirimleri yükle
  Future<void> loadNotifications() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('notifications')
          .select('''
            *,
            sender:profiles!sender_id(id, username, full_name, profile_image_url),
            post:posts(id, image_url)
          ''')
          .eq('receiver_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final notifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();

      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );

      LogService.i('✅ ${notifications.length} bildirim yüklendi');
    } catch (e) {
      LogService.e('❌ Bildirim yükleme hatası: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Realtime bildirimleri dinle
  void _listenToRealtimeNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _channel = _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: userId,
      ),
      callback: (payload) async {
        LogService.i('🔔 Yeni bildirim geldi');
        await _handleNewNotification(payload.newRecord);
      },
    )
        .subscribe();

    LogService.i('🎧 Realtime dinleyici aktif');
  }

  /// Yeni bildirim işle
  Future<void> _handleNewNotification(Map<String, dynamic> data) async {
    try {
      // Sender ve post bilgilerini al
      final enrichedData = await _supabase
          .from('notifications')
          .select('''
            *,
            sender:profiles!sender_id(id, username, full_name, profile_image_url),
            post:posts(id, image_url)
          ''')
          .eq('id', data['id'])
          .single();

      final notification = AppNotification.fromJson(enrichedData);

      state = state.copyWith(
        notifications: [notification, ...state.notifications],
        unreadCount: state.unreadCount + 1,
      );

      LogService.i('✅ Yeni bildirim eklendi: ${notification.message}');
    } catch (e) {
      LogService.e('❌ Bildirim işleme hatası: $e');
    }
  }

  /// Bildirimi okundu işaretle
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      // Güncel okunmamış sayısını hesapla
      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );

      LogService.i('✅ Bildirim okundu: $notificationId');
    } catch (e) {
      LogService.e('❌ Okundu işaretleme hatası: $e');
    }
  }

  /// Tüm bildirimleri okundu işaretle
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('receiver_id', userId)
          .eq('is_read', false);

      final updatedNotifications = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0, // Tümü okundu, sayı 0
      );

      LogService.i('✅ Tüm bildirimler okundu');
    } catch (e) {
      LogService.e('❌ Toplu okundu işaretleme hatası: $e');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// Helper: Okunmamış bildirim sayısı
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
