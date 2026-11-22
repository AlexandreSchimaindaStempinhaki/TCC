class NotificationModel {
  final String id;
  final String userId;
  final String? tripId;
  final String? routeId;
  final String title;
  final String body;
  final String type; // ex: 'trip_started', 'eta_alert', 'push'
  final int? thresholdMinutes;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.tripId,
    this.routeId,
    required this.title,
    required this.body,
    required this.type,
    this.thresholdMinutes,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? tripId,
    String? routeId,
    String? title,
    String? body,
    String? type,
    int? thresholdMinutes,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      routeId: routeId ?? this.routeId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      thresholdMinutes: thresholdMinutes ?? this.thresholdMinutes,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}