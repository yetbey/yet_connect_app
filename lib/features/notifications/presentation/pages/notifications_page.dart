import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/profile/presentation/pages/profile_page.dart';
import 'package:yet_x_app/features/notifications/data/models/notification_model.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/features/notifications/presentation/providers/notification_provider.dart';

class NotificationsPage extends ConsumerWidget {
  final String userId;
  const NotificationsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);
    final notifNotifier = ref.read(notificationProvider.notifier);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 500) {
          NavigationService.back();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Bildirimler'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          actions: [
            if (notifState.unreadCount > 0)
              IconButton(
                icon: const Icon(IconsaxPlusBold.task_square),
                tooltip: 'Tümünü Okundu İşaretle',
                onPressed: () => notifNotifier.markAllAsRead(),
              ),
          ],
        ),
        body: notifState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifState.notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      IconsaxPlusLinear.notification,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz bildirim yok.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  // Otomatik güncelleniyor
                },
                child: ListView.builder(
                  itemCount: notifState.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifState.notifications[index];
                    return _NotificationTile(notification: notif, ref: ref);
                  },
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final WidgetRef ref;

  const _NotificationTile({required this.notification, required this.ref});

  IconData _getIcon() {
    switch (notification.type) {
      case 'like':
        return IconsaxPlusBold.heart;
      case 'comment':
        return IconsaxPlusBold.message;
      case 'follow':
        return IconsaxPlusBold.user_add;
      default:
        return IconsaxPlusBold.notification;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref
            .read(notificationProvider.notifier);
      },
      child: InkWell(
        onTap: () => _handleTap(context),
        child: Container(
          color: isUnread
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        notification.senderImage != null &&
                            notification.senderImage!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            notification.senderImage!,
                            cacheManager: CustomImageCacheManager(),
                          )
                        : null,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child:
                        (notification.senderImage == null ||
                            notification.senderImage!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(), size: 14, color: _getIconColor()),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style.copyWith(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: '${notification.senderName} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: notification.message),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.createdAt, locale: 'tr'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (notification.type == 'follow')
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                )
              else if (notification.postImage != null &&
                  notification.postImage!.isNotEmpty)
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        notification.postImage!,
                        cacheManager: CustomImageCacheManager(),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) async {
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    if (notification.type == 'follow') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilePage(userId: notification.senderId),
        ),
      );
    } else if (notification.postId != null) {
      try {
        final supabase = Supabase.instance.client;

        final response = await supabase
            .from('posts')
            .select('''
              *,
              profiles:profiles!posts_user_id_fkey(*),
              post_likes(count),
              comments(count),
              my_likes:post_likes(user_id)
            ''')
            .eq('id', notification.postId!)
            .single();


        final modJson = Map<String, dynamic>.from(response);

        final post = PostModel.fromJson(modJson);

        if (context.mounted) {
          NavigationService.toNamed(
            AppRoutes.detailedPost,
            arguments: {'post': post}
          );
        }
      } catch (e) {
        debugPrint('Post Detayı Hatası: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu gönderi artık mevcut değil.')),
          );
        }
      }
    }
  }
}
