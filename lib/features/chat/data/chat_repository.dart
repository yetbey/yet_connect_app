import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/features/chat/data/models/chat_model.dart';
import 'package:yet_x_app/features/chat/data/models/message_model.dart';
import 'package:yet_x_app/core/services/database_service.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

class MessageFetchResult {
  final List<MessageModel> messages;
  final bool isFromCache;

  MessageFetchResult({required this.messages, required this.isFromCache});
}

class ChatRepository {
  final SupabaseClient _supabase;
  final DatabaseService _db;

  ChatRepository(this._supabase, this._db);

  Future<List<ChatModel>> fetchChats(String myId) async {
    try {
      // ✅ Önce database'den cached chatları göster
      final cachedChats = await _db.getCachedChats();
      if (cachedChats.isNotEmpty) {
        LogService.d('✅ ${cachedChats.length} chat cache\'den geldi');

        // ✅ Arka planda güncelle
        _updateChatsInBackground(myId);

        // ✅ Cache'den parse et (artık unread_count da var)
        return cachedChats.map((e) => ChatModel.fromJsonLocal(e)).toList();
      }

      // Database'de yoksa Supabase'den çek
      final chats = await _fetchChatsFromSupabase(myId);

      // Database'e kaydet
      try {
        await _db.saveChats(chats.map((e) => e.toJson()).toList());
        LogService.d('✅ Chatlar database\'e kaydedildi');
      } catch (e) {
        LogService.w('⚠️ Cache kaydetme hatası: $e');
      }

      return chats;
    } catch (e) {
      LogService.e('❌ Chat fetch hatası', e);

      // Hata varsa cached chatları döndür
      final cachedChats = await _db.getCachedChats();
      if (cachedChats.isNotEmpty) {
        LogService.w('⚠️ Hata sonrası cached chatlar döndürüldü');
        return cachedChats.map((e) => ChatModel.fromJsonLocal(e)).toList();
      }

      Utils.showSnackBar(
        text: LocaleKeys.chat_chat_list_error.tr(),
        isError: true,
      );
      return [];
    }
  }

  /// Supabase'den chatları çek
  Future<List<ChatModel>> _fetchChatsFromSupabase(String myId) async {
    try {
      LogService.d('🔍 _fetchChatsFromSupabase başladı');

      final myChatsData = await _supabase
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', myId)
          .isFilter('deleted_at', null);

      final chatIds = (myChatsData as List).map((e) => e['chat_id']).toList();

      LogService.d('🔍 ${chatIds.length} chat ID bulundu');

      if (chatIds.isEmpty) return [];

      // ✅ Tüm okunmamış mesajları tek sorguda çek
      final allUnreadMessages = await _supabase
          .from('messages')
          .select('chat_id')
          .filter('chat_id', 'in', chatIds)
          .eq('receiver_id', myId)
          .eq('is_read', false);

      LogService.d(
        '🔍 ${(allUnreadMessages as List).length} okunmamış mesaj bulundu',
      );

      // ✅ Chat ID'ye göre grupla ve say
      final Map<String, int> unreadCountMap = {};
      for (var msg in (allUnreadMessages as List)) {
        final chatId = msg['chat_id'].toString(); // ✅ toString()
        unreadCountMap[chatId] = (unreadCountMap[chatId] ?? 0) + 1;
      }

      final response = await _supabase
          .from('chats')
          .select('*, participants:chat_participants(profiles(*))')
          .filter('id', 'in', chatIds)
          .order('last_message_at', ascending: false);

      LogService.d('🔍 ${(response as List).length} chat bilgisi geldi');

      final List<ChatModel> chats = [];

      for (var chatJson in (response as List)) {
        try {
          LogService.d('🔍 Chat parse ediliyor: ${chatJson['id']}');

          final rawParticipants = chatJson['participants'] as List;
          final flatParticipants = rawParticipants
              .map((p) => p['profiles'])
              .where((p) => p != null)
              .toList();

          if (flatParticipants.isEmpty) {
            LogService.w('⚠️ Participants boş, atlanıyor');
            continue;
          }

          final cleanJson = Map<String, dynamic>.from(chatJson);
          cleanJson['participants'] = flatParticipants;
          cleanJson['unread_count'] =
              unreadCountMap[chatJson['id'].toString()] ?? 0; // ✅ toString()

          chats.add(ChatModel.fromSupabase(cleanJson, myId));
          LogService.d('✅ Chat eklendi: ${chatJson['id']}');
        } catch (e, stackTrace) {
          LogService.e('❌ Bu chat parse edilemedi: ${chatJson['id']}', e);
          LogService.e('Stack trace:', stackTrace);
          LogService.e('Chat data:', chatJson);
        }
      }

      LogService.d('✅ Toplam ${chats.length} chat parse edildi');
      return chats;
    } catch (e, stackTrace) {
      LogService.e('❌ _fetchChatsFromSupabase hatası', e);
      LogService.e('Stack trace:', stackTrace);
      rethrow;
    }
  }

