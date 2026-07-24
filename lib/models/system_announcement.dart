class SystemAnnouncement {
  final String id;
  final String message;
  final String type; // 'info', 'warning', 'success'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  SystemAnnouncement({
    required this.id,
    required this.message,
    this.type = 'info',
    this.isActive = true,
    required this.createdAt,
    this.expiresAt,
  });

  factory SystemAnnouncement.fromJson(Map<String, dynamic> json) {
    return SystemAnnouncement(
      id: json['id'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'info',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }
}
