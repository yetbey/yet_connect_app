class LiveEventMessageModel {
  final int id;
  final String eventId;
  final String userId;
  final String message;
  final String messageType;
  final DateTime createdAt;
  final String? username;
  final String? fullName;
  final String? profileImageUrl;

  const LiveEventMessageModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.message,
    required this.messageType,
    required this.createdAt,
    this.username,
    this.fullName,
    this.profileImageUrl,
  });

  factory LiveEventMessageModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return LiveEventMessageModel(
      id: json['id'] as int,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['created_at'] as String),
      username: profile?['username'] as String?,
      fullName: profile?['full_name'] as String?,
      profileImageUrl: profile?['profile_image_url'] as String?,
    );
  }

  LiveEventMessageModel copyWithProfile({
    String? username,
    String? fullName,
    String? profileImageUrl,
  }) {
    return LiveEventMessageModel(
      id: id,
      eventId: eventId,
      userId: userId,
      message: message,
      messageType: messageType,
      createdAt: createdAt,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}