import '../../../data/repositories/notification/i_notification_repository.dart';
import '../../models/notification_entity.dart';
import 'i_notification_usecases.dart';

class InitializeNotificationsUseCaseImpl
    implements IInitializeNotificationsUseCase {
  final INotificationRepository _repository;

  InitializeNotificationsUseCaseImpl(this._repository);

  @override
  Future<bool> call() async {
    await _repository.initialize();
    return _repository.getNotificationsEnabled();
  }
}

class ToggleNotificationsUseCaseImpl implements IToggleNotificationsUseCase {
  final INotificationRepository _repository;

  ToggleNotificationsUseCaseImpl(this._repository);

  @override
  Future<bool> call({
    required bool enable,
    String? userId,
  }) async {
    final trimmedUid = userId?.trim() ?? '';

    if (enable) {
      final granted = await _repository.requestPermissions();
      if (!granted) {
        await _repository.saveNotificationsEnabled(false);
        if (trimmedUid.isNotEmpty) {
          await _repository.clearDeviceToken(
            userId: trimmedUid,
            keepPreference: false,
          );
        }
        return false;
      }

      await _repository.saveNotificationsEnabled(true);
      if (trimmedUid.isNotEmpty) {
        await _repository.syncDeviceToken(
          userId: trimmedUid,
          enabled: true,
        );
      }
      return true;
    }

    await _repository.saveNotificationsEnabled(false);
    if (trimmedUid.isNotEmpty) {
      await _repository.clearDeviceToken(
        userId: trimmedUid,
        keepPreference: false,
      );
    }
    return true;
  }
}

class SyncNotificationTokenUseCaseImpl
    implements ISyncNotificationTokenUseCase {
  final INotificationRepository _repository;

  SyncNotificationTokenUseCaseImpl(this._repository);

  @override
  Future<bool> call({
    required String userId,
    bool requestPermission = true,
  }) async {
    final trimmedUid = userId.trim();
    if (trimmedUid.isEmpty) return false;

    final isEnabled = await _repository.getNotificationsEnabled();
    if (!isEnabled) return false;

    if (requestPermission) {
      final granted = await _repository.requestPermissions();
      if (!granted) return false;
    }

    await _repository.syncDeviceToken(
      userId: trimmedUid,
      enabled: true,
    );
    return true;
  }
}

class ClearNotificationTokenUseCaseImpl
    implements IClearNotificationTokenUseCase {
  final INotificationRepository _repository;

  ClearNotificationTokenUseCaseImpl(this._repository);

  @override
  Future<void> call({
    required String userId,
    bool keepPreference = true,
  }) async {
    await _repository.clearDeviceToken(
      userId: userId.trim(),
      keepPreference: keepPreference,
    );
  }
}

class WatchUserNotificationsUseCaseImpl
    implements IWatchUserNotificationsUseCase {
  final INotificationRepository _repository;

  WatchUserNotificationsUseCaseImpl(this._repository);

  @override
  Stream<List<NotificationModel>> call(List<String> userIdentifiers) {
    return _repository.watchUserNotifications(userIdentifiers);
  }
}

class FetchUserNotificationsUseCaseImpl
    implements IFetchUserNotificationsUseCase {
  final INotificationRepository _repository;

  FetchUserNotificationsUseCaseImpl(this._repository);

  @override
  Future<List<NotificationModel>> call(List<String> userIdentifiers) {
    return _repository.fetchUserNotifications(userIdentifiers);
  }
}

class WatchForegroundPushMessagesUseCaseImpl
    implements IWatchForegroundPushMessagesUseCase {
  final INotificationRepository _repository;

  WatchForegroundPushMessagesUseCaseImpl(this._repository);

  @override
  Stream<NotificationModel> call() {
    return _repository.watchForegroundPushMessages();
  }
}

class WatchNotificationTokenRefreshUseCaseImpl
    implements IWatchNotificationTokenRefreshUseCase {
  final INotificationRepository _repository;

  WatchNotificationTokenRefreshUseCaseImpl(this._repository);

  @override
  Stream<String> call() {
    return _repository.watchTokenRefresh();
  }
}

class MarkNotificationAsReadUseCaseImpl
    implements IMarkNotificationAsReadUseCase {
  final INotificationRepository _repository;

  MarkNotificationAsReadUseCaseImpl(this._repository);

  @override
  Future<void> call(String notificationId) async {
    final trimmed = notificationId.trim();
    if (trimmed.isEmpty) return;
    await _repository.markAsRead(trimmed);
  }
}

class MarkAllNotificationsAsReadUseCaseImpl
    implements IMarkAllNotificationsAsReadUseCase {
  final INotificationRepository _repository;

  MarkAllNotificationsAsReadUseCaseImpl(this._repository);

  @override
  Future<void> call(List<String> userIdentifiers) async {
    if (userIdentifiers.isEmpty) return;
    await _repository.markAllAsRead(userIdentifiers);
  }
}

class DeleteNotificationUseCaseImpl implements IDeleteNotificationUseCase {
  final INotificationRepository _repository;

  DeleteNotificationUseCaseImpl(this._repository);

  @override
  Future<void> call(String notificationId) async {
    final trimmed = notificationId.trim();
    if (trimmed.isEmpty) return;
    await _repository.deleteNotification(trimmed);
  }
}

class ShowLocalNotificationUseCaseImpl
    implements IShowLocalNotificationUseCase {
  final INotificationRepository _repository;

  ShowLocalNotificationUseCaseImpl(this._repository);

  @override
  Future<void> call({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (title.trim().isEmpty && body.trim().isEmpty) return;

    final isEnabled = await _repository.getNotificationsEnabled();
    if (!isEnabled) return;

    await _repository.showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
}