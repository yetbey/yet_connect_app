class AppNotification {
  final String id;
  final String type; // 'like', 'comment', 'follow'
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? postId;
  final String senderId;

  // İlişkisel Veriler (UI için)
  final String? senderName;
  final String? senderImage;
  final String? postImage;

  AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.senderId,
    this.isRead = false,
    this.postId,
    this.senderName,
    this.senderImage,
    this.postImage,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] ?? {};
    final post = json['post'] ?? {};

    return AppNotification(
      id: json['id'].toString(),
      type: json['type'] ?? 'info',
      message: json['message'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      postId: json['post_id']?.toString(),
      senderId: json['sender_id'].toString(),
      senderName: sender['username'] ?? sender['full_name'] ?? 'Kullanıcı',
      senderImage: sender['profile_image_url'],
      postImage: post['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'created_at': createdAt.toUtc().toIso8601String(),
      'is_read': isRead,
      'post_id': postId,
      'sender_id': senderId,
      'sender': {
        'username': senderName,
        'profile_image_url': senderImage,
      },
      'post': {
        'image_url': postImage,
      },
    };
  }

  AppNotification copyWith({
    String? id,
    String? type,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? postId,
    String? senderId,
    String? senderName,
    String? senderImage,
    String? postImage,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      postId: postId ?? this.postId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      postImage: postImage ?? this.postImage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
