import '../../models/notification_entity.dart';

abstract class INotificationFacade {
  Future<bool> initializeNotifications();

  Future<bool> toggleNotifications({
    required bool enable,
    String? userId,
  });

  Future<bool> syncNotificationToken({
    required String userId,
    bool requestPermission = true,
  });

  Future<void> clearNotificationToken({
    required String userId,
    bool keepPreference = true,
  });

  Stream<List<NotificationModel>> watchUserNotifications(
    List<String> userIdentifiers,
  );

  Future<List<NotificationModel>> fetchUserNotifications(
    List<String> userIdentifiers,
  );

  Stream<NotificationModel> watchForegroundPushMessages();

  Stream<String> watchTokenRefresh();

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