import 'package:flutter/material.dart';

class AnnouncementModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final String icon;
  final String gradientStart;
  final String gradientEnd;
  final String actionType; // 'none', 'post', 'tag', 'url'
  final String? actionValue;
  final int priority;
  final bool isActive;
  final DateTime startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.actionType,
    this.actionValue,
    required this.priority,
    required this.isActive,
    required this.startsAt,
    this.endsAt,
    required this.createdAt,
});

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'update',
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? 'celebration',
      gradientStart: json['gradient_start'] as String? ?? '#667eea',
      gradientEnd: json['gradient_end'] as String? ?? '#764ba2',
      actionType: json['action_type'] as String? ?? 'none',
      actionValue: json['action_value'] as String?,
      priority: json['priority'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Color get startColor => _parseColor(gradientStart);
  Color get endColor => _parseColor(gradientEnd);

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  IconData get iconData {
    const iconMap = {
      'celebration': Icons.celebration,
      'local_fire_department': Icons.local_fire_department,
      'newspaper': Icons.newspaper,
      'emoji_events': Icons.emoji_events,
      'campaign': Icons.campaign,
      'stars': Icons.stars,
      'auto_awesome': Icons.auto_awesome,
      'card_giftcard': Icons.card_giftcard,
      'photo_camera': Icons.photo_camera,
    };
    return iconMap[icon] ?? Icons.campaign;
  }

  @override
  String toString() => 'AnnouncementModel(id: $id, title: $title)';
}