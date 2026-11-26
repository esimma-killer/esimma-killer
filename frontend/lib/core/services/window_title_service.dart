import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Cambia el titulo de la ventana nativa en Windows desde Flutter
class WindowTitleService {
  const WindowTitleService();

  static const MethodChannel _channel = MethodChannel('uaa/window_title');

  Future<void> actualizar(String titulo) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setTitle', titulo);
    } catch (_) {
      // La ventana no esta disponible o el canal no esta registrado.
    }
  }
}
