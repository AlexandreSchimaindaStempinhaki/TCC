import '../../domain/facades/notification/i_notification_facade.dart';
import '../../domain/models/notification_entity.dart';

class InitializeNotificationsCommand {
  final INotificationFacade _facade;

  InitializeNotificationsCommand(this._facade);

  Future<bool> execute() => _facade.initializeNotifications();
}

class ToggleNotificationsCommand {
  final INotificationFacade _facade;

  ToggleNotificationsCommand(this._facade);

  Future<bool> execute({
    required bool enable,
    String? userId,
  }) {
    return _facade.toggleNotifications(
      enable: enable,
      userId: userId,
    );
  }
}

class SyncNotificationTokenCommand {
  final INotificationFacade _facade;

  SyncNotificationTokenCommand(this._facade);

  Future<bool> execute({
    required String userId,
    bool requestPermission = true,
  }) {
    return _facade.syncNotificationToken(
      userId: userId,
      requestPermission: requestPermission,
    );
  }
}

class ClearNotificationTokenCommand {
  final INotificationFacade _facade;

  ClearNotificationTokenCommand(this._facade);

  Future<void> execute({
    required String userId,
    bool keepPreference = true,
  }) {
    return _facade.clearNotificationToken(
      userId: userId,
      keepPreference: keepPreference,
    );
  }
}

class WatchUserNotificationsCommand {
  final INotificationFacade _facade;

  WatchUserNotificationsCommand(this._facade);

  Stream<List<NotificationModel>> execute(List<String> userIdentifiers) {
    return _facade.watchUserNotifications(userIdentifiers);
  }
}

class FetchUserNotificationsCommand {
  final INotificationFacade _facade;

  FetchUserNotificationsCommand(this._facade);

  Future<List<NotificationModel>> execute(List<String> userIdentifiers) {
    return _facade.fetchUserNotifications(userIdentifiers);
  }
}

class WatchForegroundPushMessagesCommand {
  final INotificationFacade _facade;

  WatchForegroundPushMessagesCommand(this._facade);

  Stream<NotificationModel> execute() {
    return _facade.watchForegroundPushMessages();
  }
}

class WatchNotificationTokenRefreshCommand {
  final INotificationFacade _facade;

  WatchNotificationTokenRefreshCommand(this._facade);

  Stream<String> execute() {
    return _facade.watchTokenRefresh();
  }
}

class MarkNotificationAsReadCommand {
  final INotificationFacade _facade;

  MarkNotificationAsReadCommand(this._facade);

  Future<void> execute(String notificationId) {
    return _facade.markAsRead(notificationId);
  }
}

class MarkAllNotificationsAsReadCommand {
  final INotificationFacade _facade;

  MarkAllNotificationsAsReadCommand(this._facade);

  Future<void> execute(List<String> userIdentifiers) {
    return _facade.markAllAsRead(userIdentifiers);
  }
}

class DeleteNotificationCommand {
  final INotificationFacade _facade;

  DeleteNotificationCommand(this._facade);

  Future<void> execute(String notificationId) {
    return _facade.deleteNotification(notificationId);
  }
}

class ShowLocalNotificationCommand {
  final INotificationFacade _facade;

  ShowLocalNotificationCommand(this._facade);

  Future<void> execute({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    return _facade.showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
}