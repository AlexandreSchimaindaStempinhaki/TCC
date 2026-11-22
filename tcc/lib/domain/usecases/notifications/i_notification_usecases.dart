import '../../models/notification_entity.dart';

abstract class IInitializeNotificationsUseCase {
  Future<bool> call();
}

abstract class IToggleNotificationsUseCase {
  Future<bool> call({
    required bool enable,
    String? userId,
  });
}

abstract class ISyncNotificationTokenUseCase {
  Future<bool> call({
    required String userId,
    bool requestPermission = true,
  });
}

abstract class IClearNotificationTokenUseCase {
  Future<void> call({
    required String userId,
    bool keepPreference = true,
  });
}

abstract class IWatchUserNotificationsUseCase {
  Stream<List<NotificationModel>> call(List<String> userIdentifiers);
}

abstract class IFetchUserNotificationsUseCase {
  Future<List<NotificationModel>> call(List<String> userIdentifiers);
}

abstract class IWatchForegroundPushMessagesUseCase {
  Stream<NotificationModel> call();
}

abstract class IWatchNotificationTokenRefreshUseCase {
  Stream<String> call();
}

abstract class IMarkNotificationAsReadUseCase {
  Future<void> call(String notificationId);
}

abstract class IMarkAllNotificationsAsReadUseCase {
  Future<void> call(List<String> userIdentifiers);
}

abstract class IDeleteNotificationUseCase {
  Future<void> call(String notificationId);
}

abstract class IShowLocalNotificationUseCase {
  Future<void> call({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
}