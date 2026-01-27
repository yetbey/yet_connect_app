class PointHistoryModel {
  final int id;
  final String userId;
  final int points;
  final String source; // 'post', 'like', 'comment', 'mission', 'weekly_top', 'streak'
  final String? description;
  final int? missionId;
  final DateTime createdAt;

  const PointHistoryModel({
    required this.id,
    required this.userId,
    required this.points,
    required this.source,
    this.description,
    this.missionId,
    required this.createdAt,
  });

  factory PointHistoryModel.fromJson(Map<String, dynamic> json) {
    return PointHistoryModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      points: json['points'] as int,
      source: json['source'] as String,
      description: json['description'] as String?,
      missionId: json['mission_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'source': source,
      'description': description,
      'mission_id': missionId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get sourceIcon {
    final iconMap = {
      'post': '📝',
      'like': '❤️',
      'comment': '💬',
      'mission': '🎯',
      'weekly_top': '🏆',
      'streak': '🔥',
    };
    return iconMap[source] ?? '⭐';
  }

  @override
  String toString() => 'PointHistoryModel(points: $points, source: $source)';
}
