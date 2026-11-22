import '../../../domain/facades/notification/i_notification_facade.dart';
import '../../commands/notification_commands.dart';
import 'notification_state_viewmodel.dart';
import 'notification_viewmodel_commands.dart';

class NotificationViewModel {
  final INotificationFacade _facade;

  late final NotificationState state;
  late final NotificationViewModelCommands commands;

  late final InitializeNotificationsCommand initializeNotificationsCommand;
  late final ToggleNotificationsCommand toggleNotificationsCommand;
  late final SyncNotificationTokenCommand syncNotificationTokenCommand;
  late final ClearNotificationTokenCommand clearNotificationTokenCommand;
  late final WatchUserNotificationsCommand watchUserNotificationsCommand;
  late final FetchUserNotificationsCommand fetchUserNotificationsCommand;
  late final WatchForegroundPushMessagesCommand
      watchForegroundPushMessagesCommand;
  late final WatchNotificationTokenRefreshCommand
      watchNotificationTokenRefreshCommand;
  late final MarkNotificationAsReadCommand markNotificationAsReadCommand;
  late final MarkAllNotificationsAsReadCommand
      markAllNotificationsAsReadCommand;
  late final DeleteNotificationCommand deleteNotificationCommand;
  late final ShowLocalNotificationCommand showLocalNotificationCommand;

  NotificationViewModel(this._facade) {
    state = NotificationState();
    initializeNotificationsCommand = InitializeNotificationsCommand(_facade);
    toggleNotificationsCommand = ToggleNotificationsCommand(_facade);
    syncNotificationTokenCommand = SyncNotificationTokenCommand(_facade);
    clearNotificationTokenCommand = ClearNotificationTokenCommand(_facade);
    watchUserNotificationsCommand = WatchUserNotificationsCommand(_facade);
    fetchUserNotificationsCommand = FetchUserNotificationsCommand(_facade);
    watchForegroundPushMessagesCommand =
        WatchForegroundPushMessagesCommand(_facade);
    watchNotificationTokenRefreshCommand =
        WatchNotificationTokenRefreshCommand(_facade);
    markNotificationAsReadCommand = MarkNotificationAsReadCommand(_facade);
    markAllNotificationsAsReadCommand =
        MarkAllNotificationsAsReadCommand(_facade);
    deleteNotificationCommand = DeleteNotificationCommand(_facade);
    showLocalNotificationCommand = ShowLocalNotificationCommand(_facade);
    commands = NotificationViewModelCommands(this);
  }
}