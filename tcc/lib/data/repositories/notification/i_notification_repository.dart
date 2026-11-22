import '../../../domain/models/notification_entity.dart';

abstract class INotificationRepository {
  Future<void> initialize();

  Future<bool> getNotificationsEnabled();
  Future<void> saveNotificationsEnabled(bool enabled);

  Future<bool> requestPermissions();

  Future<String?> getFcmToken();
  Future<void> syncDeviceToken({
    required String userId,
    required bool enabled,
  });
  Future<void> clearDeviceToken({
    required String userId,
    bool keepPreference = false,
  });

  Stream<NotificationModel> watchForegroundPushMessages();
  Stream<String> watchTokenRefresh();

  Stream<List<NotificationModel>> watchUserNotifications(
    List<String> userIdentifiers,
  );
  Future<List<NotificationModel>> fetchUserNotifications(
    List<String> userIdentifiers,
  );
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(List<String> userIdentifiers);
  Future<void> deleteNotification(String notificationId);

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
}