class UserPointsModel {
  final String userId;
  final int totalPoints;
  final String rank;
  final int level;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPointsModel({
    required this.userId,
    required this.totalPoints,
    required this.rank,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPointsModel.fromJson(Map<String, dynamic> json) {
    return UserPointsModel(
      userId: json['user_id'] as String,
      totalPoints: json['total_points'] as int? ?? 0,
      rank: json['rank'] as String? ?? 'rookie',
      level: json['level'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_points': totalPoints,
      'rank': rank,
      'level': level,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserPointsModel copyWith({
    String? userId,
    int? totalPoints,
    String? rank,
    int? level,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPointsModel(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      rank: rank ?? this.rank,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'UserPointsModel(userId: $userId, points: $totalPoints, rank: $rank)';
}
