import '../../../domain/models/notification_entity.dart';
import 'i_notification_repository.dart';
import '../../services/notification/i_notification_service.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  final INotificationService _service;

  NotificationRepositoryImpl(this._service);

  @override
  Future<void> initialize() {
    return _service.initialize();
  }

  @override
  Future<bool> getNotificationsEnabled() {
    return _service.getNotificationsEnabled();
  }

  @override
  Future<void> saveNotificationsEnabled(bool enabled) {
    return _service.saveNotificationsEnabled(enabled);
  }

  @override
  Future<bool> requestPermissions() {
    return _service.requestPermissions();
  }

  @override
  Future<String?> getFcmToken() {
    return _service.getFcmToken();
  }

  @override
  Future<void> syncDeviceToken({
    required String userId,
    required bool enabled,
  }) {
    return _service.syncDeviceToken(
      userId: userId,
      enabled: enabled,
    );
  }

  @override
  Future<void> clearDeviceToken({
    required String userId,
    bool keepPreference = false,
  }) {
    return _service.clearDeviceToken(
      userId: userId,
      keepPreference: keepPreference,
    );
  }

  @override
  Stream<NotificationModel> watchForegroundPushMessages() {
    return _service.watchForegroundPushMessages();
  }

  @override
  Stream<String> watchTokenRefresh() {
    return _service.watchTokenRefresh();
  }

  @override
  Stream<List<NotificationModel>> watchUserNotifications(
    List<String> userIdentifiers,
  ) {
    return _service.watchUserNotifications(userIdentifiers);
  }

  @override
  Future<List<NotificationModel>> fetchUserNotifications(
    List<String> userIdentifiers,
  ) {
    return _service.fetchUserNotifications(userIdentifiers);
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _service.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead(List<String> userIdentifiers) {
    return _service.markAllAsRead(userIdentifiers);
  }

  @override
  Future<void> deleteNotification(String notificationId) {
    return _service.deleteNotification(notificationId);
  }

  @override
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    return _service.showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
}