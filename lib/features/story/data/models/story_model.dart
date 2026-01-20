import 'package:equatable/equatable.dart';

class StoryModel extends Equatable {
  final int id;
  final String userId;
  final String mediaUrl;
  final String mediaType; // 'image' veya 'video'
  final String? thumbnailUrl;
  final int? duration; // video için milisaniye
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;

  // Story sahibi bilgileri (join ile gelecek)
  final String? username;
  final String? userFullName;
  final String? userProfileImage;

  // Görüntüleyen kullanıcılar (opsiyonel)
  final List<String>? viewerIds;
  final bool? isViewedByMe;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    this.thumbnailUrl,
    this.duration,
    required this.createdAt,
    required this.expiresAt,
    this.viewCount = 0,
    this.username,
    this.userFullName,
    this.userProfileImage,
    this.viewerIds,
    this.isViewedByMe,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isVideo => mediaType == 'video';

  bool get isImage => mediaType == 'image';

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as int,
      userId: json['user_id']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? '',
      mediaType: json['media_type']?.toString() ?? 'image',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      duration: json['duration'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'].toString())
          : DateTime.now().add(const Duration(hours: 24)),
      viewCount: json['view_count'] as int? ?? 0,
      username: json['username']?.toString(),
      userFullName:
          json['full_name']?.toString() ?? json['user_full_name']?.toString(),
      userProfileImage:
          json['profile_image_url']?.toString() ??
          json['user_profile_image']?.toString(),
      viewerIds: json['viewers'] != null
          ? List<String>.from(
              (json['viewers'] as List).map((v) => v['viewer_id'].toString()),
            )
          : null,
      isViewedByMe: json['is_viewed_by_me'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'view_count': viewCount,
      'username': username,
      'user_full_name': userFullName,
      'user_profile_image': userProfileImage,
      'is_viewed_by_me': isViewedByMe,
    };
  }

  StoryModel copyWith({
    int? id,
    String? userId,
    String? mediaUrl,
    String? mediaType,
    String? thumbnailUrl,
    int? duration,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewCount,
    String? username,
    String? userFullName,
    String? userProfileImage,
    List<String>? viewerIds,
    bool? isViewedByMe,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      username: username ?? this.username,
      userFullName: userFullName ?? this.userFullName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      viewerIds: viewerIds ?? this.viewerIds,
      isViewedByMe: isViewedByMe ?? this.isViewedByMe,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    mediaUrl,
    mediaType,
    thumbnailUrl,
    duration,
    createdAt,
    expiresAt,
    viewCount,
    isViewedByMe,
  ];
}

/// Kullanıcının story grupları için model
class UserStoryGroup extends Equatable {
  final String userId;
  final String username;
  final String? userFullName;
  final String? userProfileImage;
  final List<StoryModel> stories;
  final bool hasUnseenStories;
  final DateTime lastStoryTime;

  const UserStoryGroup({
    required this.userId,
    required this.username,
    this.userFullName,
    this.userProfileImage,
    required this.stories,
    required this.hasUnseenStories,
    required this.lastStoryTime,
  });

  @override
  List<Object?> get props => [userId, stories, hasUnseenStories];
}
