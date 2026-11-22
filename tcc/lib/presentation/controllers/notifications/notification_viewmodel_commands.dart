import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/notification_entity.dart';
import 'notification_viewmodel.dart';

class NotificationViewModelCommands {
  final NotificationViewModel _viewModel;
  final FirebaseAuth _auth;

  bool _initialized = false;
  String? _activeUserId;
  String? _activeCpf;
  bool _isFirstSnapshot = true;

  final Set<String> _shownNotificationIds = {};

  StreamSubscription<User?>? _authSub;
  StreamSubscription<NotificationModel>? _foregroundPushSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<List<NotificationModel>>? _userNotificationsSub;

  NotificationViewModelCommands(
    this._viewModel, {
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  List<String> _buildUserIdentifiers({String? userId, String? cpf}) {
    final uid = (userId ?? _activeUserId ?? _auth.currentUser?.uid ?? '').trim();
    final docCpf = (cpf ?? _activeCpf ?? '').trim();

    final ids = <String>{};
    if (uid.isNotEmpty) ids.add(uid);
    if (docCpf.isNotEmpty) {
      ids.add(docCpf);
      final digits = docCpf.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) ids.add(digits);
    }
    return ids.toList();
  }

  /// Inicializa canais locais, preferência salva e listeners de sessão/FCM.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _viewModel.state.clearMessage();
    try {
      final isEnabled =
          await _viewModel.initializeNotificationsCommand.execute();
      _viewModel.state.isEnabled.value = isEnabled;

      _foregroundPushSub?.cancel();
      _foregroundPushSub =
          _viewModel.watchForegroundPushMessagesCommand.execute().listen(
        (push) {
          if (!_viewModel.state.isEnabled.value) return;
          if (push.body.trim().isEmpty && push.title.trim().isEmpty) return;

          _viewModel.showLocalNotificationCommand.execute(
            id: push.id.hashCode & 0x7fffffff,
            title: push.title,
            body: push.body,
            payload: push.tripId,
          );
        },
        onError: (e) {
          debugPrint('Erro ao escutar pushes FCM: $e');
        },
      );

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub =
          _viewModel.watchNotificationTokenRefreshCommand.execute().listen(
        (_) {
          final uid = _activeUserId ?? _auth.currentUser?.uid;
          if (uid != null &&
              uid.isNotEmpty &&
              _viewModel.state.isEnabled.value) {
            _viewModel.syncNotificationTokenCommand.execute(
              userId: uid,
              requestPermission: false,
            );
          }
        },
      );

      _authSub?.cancel();
      _authSub = _auth.authStateChanges().listen((user) {
        if (user == null) {
          stopWatchingNotifications();
          _activeUserId = null;
          _activeCpf = null;
          _shownNotificationIds.clear();
          _viewModel.state.clearNotifications();
        } else {
          _activeUserId = user.uid;
          if (_viewModel.state.isEnabled.value) {
            syncUserSession(userId: user.uid, cpf: _activeCpf);
          }
        }
      });

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _activeUserId = currentUser.uid;
        if (isEnabled) {
          await syncUserSession(userId: currentUser.uid, cpf: _activeCpf);
        }
      }
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao inicializar notificações: $e';
    }
  }

  /// Sincroniza token FCM e inicia a escuta em tempo real das notificações do usuário.
  Future<void> syncUserSession({
    String? userId,
    String? cpf,
    bool requestPermission = true,
  }) async {
    final uid = (userId ?? _auth.currentUser?.uid ?? '').trim();
    if (uid.isNotEmpty) _activeUserId = uid;
    if (cpf != null && cpf.trim().isNotEmpty) _activeCpf = cpf.trim();

    if (!_viewModel.state.isEnabled.value) return;

    if (_activeUserId != null && _activeUserId!.isNotEmpty) {
      try {
        await _viewModel.syncNotificationTokenCommand.execute(
          userId: _activeUserId!,
          requestPermission: requestPermission,
        );
      } catch (e) {
        debugPrint('Erro ao sincronizar token FCM: $e');
      }
    }

    startWatchingNotifications();
  }

  /// Liga ou desliga notificações pela tela de Configurações.
  /// Retorna `false` caso a permissão do sistema operacional tenha sido negada.
  Future<bool> toggleNotifications({
    required bool enable,
    String? userId,
    String? cpf,
  }) async {
    if (_viewModel.state.isToggling.value) return true;

    _viewModel.state.clearMessage();
    _viewModel.state.isToggling.value = true;

    final uid = (userId ?? _activeUserId ?? _auth.currentUser?.uid ?? '').trim();
    if (uid.isNotEmpty) _activeUserId = uid;
    if (cpf != null && cpf.trim().isNotEmpty) _activeCpf = cpf.trim();

    try {
      final result = await _viewModel.toggleNotificationsCommand.execute(
        enable: enable,
        userId: uid.isNotEmpty ? uid : null,
      );

      if (enable && !result) {
        _viewModel.state.isEnabled.value = false;
        stopWatchingNotifications();
        _viewModel.state.message.value =
            'Permissão de notificações bloqueada no dispositivo.';
        return false;
      }

      _viewModel.state.isEnabled.value = enable;

      if (enable) {
        startWatchingNotifications();
      } else {
        stopWatchingNotifications();
      }

      return true;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao atualizar preferência de notificações: $e';
      return false;
    } finally {
      _viewModel.state.isToggling.value = false;
    }
  }

  /// Escuta a coleção `notifications` e dispara o banner local para novos alertas de viagem/ETA.
  void startWatchingNotifications() {
    _userNotificationsSub?.cancel();

    if (!_viewModel.state.isEnabled.value) return;
    final identifiers = _buildUserIdentifiers();
    if (identifiers.isEmpty) return;

    _isFirstSnapshot = true;

    _userNotificationsSub =
        _viewModel.watchUserNotificationsCommand.execute(identifiers).listen(
      (list) {
        _viewModel.state.notifications.value = list;
        _triggerLocalAlertsForNewItems(list);
        _isFirstSnapshot = false;
      },
      onError: (e) {
        _viewModel.state.message.value =
            'Erro ao acompanhar notificações em tempo real: $e';
      },
    );
  }

  void _triggerLocalAlertsForNewItems(List<NotificationModel> items) {
    if (!_viewModel.state.isEnabled.value) return;
    final now = DateTime.now();

    for (final item in items) {
      if (item.isRead || _shownNotificationIds.contains(item.id)) continue;

      final ageMinutes = now.difference(item.createdAt).inMinutes;

      // Na primeira carga, evita disparar notificações antigas acumuladas no histórico.
      if (_isFirstSnapshot && ageMinutes > 3) {
        _shownNotificationIds.add(item.id);
        continue;
      }

      _shownNotificationIds.add(item.id);

      if (item.body.trim().isEmpty && item.title.trim().isEmpty) continue;

      _viewModel.showLocalNotificationCommand.execute(
        id: item.id.hashCode & 0x7fffffff,
        title: item.title,
        body: item.body,
        payload: item.tripId,
      );
    }
  }

  void stopWatchingNotifications() {
    _userNotificationsSub?.cancel();
    _userNotificationsSub = null;
  }

  Future<void> fetchNotifications() async {
    final identifiers = _buildUserIdentifiers();
    if (identifiers.isEmpty) return;

    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final list =
          await _viewModel.fetchUserNotificationsCommand.execute(identifiers);
      _viewModel.state.notifications.value = list;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao buscar notificações: $e';
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _viewModel.markNotificationAsReadCommand.execute(notificationId);
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao marcar notificação como lida: $e';
    }
  }

  Future<void> markAllAsRead() async {
    final identifiers = _buildUserIdentifiers();
    if (identifiers.isEmpty) return;

    try {
      await _viewModel.markAllNotificationsAsReadCommand.execute(identifiers);
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao marcar notificações como lidas: $e';
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _viewModel.deleteNotificationCommand.execute(notificationId);
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao excluir notificação: $e';
    }
  }

  /// Limpa o token do aparelho e encerra a escuta antes do signOut.
  Future<void> onSignOut() async {
    stopWatchingNotifications();
    final uid = (_activeUserId ?? _auth.currentUser?.uid ?? '').trim();
    if (uid.isNotEmpty) {
      try {
        await _viewModel.clearNotificationTokenCommand.execute(
          userId: uid,
          keepPreference: true,
        );
      } catch (_) {}
    }
    _activeUserId = null;
    _activeCpf = null;
    _shownNotificationIds.clear();
    _viewModel.state.clearNotifications();
  }

  void dispose() {
    _authSub?.cancel();
    _foregroundPushSub?.cancel();
    _tokenRefreshSub?.cancel();
    _userNotificationsSub?.cancel();
  }
}