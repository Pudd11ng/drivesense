import 'package:flutter/services.dart';

class NetworkBinder {
  static const MethodChannel _channel = MethodChannel('network_binder');

  /// Binds this app’s network traffic to Wi-Fi only.
  static Future<void> bindWifi() async {
    await _channel.invokeMethod('bindWifi');
  }

  /// Restores normal network routing (cellular or default).
  static Future<void> unbind() async {
    await _channel.invokeMethod('unbind');
  }

  static Future<bool> isWifiBound() async {
    try {
      return await _channel.invokeMethod('isWifiBound') ?? false;
    } catch (e) {
      return false;
    }
  }
}
