class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final String? imageUrl;
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToImageUrl;
  final String? replyToSenderName;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.imageUrl,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToImageUrl,
    this.replyToSenderName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
      chatId: json['chat_id'].toString(),
      senderId: json['sender_id'].toString(),
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      // GÜNCELLEME: .toLocal() eklendi
      sentAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      replyToMessageId: json['reply_to_message_id']?.toString(),
      replyToContent: json['reply_to_content']?.toString(),
      replyToImageUrl: json['reply_to_image_url']?.toString(),
      replyToSenderName: json['reply_to_sender_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'created_at': sentAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'image_url': imageUrl,
      'reply_to_message_id': replyToMessageId,
      'reply_to_content': replyToContent,
      'reply_to_image_url': replyToImageUrl,
      'reply_to_sender_name': replyToSenderName,
    };
  }

  factory MessageModel.fromJsonLocal(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      content: json['content'],
      sentAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      imageUrl: json['image_url'],
    );
  }
}
