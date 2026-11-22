import '../../../domain/models/notification_entity.dart';

abstract class INotificationService {
  /// Inicializa canais Android, plugin de notificações locais e opções de apresentação do FCM.
  Future<void> initialize();

  /// Lê e persiste a preferência local de notificações no dispositivo.
  Future<bool> getNotificationsEnabled();
  Future<void> saveNotificationsEnabled(bool enabled);

  /// Solicita permissão de notificações ao sistema operacional (Android 13+ / iOS).
  Future<bool> requestPermissions();

  /// Gerenciamento do token FCM vinculado ao documento do usuário no Firestore.
  Future<String?> getFcmToken();
  Future<void> syncDeviceToken({
    required String userId,
    required bool enabled,
  });
  Future<void> clearDeviceToken({
    required String userId,
    bool keepPreference = false,
  });

  /// Streams reativas do FCM (push em primeiro plano e renovação de token).
  Stream<NotificationModel> watchForegroundPushMessages();
  Stream<String> watchTokenRefresh();

  /// Leitura e manutenção dos alertas da coleção `notifications` no Firestore.
  Stream<List<NotificationModel>> watchUserNotifications(
    List<String> userIdentifiers,
  );
  Future<List<NotificationModel>> fetchUserNotifications(
    List<String> userIdentifiers,
  );
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(List<String> userIdentifiers);
  Future<void> deleteNotification(String notificationId);

  /// Exibe o banner/som local na barra de notificações do sistema.
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
}