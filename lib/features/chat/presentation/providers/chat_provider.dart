import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/features/chat/data/models/chat_model.dart';
import 'package:yet_x_app/features/chat/data/models/message_model.dart';
import 'package:yet_x_app/features/chat/data/chat_repository.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

class ChatListNotifier extends Notifier<List<ChatModel>> {
  // Repo Enjeksiyonu
  late final ChatRepository _repository = ref.read(chatRepositoryProvider);

  @override
  List<ChatModel> build() {
    Future.microtask(() => fetchChats());
    return [];
  }

  void clearChats() {
    state = [];
  }

  Future<void> fetchChats() async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) {
      state = [];
      return;
    }

    try {
      final chats = await _repository.fetchChats(myId);
      state = chats;
    } catch (e) {
      Utils.showSnackBar(text: 'chat_list_error'.tr(), isError: true);
    }
  }

  Future<String?> startChat(String targetUserId) async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return null;

    try {
      final chatId = await _repository.startChat(targetUserId);
      await fetchChats();
      return chatId;
    } catch (e) {
      Utils.showSnackBar(text: ErrorHandler.getErrorMessage(e), isError: true);
      return null;
    }
  }
}

final chatListProvider = NotifierProvider<ChatListNotifier, List<ChatModel>>(
  () {
    return ChatListNotifier();
  },
);

class MessageState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final bool hasCachedData;
  final MessageModel? replyingTo;

  MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.hasCachedData = false,
    this.replyingTo,
  });

  MessageState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    bool? hasCachedData,
    MessageModel? replyingTo,
    bool clearReply = false,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      hasCachedData: hasCachedData ?? this.hasCachedData,
      replyingTo: clearReply ? null : (replyingTo ?? this.replyingTo),
    );
  }
}

class MessagesNotifier extends AutoDisposeFamilyNotifier<MessageState, String> {
  late final ChatRepository _repository = ref.read(chatRepositoryProvider);
  StreamSubscription? _subscription;

  @override
  MessageState build(String chatId) {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    _loadInitialMessages(chatId);
    _subscribeToMessages(chatId);

    return MessageState(isLoading: true, replyingTo: null);
  }

  Future<void> _loadInitialMessages(String chatId) async {
    try {
      final result = await _repository.fetchMessages(chatId);

      state = state.copyWith(
        messages: result.messages,
        isLoading: false,
        hasCachedData: result.isFromCache,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, hasCachedData: false);
    }
  }

  void _subscribeToMessages(String chatId) {
    _subscription = _repository.getMessagesStream(chatId).listen((msgs) {
      state = state.copyWith(
        messages: msgs,
        hasCachedData: true, // Stream'den geliyorsa cihazda var
      );
    });
  }

  Future<void> markAsRead(String chatId) async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;

    try {
      await _repository.markAsRead(chatId, myId);
    } catch (e) {
      Utils.showSnackBar(text: 'mark_as_read'.tr(), isError: true);
    }
  }

  void setReplyTo(MessageModel message) {
    state = state.copyWith(replyingTo: message);
  }

  void clearReply() {
    state = state.copyWith(clearReply: true);
  }

  Future<void> sendMessage(
    String chatId,
    String content, {
    File? imageFile,
  }) async {
    if (content.trim().isEmpty && imageFile == null) return;

    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;

    final replyTo = state.replyingTo;

    String? replyToSenderName;
    if (replyTo != null) {
      if (replyTo.senderId == myId) {
        replyToSenderName = 'Sen';
      } else {
        // Karşı kullanıcının ismi zaten replyToSenderName'de var
        replyToSenderName = replyTo.replyToSenderName;
      }
    }

    final tempMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: myId,
      content: content,
      sentAt: DateTime.now(),
      isRead: false,
      imageUrl: imageFile?.path,
      replyToMessageId: replyTo?.id,
      replyToContent: replyTo?.content,
      replyToImageUrl: replyTo?.imageUrl,
      replyToSenderName: replyToSenderName,
    );

    state = state.copyWith(
      messages: [tempMessage, ...state.messages],
      isSending: true,
      clearReply: true,
    );

    try {
      await _repository.sendMessage(
        chatId: chatId,
        senderId: myId,
        content: content,
        imageFile: imageFile,
        replyToMessageId: replyTo?.id,
      );

      state = state.copyWith(
        messages: state.messages.where((m) => m.id != tempMessage.id).toList(),
        isSending: false,
      );
    } catch (e) {
      Utils.showSnackBar(
        text: LocaleKeys.chat_message_not_send.tr(),
        isError: true,
      );

      state = state.copyWith(
        messages: state.messages.where((m) => m.id != tempMessage.id).toList(),
      );
    } finally {
      state = state.copyWith(isSending: false);
    }
  }
}

final chatMessagesProvider = NotifierProvider.autoDispose
    .family<MessagesNotifier, MessageState, String>(MessagesNotifier.new);
