import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String userName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? bio;
  final List<String> followers;
  final List<String> following;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.userName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.bio,
    this.followers = const [],
    this.following = const [],
    this.createdAt,
  });

  // Boş bir kullanıcı modeli
  static const empty = UserModel(id: '', fullName: '', userName: '', email: '');

  /// Takipçi ve takip sayısı
  int get followersCount => followers.length;
  int get followingCount => following.length;

  /// Belirli bir kullanıcı takip ediyor mu yada takipçi mi?
  bool isFollowing(String userId) => following.contains(userId);
  bool isFollower(String userId) => followers.contains(userId);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parseIds(dynamic list, String keyName) {
      if (list == null) return [];
      if (list is List) {
        return list
            .map((item) {
              if (item is Map) {
                // Supabase join yapısı: { "follower_id": "xyz" }
                return item[keyName]?.toString() ?? '';
              }
              return item.toString();
            })
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      userName: json['username'] ?? '',
      email: json['email'] ?? '', // Auth tablosundan gelmiyorsa boş olabilir
      profileImageUrl: json['profile_image_url'],
      bio: json['bio'],
      phoneNumber: json['phone_number'],
      // Supabase'de 'follows' tablosu üzerinden gelen veriyi parse et
      // followers tablosunda: follower_id bizim için önemli
      followers: parseIds(json['followers'], 'follower_id'),
      // following tablosunda: following_id bizim için önemli
      following: parseIds(json['following'], 'following_id'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': userName,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'bio': bio,
      'followers': followers,
      'following': following,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromJsonLocal(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      userName: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      bio: json['bio'],
      // Listeleri güvenli bir şekilde dönüştür
      followers: json['followers'] != null
          ? List<String>.from(json['followers'])
          : [],
      following: json['following'] != null
          ? List<String>.from(json['following'])
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? userName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? bio,
    List<String>? followers,
    List<String>? following,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    userName,
    email,
    profileImageUrl,
    bio,
    followers,
    following,
  ];
}
