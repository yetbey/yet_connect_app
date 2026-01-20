class ChatModel {
  final String id;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserImage;
  final int unreadCount;

  ChatModel({
    required this.id,
    this.lastMessage,
    this.lastMessageAt,
    this.otherUserId,
    this.otherUserName,
    this.otherUserImage,
    this.unreadCount = 0,
  });

  factory ChatModel.fromSupabase(Map<String, dynamic> json, String myUserId) {
    final List participants = json['participants'] ?? [];
    final otherUserMap = participants.firstWhere(
      (u) => u['id'].toString() != myUserId, // ✅ toString()
      orElse: () => {},
    );

    final targetUser = otherUserMap.isNotEmpty
        ? otherUserMap
        : (participants.isNotEmpty ? participants.first : {});

    return ChatModel(
      id: json['id']?.toString() ?? '', // ✅ toString()
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'].toString()) // ✅ toString()
          : null,
      otherUserId: targetUser['id']?.toString(), // ✅ toString()
      otherUserName: targetUser['username']?.toString() ?? 'Kullanıcı',
      otherUserImage: targetUser['profile_image_url']?.toString(),
      unreadCount: json['unread_count'] is int
          ? json['unread_count']
          : (int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0),
    );
  }

  // 1. Modeli JSON Map'e çevir (Kaydetmek için)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_image': otherUserImage,
      'unread_count': unreadCount,
    };
  }

  factory ChatModel.fromJsonLocal(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id']?.toString() ?? '',
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'].toString())
          : null,
      otherUserId: json['other_user_id']?.toString(),
      otherUserName: json['other_user_name']?.toString() ?? 'Kullanıcı',
      otherUserImage: json['other_user_image']?.toString(),
      unreadCount: json['unread_count'] is int
          ? json['unread_count']
          : (int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0),
    );
  }
}
