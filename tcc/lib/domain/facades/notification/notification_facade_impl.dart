import '../../models/notification_entity.dart';
import '../../usecases/notifications/i_notification_usecases.dart';
import 'i_notification_facade.dart';

class NotificationFacadeImpl implements INotificationFacade {
  final IInitializeNotificationsUseCase _initializeNotificationsUseCase;
  final IToggleNotificationsUseCase _toggleNotificationsUseCase;
  final ISyncNotificationTokenUseCase _syncNotificationTokenUseCase;
  final IClearNotificationTokenUseCase _clearNotificationTokenUseCase;
  final IWatchUserNotificationsUseCase _watchUserNotificationsUseCase;
  final IFetchUserNotificationsUseCase _fetchUserNotificationsUseCase;
  final IWatchForegroundPushMessagesUseCase _watchForegroundPushMessagesUseCase;
  final IWatchNotificationTokenRefreshUseCase
      _watchNotificationTokenRefreshUseCase;
  final IMarkNotificationAsReadUseCase _markNotificationAsReadUseCase;
  final IMarkAllNotificationsAsReadUseCase _markAllNotificationsAsReadUseCase;
  final IDeleteNotificationUseCase _deleteNotificationUseCase;
  final IShowLocalNotificationUseCase _showLocalNotificationUseCase;

  NotificationFacadeImpl(
    this._initializeNotificationsUseCase,
    this._toggleNotificationsUseCase,
    this._syncNotificationTokenUseCase,
    this._clearNotificationTokenUseCase,
    this._watchUserNotificationsUseCase,
    this._fetchUserNotificationsUseCase,
    this._watchForegroundPushMessagesUseCase,
    this._watchNotificationTokenRefreshUseCase,
    this._markNotificationAsReadUseCase,
    this._markAllNotificationsAsReadUseCase,
    this._deleteNotificationUseCase,
    this._showLocalNotificationUseCase,
  );

  @override
  Future<bool> initializeNotifications() {
    return _initializeNotificationsUseCase();
  }

  @override
  Future<bool> toggleNotifications({
    required bool enable,
    String? userId,
  }) {
    return _toggleNotificationsUseCase(
      enable: enable,
      userId: userId,
    );
  }

  @override
  Future<bool> syncNotificationToken({
    required String userId,
    bool requestPermission = true,
  }) {
    return _syncNotificationTokenUseCase(
      userId: userId,
      requestPermission: requestPermission,
    );
  }

  @override
  Future<void> clearNotificationToken({
    required String userId,
    bool keepPreference = true,
  }) {
    return _clearNotificationTokenUseCase(
      userId: userId,
      keepPreference: keepPreference,
    );
  }

  @override
  Stream<List<NotificationModel>> watchUserNotifications(
    List<String> userIdentifiers,
  ) {
    return _watchUserNotificationsUseCase(userIdentifiers);
  }

  @override
  Future<List<NotificationModel>> fetchUserNotifications(
    List<String> userIdentifiers,
  ) {
    return _fetchUserNotificationsUseCase(userIdentifiers);
  }

  @override
  Stream<NotificationModel> watchForegroundPushMessages() {
    return _watchForegroundPushMessagesUseCase();
  }

  @override
  Stream<String> watchTokenRefresh() {
    return _watchNotificationTokenRefreshUseCase();
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _markNotificationAsReadUseCase(notificationId);
  }

  @override
  Future<void> markAllAsRead(List<String> userIdentifiers) {
    return _markAllNotificationsAsReadUseCase(userIdentifiers);
  }

  @override
  Future<void> deleteNotification(String notificationId) {
    return _deleteNotificationUseCase(notificationId);
  }

  @override
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    return _showLocalNotificationUseCase(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
}