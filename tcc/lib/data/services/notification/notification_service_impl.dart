import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/notification_entity.dart';
import 'i_notification_service.dart';

/// Handler obrigatório de nível superior para pushes FCM com o app em segundo plano/fechado.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}

class NotificationServiceImpl implements INotificationService {
  static const String _prefKey = 'indigo_notifications_enabled';
  static const String _channelId = 'indigo_trip_alerts';
  static const String _channelName = 'Alertas de Viagem e Proximidade';
  static const String _channelDescription =
      'Avisos quando a van inicia a viagem ou se aproxima do seu ponto.';

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool _initialized = false;

  NotificationServiceImpl({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  CollectionReference get _usersCollection => _firestore.collection('users');

  List<String> _normalizeIdentifiers(List<String> raw) {
    final ids = <String>{};
    for (final item in raw) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) continue;
      ids.add(trimmed);
      final digits = trimmed.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) ids.add(digits);
    }
    return ids.take(10).toList();
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim()) ?? DateTime.now();
    }
    return DateTime.now();
  }

  NotificationModel? _fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) return null;
    final raw = doc.data();
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    final rawRead = map['isRead'];
    final isRead = rawRead is bool
        ? rawRead
        : (rawRead?.toString().toLowerCase() == 'true');

    return NotificationModel(
      id: (doc.id.trim().isNotEmpty ? doc.id : (map['id'] ?? '')).toString(),
      userId: (map['userId'] ?? '').toString(),
      tripId: map['tripId']?.toString(),
      routeId: map['routeId']?.toString(),
      title: (map['title'] ?? 'Atualização da Viagem').toString(),
      body: (map['body'] ?? '').toString(),
      type: (map['type'] ?? 'general').toString(),
      thresholdMinutes: map['thresholdMinutes'] != null
          ? int.tryParse(map['thresholdMinutes'].toString())
          : null,
      isRead: isRead,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(initSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefKey) ?? false;
    if (!saved) return false;

    // Se o usuário revogou a permissão nas configurações do Android, reflete como desligado
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final osEnabled = await androidPlugin?.areNotificationsEnabled();
    return osEnabled ?? true;
  }

  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

@override
  Future<bool> requestPermissions() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final alreadyEnabled = await androidPlugin.areNotificationsEnabled();
        debugPrint('[Notif] Android já habilitado antes do pedido: $alreadyEnabled');
        if (alreadyEnabled == true) return true;

        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('[Notif] Resultado do popup Android: $granted');

        if (granted == true) return true;

        final enabledAfter = await androidPlugin.areNotificationsEnabled();
        debugPrint('[Notif] Android habilitado após o pedido: $enabledAfter');
        return enabledAfter ?? false;
      }

      // iOS / outras plataformas
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[Notif] Status FCM: ${settings.authorizationStatus}');

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('[Notif] Erro ao solicitar permissão: $e');
      return false;
    }
  }

  @override
  Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Erro ao obter token FCM: $e');
      return null;
    }
  }

  @override
  Future<void> syncDeviceToken({
    required String userId,
    required bool enabled,
  }) async {
    final trimmedUid = userId.trim();
    if (trimmedUid.isEmpty) return;

    final token = enabled ? await getFcmToken() : null;
    try {
      await _usersCollection.doc(trimmedUid).set({
        'fcmToken': enabled && token != null ? token : FieldValue.delete(),
        'notificationsEnabled': enabled,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao sincronizar fcmToken no Firestore: $e');
    }
  }

  @override
  Future<void> clearDeviceToken({
    required String userId,
    bool keepPreference = false,
  }) async {
    try {
      await _messaging.deleteToken();
    } catch (_) {}

    final trimmedUid = userId.trim();
    if (trimmedUid.isEmpty) return;

    try {
      final payload = <String, dynamic>{
        'fcmToken': FieldValue.delete(),
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      };
      if (!keepPreference) {
        payload['notificationsEnabled'] = false;
      }
      await _usersCollection
          .doc(trimmedUid)
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao limpar fcmToken no Firestore: $e');
    }
  }

  @override
  Stream<NotificationModel> watchForegroundPushMessages() {
    return FirebaseMessaging.onMessage.map((message) {
      return NotificationModel(
        id:
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: (message.data['userId'] ?? '').toString(),
        tripId: message.data['tripId']?.toString(),
        routeId: message.data['routeId']?.toString(),
        title:
            message.notification?.title ??
            message.data['title']?.toString() ??
            'Atualização da Viagem',
        body:
            message.notification?.body ??
            message.data['body']?.toString() ??
            '',
        type: (message.data['type'] ?? 'push').toString(),
        thresholdMinutes: message.data['thresholdMinutes'] != null
            ? int.tryParse(message.data['thresholdMinutes'].toString())
            : null,
        isRead: false,
        createdAt: message.sentTime ?? DateTime.now(),
      );
    });
  }

  @override
  Stream<String> watchTokenRefresh() => _messaging.onTokenRefresh;

  @override
  Stream<List<NotificationModel>> watchUserNotifications(
    List<String> userIdentifiers,
  ) {
    final ids = _normalizeIdentifiers(userIdentifiers);
    if (ids.isEmpty) return Stream.value(const []);

    return _notificationsCollection
        .where('userId', whereIn: ids)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(_fromDoc)
              .whereType<NotificationModel>()
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  @override
  Future<List<NotificationModel>> fetchUserNotifications(
    List<String> userIdentifiers,
  ) async {
    final ids = _normalizeIdentifiers(userIdentifiers);
    if (ids.isEmpty) return const [];

    final snap = await _notificationsCollection
        .where('userId', whereIn: ids)
        .get();
    final list = snap.docs
        .map(_fromDoc)
        .whereType<NotificationModel>()
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final trimmed = notificationId.trim();
    if (trimmed.isEmpty) return;

    await _notificationsCollection.doc(trimmed).set({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> markAllAsRead(List<String> userIdentifiers) async {
    final ids = _normalizeIdentifiers(userIdentifiers);
    if (ids.isEmpty) return;

    final snap = await _notificationsCollection
        .where('userId', whereIn: ids)
        .get();
    final batch = _firestore.batch();
    bool hasUpdates = false;

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data?['isRead'] != true) {
        batch.set(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    final trimmed = notificationId.trim();
    if (trimmed.isEmpty) return;
    await _notificationsCollection.doc(trimmed).delete();
  }

  @override
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }
}
