import 'dart:io';
import 'package:signals_flutter/signals_flutter.dart';

class NetworkStatusService {
  NetworkStatusService._();

  static final Signal<bool> isConnected = signal<bool>(true);
  static DateTime? _lastCheck;
  static Future<bool>? _inFlightCheck;

  static Future<bool> checkConnection({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastCheck != null &&
        now.difference(_lastCheck!).inSeconds < 3) {
      return isConnected.value;
    }

    if (_inFlightCheck != null) return _inFlightCheck!;

    _inFlightCheck = _performLookup();
    final result = await _inFlightCheck!;
    _inFlightCheck = null;
    _lastCheck = DateTime.now();

    if (isConnected.value != result) {
      isConnected.value = result;
    }
    return result;
  }

  static Future<bool> _performLookup() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}