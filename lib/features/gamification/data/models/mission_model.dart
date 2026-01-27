import 'package:flutter/material.dart';

class MissionModel {
  final int id;
  final String type; // 'daily', 'weekly', 'special'
  final String title;
  final String? description;
  final int target;
  final int rewardPoints;
  final String? icon;
  final String? color;
  final bool isActive;
  final DateTime createdAt;

  // Progress (opsiyonel, user_mission_progress'ten gelir)
  final int currentProgress;
  final bool isCompleted;

  const MissionModel({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.target,
    required this.rewardPoints,
    this.icon,
    this.color,
    required this.isActive,
    required this.createdAt,
    this.currentProgress = 0,
    this.isCompleted = false,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      target: json['target'] as int,
      rewardPoints: json['reward_points'] as int,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      currentProgress: json['current_progress'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'target': target,
      'reward_points': rewardPoints,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'current_progress': currentProgress,
      'is_completed': isCompleted,
    };
  }

  double get progress => target > 0 ? (currentProgress / target).clamp(0.0, 1.0) : 0.0;

  Color get colorValue {
    if (color == null) return Colors.blue;
    try {
      return Color(int.parse(color!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData get iconData {
    if (icon == null) return Icons.emoji_events;

    final iconMap = {
      'edit': Icons.edit,
      'favorite': Icons.favorite,
      'comment': Icons.comment,
      'trending_up': Icons.trending_up,
      'forum': Icons.forum,
    };

    return iconMap[icon] ?? Icons.emoji_events;
  }

  MissionModel copyWith({
    int? currentProgress,
    bool? isCompleted,
  }) {
    return MissionModel(
      id: id,
      type: type,
      title: title,
      description: description,
      target: target,
      rewardPoints: rewardPoints,
      icon: icon,
      color: color,
      isActive: isActive,
      createdAt: createdAt,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() => 'MissionModel(title: $title, progress: $currentProgress/$target)';
}
