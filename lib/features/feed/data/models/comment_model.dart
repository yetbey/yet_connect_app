class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;

  // İlişkisel Veriler (profiles tablosundan)
  final String userName;
  final String? userProfileImage;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.userName,
    this.userProfileImage,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Supabase join ile 'profiles' objesini getirir
    final profile = json['profiles'] ?? {};

    return CommentModel(
      id: json['id'].toString(),
      postId: json['post_id'].toString(),
      userId: json['user_id'].toString(),
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),

      // İlişkisel Veriler
      userName: profile['username'] ?? 'Kullanıcı',
      userProfileImage: profile['profile_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}