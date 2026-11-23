import 'dart:async';
import 'dart:io';
import 'package:signals_flutter/signals_flutter.dart';

class NetworkStatusService {
  NetworkStatusService._();

  static final Signal<bool> isConnected = signal<bool>(true);
  static DateTime? _lastCheck;
  static Future<bool>? _inFlightCheck;

  /// Atualiza o estado de conexão de forma segura (nunca trava ou deixa tela preta).
  static Future<bool> checkConnection({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastCheck != null &&
        now.difference(_lastCheck!).inMilliseconds < 2500) {
      return isConnected.value;
    }

    if (_inFlightCheck != null) {
      return _inFlightCheck!;
    }

    _inFlightCheck = _performCheck().whenComplete(() {
      _inFlightCheck = null;
      _lastCheck = DateTime.now();
    });

    final result = await _inFlightCheck!;
    if (isConnected.value != result) {
      isConnected.value = result;
    }
    return result;
  }

  /// Dispara uma verificação em segundo plano sem bloquear chamadas síncronas.
  static void checkInBackground({bool force = false}) {
    unawaited(checkConnection(force: force));
  }

  static Future<bool> _performCheck() async {
    try {
      final result = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 2));
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}