  /// Arka planda chatları güncelle
  Future<void> _updateChatsInBackground(String myId) async {
    try {
      final chats = await _fetchChatsFromSupabase(myId);
      await _db.saveChats(chats.map((e) => e.toJson()).toList());
      LogService.d('🔄 Chatlar arka planda güncellendi');
    } catch (e) {
      LogService.d('⚠️ Arka plan chat güncellemesi başarısız');
    }
  }

  Future<String> startChat(String targetUserId) async {
    final response = await _supabase.rpc(
      'get_or_create_chat',
      params: {'target_user_id': targetUserId},
    );
    return response.toString();
  }

  Future<MessageFetchResult> fetchMessages(String chatId) async {
    try {
      // Önce database'den cached mesajları göster
      final cachedMessages = await _db.getChatMessages(chatId, limit: 100);
      if (cachedMessages.isNotEmpty) {
        LogService.d('✅ ${cachedMessages.length} mesaj cache\'den geldi');
        _updateMessagesInBackground(chatId);
        return MessageFetchResult(
          // ✅ fromJson kullan (artık hem SQLite hem Supabase için çalışıyor)
          messages: cachedMessages
              .map((e) => MessageModel.fromJson(e))
              .toList(),
          isFromCache: true,
        );
      }

      // Database'de yoksa Supabase'den çek
      final data = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false);

      final messages = (data as List)
          .map((e) => MessageModel.fromJson(e))
          .toList();

      // Database'e kaydet
      await _db.saveMessages(chatId, messages.map((e) => e.toJson()).toList());

      return MessageFetchResult(messages: messages, isFromCache: false);
    } catch (e) {
      LogService.e('❌ Mesaj fetch hatası', e);
      // Hata varsa cached mesajları döndür
      final cachedMessages = await _db.getChatMessages(chatId, limit: 100);
      return MessageFetchResult(
        messages: cachedMessages.map((e) => MessageModel.fromJson(e)).toList(),
        isFromCache: true,
      );
    }
  }

  /// Arka planda mesajları güncelle
  Future<void> _updateMessagesInBackground(String chatId) async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(100);

      final messages = (data as List)
          .map((e) => MessageModel.fromJson(e))
          .toList();

      await _db.saveMessages(chatId, messages.map((e) => e.toJson()).toList());
      LogService.d('🔄 Mesajlar arka planda güncellendi');
    } catch (e) {
      LogService.d('⚠️ Arka plan mesaj güncellemesi başarısız');
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => MessageModel.fromJson(e)).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    File? imageFile,
    String? replyToMessageId,
  }) async {
    try {
      LogService.d('📤 sendMessage başladı - chatId: $chatId');

      String? imageUrl;

      // 1. Resim Varsa Yükle
      if (imageFile != null) {
        LogService.d('📸 Resim yükleniyor...');
        final fileExt = imageFile.path.split('.').last;
        final fileName =
            'chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await _supabase.storage.from('uploads').upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );
        imageUrl = _supabase.storage.from('uploads').getPublicUrl(fileName);
        LogService.d('✅ Resim yüklendi: $imageUrl');
      }

      LogService.d('🔍 Alıcı ID çekiliyor...');
      final participants = await _supabase
          .from('chat_participants')
          .select('user_id')
          .eq('chat_id', chatId)
          .neq('user_id', senderId)
          .maybeSingle();

      final receiverId = participants != null ? participants['user_id'] : senderId;
      LogService.d('✅ Alıcı ID: $receiverId');

      Map<String, dynamic>? replyData;
      if (replyToMessageId != null) {
        LogService.d('🔍 Reply mesajı çekiliyor: $replyToMessageId');

        final replyMessage = await _supabase
            .from('messages')
            .select('content, image_url, sender_id')
            .eq('id', replyToMessageId)
            .maybeSingle();

        if (replyMessage != null) {
          LogService.d('✅ Reply mesajı bulundu, gönderen: ${replyMessage['sender_id']}');

          // Kendi mesajımıza reply yapıyorsak "Sen", değilse kullanıcı adını çek
          String senderName;
          if (replyMessage['sender_id'] == senderId) {
            senderName = 'Sen';
            LogService.d('✅ Kendi mesajına reply yapıyor');
          } else {
            LogService.d('🔍 Karşı kullanıcının profili çekiliyor...');
            final senderProfile = await _supabase
                .from('profiles')
                .select('username')
                .eq('id', replyMessage['sender_id'])
                .maybeSingle();
            senderName = senderProfile?['username'] ?? 'Kullanıcı';
            LogService.d('✅ Karşı kullanıcı adı: $senderName');
          }

          replyData = {
            'reply_to_message_id': replyToMessageId,
            'reply_to_content': replyMessage['content'],
            'reply_to_image_url': replyMessage['image_url'],
            'reply_to_sender_name': senderName,
          };
          LogService.d('✅ Reply data hazırlandı');
        }
      }

      LogService.d('📨 Mesaj veritabanına yazılıyor...');
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'image_url': imageUrl,
        ...?replyData,
      });
      LogService.d('✅ Mesaj veritabanına yazıldı');

      final lastMsgText = (imageFile != null)
          ? (content.isEmpty ? '📷${'photo'.tr()}' : '📷 $content')
          : content;

      LogService.d('🔄 Chat güncelleniyor...');
      await _supabase.from('chats').update({
        'last_message': lastMsgText,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      LogService.i('✅ Mesaj başarıyla gönderildi');
    } catch (e, stackTrace) {
      LogService.e('❌ sendMessage hatası', e);
      LogService.e('Stack trace:', stackTrace);
      rethrow; // Hatayı provider'a fırlat
    }
  }


  Future<void> markAsRead(String chatId, String myId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .eq('receiver_id', myId)
          .eq('is_read', false);
    } catch (e) {
      LogService.e('Okundu işaretlenirken hata (Offline olabilir): $e');
    }
  }

  /// İki taraf için sil (hard delete)
  Future<void> deleteChatForBoth(String chatId) async {
    try {
      LogService.d('🗑️ Chat siliniyor (iki taraf için): $chatId');

      // 1. Önce mesajları sil
      try {
        await _supabase
            .from('messages')
            .delete()
            .eq('chat_id', chatId);
        LogService.d('✅ Mesajlar silindi');
      } catch (e) {
        LogService.e('❌ Mesaj silme hatası:', e);
      }

      // 2. Chat participants'ları sil
      try {
        await _supabase
            .from('chat_participants')
            .delete()
            .eq('chat_id', chatId);
        LogService.d('✅ Participants silindi');
      } catch (e) {
        LogService.e('❌ Participants silme hatası:', e);
      }

      // 3. Chat'i sil
      try {
        await _supabase
            .from('chats')
            .delete()
            .eq('id', chatId);
        LogService.d('✅ Chat silindi');
      } catch (e) {
        LogService.e('❌ Chat silme hatası:', e);
      }

      // 4. Local cache'den sil
      await _db.deleteChat(chatId);

      LogService.d('✅ Chat iki taraf için tamamen silindi: $chatId');
    } catch (e, stackTrace) {
      LogService.e('❌ Chat silme hatası (iki taraf için)', e);
      LogService.e('Stack trace:', stackTrace);
      rethrow;
    }
  }

  /// Sadece benim için sil
  Future<void> deleteChatForMe(String chatId, String myId) async {
    try {
      LogService.d('🗑️ Chat siliniyor (benim için): chatId=$chatId, myId=$myId');

      // Önce kontrol et
      final checkResult = await _supabase
          .from('chat_participants')
          .select()
          .eq('chat_id', chatId)
          .eq('user_id', myId);

      LogService.d('📊 Bulunan participant: ${checkResult.length}');

      if (checkResult.isNotEmpty) {
        // Soft delete
        final updateResult = await _supabase
            .from('chat_participants')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('chat_id', chatId)
            .eq('user_id', myId)
            .select();

        LogService.d('✅ Update sonucu: ${updateResult.length}');
      }

      // Local cache'den sil
      await _db.deleteChat(chatId);

      LogService.d('✅ Chat sadece benim için silindi: $chatId');
    } catch (e, stackTrace) {
      LogService.e('❌ Chat silme hatası (benim için)', e);
      LogService.e('Stack trace:', stackTrace);
      rethrow;
    }
  }

}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    Supabase.instance.client,
    ref.read(databaseServiceProvider),
  );
});
