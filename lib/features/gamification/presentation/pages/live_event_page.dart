import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yet_x_app/core/constants/app_colors.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:yet_x_app/features/gamification/data/models/live_event_model.dart';
import 'package:yet_x_app/features/gamification/data/models/live_event_message_model.dart';
import 'package:yet_x_app/features/gamification/data/services/live_event_service.dart';

class LiveEventPage extends ConsumerStatefulWidget {
  final String eventId;
  const LiveEventPage({super.key, required this.eventId});

  @override
  ConsumerState<LiveEventPage> createState() => _LiveEventPageState();
}

class _LiveEventPageState extends ConsumerState<LiveEventPage> {
  final _service = LiveEventService();
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  LiveEventModel? _event;
  List<LiveEventMessageModel> _messages = [];
  final Map<String, Map<String, dynamic>> _profileCache = {};

  StreamSubscription<List<Map<String, dynamic>>>? _messageSub;
  RealtimeChannel? _presenceChannel;
  int _viewerCount = 0;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final response = await _supabase
          .from('live_events')
          .select()
          .eq('id', widget.eventId)
          .maybeSingle();

      if (response == null) {
        setState(() => _isLoading = false);
        return;
      }

      _event = LiveEventModel.fromJson(response);

      final initial = await _service.getInitialMessages(widget.eventId);
      _messages = initial
          .map((json) => LiveEventMessageModel.fromJson(json))
          .toList();

      for (final m in _messages) {
        _profileCache[m.userId] = {
          'username': m.username,
          'full_name': m.fullName,
          'profile_image_url': m.profileImageUrl,
        };
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      _scrollToBottom();

      _listenToMessages();
      _joinPresence();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToMessages() {
    _messageSub = _service.streamMessages(widget.eventId).listen((rows) async {
      final resolved = <LiveEventMessageModel>[];

      for (final row in rows) {
        var msg = LiveEventMessageModel.fromJson(row);

        if (!_profileCache.containsKey(msg.userId)) {
          final profile = await _service.getProfile(msg.userId);
          if (profile != null) {
            _profileCache[msg.userId] = profile;
          }
        }

        final cached = _profileCache[msg.userId];
        if (cached != null) {
          msg = msg.copyWithProfile(
            username: cached['username'] as String?,
            fullName: cached['full_name'] as String?,
            profileImageUrl: cached['profile_image_url'] as String?,
          );
        }
        resolved.add(msg);
      }

      if (!mounted) return;
      setState(() => _messages = resolved);
      _scrollToBottom();
    });
  }

  void _joinPresence() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _presenceChannel = _supabase.channel('live_event_presence:${widget.eventId}');

    _presenceChannel!.onPresenceSync((payload) {
      if (!mounted) return;
      setState(() {
        _viewerCount = _presenceChannel!.presenceState().length;
      });
    });

    _presenceChannel!.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _presenceChannel!.track({
          'user_id': userId,
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _event == null || _isSending) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _service.sendMessage(
        eventId: _event!.id,
        userId: userId,
        message: text,
      );
    } catch (e) {
      if (mounted) {
        Utils.showSnackBar(text: 'Mesaj gönderilemedi', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _presenceChannel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: _event == null
            ? const Text('Canlı Etkinlik')
            : Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _event!.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_event!.hostName != null)
                    Text(
                      _event!.hostName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_event?.isLive ?? false)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_viewerCount izliyor',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
          ? const Center(child: Text('Bu etkinlik bulunamadı'))
          : Column(
        children: [
          if (_event!.description != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Text(
                _event!.description!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Text(
                'Henüz mesaj yok, ilk mesajı sen gönder! 👋',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.userId == currentUserId;
                return _buildMessageBubble(message, isMe, theme);
              },
            ),
          ),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      LiveEventMessageModel message,
      bool isMe,
      ThemeData theme,
      ) {
    final displayName = message.fullName ?? message.username ?? 'Kullanıcı';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: message.profileImageUrl != null
                  ? CachedNetworkImageProvider(
                message.profileImageUrl!,
                cacheManager: CustomImageCacheManager(),
              )
                  : null,
              child: message.profileImageUrl == null
                  ? Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeago.format(message.createdAt, locale: 'tr'),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Bir mesaj yaz...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSending ? null : () {
                HapticFeedback.lightImpact();
                _sendMessage();
              },
              icon: _isSending
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send_rounded, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
