import 'dart:convert';

class PostModel {
  final String id;
  final String userId;
  final String? caption;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;

  // Kullanıcı Bilgileri
  final String? userFullName;
  final String? userProfileImage;
  final String? username;

  // Değişkenler (UI etkileşimi için)
  final int likes;
  final bool isLikedByCurrentUser;
  final int commentCount;
  final double? alignmentX;
  final double? alignmentY;

  final List<String> tags;
  final List<LikerPreview>? topLikers;

  PostModel({
    required this.id,
    required this.userId,
    this.caption,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    this.userFullName,
    this.userProfileImage,
    this.username,
    this.alignmentX,
    this.alignmentY,
    required this.likes,
    required this.isLikedByCurrentUser,
    required this.commentCount,
    this.tags = const [],
    this.topLikers
  });

  PostModel copyWith({
    String? id,
    String? userId,
    String? caption,
    String? imageUrl,
    String? videoUrl,
    DateTime? createdAt,
    String? userFullName,
    String? userProfileImage,
    String? username,
    double? alignmentX,
    double? alignmentY,
    int? likes,
    bool? isLikedByCurrentUser,
    int? commentCount,
    List<String>? tags,
    List<LikerPreview>? topLikers,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      userFullName: userFullName ?? this.userFullName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      username: username ?? this.username,
      alignmentX: alignmentX ?? this.alignmentX,
      alignmentY: alignmentY ?? this.alignmentY,
      likes: likes ?? this.likes,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      commentCount: commentCount ?? this.commentCount,
      tags: tags ?? this.tags,
      topLikers: topLikers ?? this.topLikers,
    );
  }

  // 1. SUPABASE'DEN GELEN VERİYİ OKUMA
  factory PostModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] ?? {};

    int likesCount = 0;
    if (json['post_likes'] is List && (json['post_likes'] as List).isNotEmpty) {
      likesCount = json['post_likes'][0]['count'] ?? 0;
    }

    int commentsCount = 0;
    if (json['comments'] is List && (json['comments'] as List).isNotEmpty) {
      commentsCount = json['comments'][0]['count'] ?? 0;
    }

    bool isLiked = false;
    if (json['my_likes'] != null && (json['my_likes'] is List)) {
      isLiked = (json['my_likes'] as List).isNotEmpty;
    }

    List<String> tagsList = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tagsList = (json['tags'] as List).map((e) => e.toString()).toList();
      }
    }

    List<LikerPreview> likersList = [];
    if (json['top_likers'] != null && json['top_likers'] is List) {
      likersList = (json['top_likers'] as List)
          .map((l) => LikerPreview.fromJson(l))
          .toList();
    }

    return PostModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      caption: json['caption'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      username: profile['username'] ?? 'Kullanıcı',
      userFullName: profile['full_name'],
      userProfileImage: profile['profile_image_url'],
      alignmentX: (json['alignment_x'] as num?)?.toDouble(),
      alignmentY: (json['alignment_y'] as num?)?.toDouble(),
      likes: likesCount,
      isLikedByCurrentUser: isLiked,
      commentCount: commentsCount,
      tags: tagsList,
      topLikers: likersList,
    );
  }

  // 2. TELEFONA KAYDETME (TO JSON) - EKSİK OLAN BUYDU
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'caption': caption,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'created_at': createdAt.toIso8601String(),
      'username': username,
      'user_full_name': userFullName,
      'user_profile_image': userProfileImage,
      'alignment_x': alignmentX,
      'alignment_y': alignmentY,
      'likes': likes,
      'is_liked_by_current_user': isLikedByCurrentUser,
      'comment_count': commentCount,
      'tags': tags,
      'top_likers': topLikers?.map((l) => l.toJson()).toList(),
    };
  }

  // 3. TELEFONDAN OKUMA (FROM LOCAL JSON)
  factory PostModel.fromJsonLocal(Map<String, dynamic> json) {
    // ✅ Local tags parsing
    List<String> tagsList = [];
    if (json['tags'] != null) {
      if (json['tags'] is String) {
        // SQLite'dan gelen string formatını parse et
        final tagsStr = json['tags'] as String;
        if (tagsStr.isNotEmpty && tagsStr != '[]') {
          tagsList = tagsStr
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else if (json['tags'] is List) {
        tagsList = (json['tags'] as List).map((e) => e.toString()).toList();
      }
    }

    List<LikerPreview> likersList = [];
    if (json['top_likers'] != null) {
      if (json['top_likers'] is String) {
        // SQLite'dan string olarak gelebilir
        try {
          final decoded = jsonDecode(json['top_likers']) as List;
          likersList = decoded.map((l) => LikerPreview.fromJson(l)).toList();
        } catch (_) {}
      } else if (json['top_likers'] is List) {
        likersList = (json['top_likers'] as List)
            .map((l) => LikerPreview.fromJson(l))
            .toList();
      }
    }

    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      caption: json['caption'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      createdAt: DateTime.parse(json['created_at']),
      username: json['username'],
      alignmentX: (json['alignment_x'] as num?)?.toDouble(),
      alignmentY: (json['alignment_y'] as num?)?.toDouble(),
      userFullName: json['user_full_name'],
      userProfileImage: json['user_profile_image'],
      likes: json['likes'],
      isLikedByCurrentUser: json['is_liked_by_current_user'],
      commentCount: json['comment_count'],
      tags: tagsList,
      topLikers: likersList,
    );
  }
}

class LikerPreview {
  final String username;
  final String? fullName;

  LikerPreview({
    required this.username,
    this.fullName,
});

  factory LikerPreview.fromJson(Map<String, dynamic> json) {
    return LikerPreview(
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'full_name': fullName,
    };
  }
}
