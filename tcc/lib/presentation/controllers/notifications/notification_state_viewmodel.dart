import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/notification_entity.dart';

class NotificationState {
  final notifications = signal<List<NotificationModel>>([]);
  final isEnabled = signal<bool>(false);
  final isLoading = signal<bool>(false);
  final isToggling = signal<bool>(false);
  final message = signal<String?>(null);

  late final unreadNotifications = computed(
    () => notifications.value.where((n) => !n.isRead).toList(),
  );

  late final unreadCount = computed(() => unreadNotifications.value.length);

  late final hasUnread = computed(() => unreadCount.value > 0);

  void clearMessage() => message.value = null;

  void clearNotifications() {
    notifications.value = const [];
  }
}
