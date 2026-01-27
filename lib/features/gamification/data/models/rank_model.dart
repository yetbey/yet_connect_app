import 'package:flutter/material.dart';

class RankModel {
  final int id;
  final String name;
  final String displayName;
  final int minPoints;
  final String? icon;
  final String? color;
  final String? badgeUrl;

  const RankModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.minPoints,
    this.icon,
    this.color,
    this.badgeUrl,
});

  factory RankModel.fromJson(Map<String, dynamic> json) {
    return RankModel(
      id: json['id'] as int,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      minPoints: json['min_points'] as int,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      badgeUrl: json['badge_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'min_points': minPoints,
      'icon': icon,
      'color': color,
      'badge_url': badgeUrl,
    };
  }

  Color get colorValue {
    if (color == null) return Colors.grey;
    try {
      return Color(int.parse(color!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData get iconData {
    if (icon == null) return Icons.emoji_events;

    final iconMap = {
      'sports_kabaddi': Icons.sports_kabaddi,
      'emoji_events': Icons.emoji_events,
      'military_tech': Icons.military_tech,
      'workspace_premium': Icons.workspace_premium,
      'stars': Icons.stars,
      'auto_awesome': Icons.auto_awesome,
    };

    return iconMap[icon] ?? Icons.emoji_events;
  }

  @override
  String toString() => 'RankModel(name: $name, displayName: $displayName, minPoints: $minPoints)';
}