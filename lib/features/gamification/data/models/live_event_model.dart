class LiveEventModel {
  final String id;
  final String title;
  final String? description;
  final String status; // 'scheduled' | 'live' | 'ended'
  final String? hostName;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const LiveEventModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.hostName,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
  });

  factory LiveEventModel.fromJson(Map<String, dynamic> json) {
    return LiveEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'scheduled',
      hostName: json['host_name'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }

  bool get isLive => status == 'live';

  @override
  String toString() => 'LiveEventModel(title: $title, status: $status)';
}