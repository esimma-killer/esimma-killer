import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'geolocation_provider_stub.dart';

export 'geolocation_provider_stub.dart' show LecturaGpsUsuario;

@JS('window.navigator.geolocation')
external JSObject? get _navigatorGeolocation;

// Proveedor web que consume la API oficial navigator.geolocation.watchPosition del navegador
class GeolocationPlatformProvider {
  int? _watchId;
  StreamController<LecturaGpsUsuario>? _controller;

  // Solicita permiso de ubicacion al navegador y emite coordenadas en tiempo real conforme avanza el usuario
  Stream<LecturaGpsUsuario> observarUbicacion({
    required void Function(bool permisoDenegado, String mensaje) onError,
  }) {
    detenerObservacion();
    final StreamController<LecturaGpsUsuario> controller =
        StreamController<LecturaGpsUsuario>.broadcast();
    _controller = controller;

    final JSObject? geo = _navigatorGeolocation;
    if (geo == null) {
      Timer.run(() {
        onError(false, 'El navegador no soporta geolocalizacion en tiempo real.');
      });
      return controller.stream;
    }

    final JSFunction onSuccess = ((JSObject pos) {
      final JSObject? coords = pos.getProperty<JSObject?>('coords'.toJS);
      if (coords == null) {
        return;
      }
      final double? lat =
          coords.getProperty<JSNumber?>('latitude'.toJS)?.toDartDouble;
      final double? lng =
          coords.getProperty<JSNumber?>('longitude'.toJS)?.toDartDouble;
      final double acc =
          coords.getProperty<JSNumber?>('accuracy'.toJS)?.toDartDouble ?? 15.0;

      if (lat != null && lng != null && !controller.isClosed) {
        controller.add(
          LecturaGpsUsuario(
            latitud: lat,
            longitud: lng,
            precisionMetros: acc,
          ),
        );
      }
    }).toJS;

    final JSFunction onErr = ((JSObject err) {
      final int code = err.getProperty<JSNumber?>('code'.toJS)?.toDartInt ?? 1;
      final bool denegado = code == 1;
      onError(
        denegado,
        denegado
            ? 'Permiso de ubicacion denegado. Modo manual activado.'
            : 'No se pudo obtener la senal GPS. Modo manual activado.',
      );
    }).toJS;

    final JSObject options = JSObject()
      ..setProperty('enableHighAccuracy'.toJS, true.toJS)
      ..setProperty('maximumAge'.toJS, 2000.toJS)
      ..setProperty('timeout'.toJS, 12000.toJS);

    try {
      final JSNumber? id = geo.callMethod<JSNumber?>(
        'watchPosition'.toJS,
        onSuccess,
        onErr,
        options,
      );
      _watchId = id?.toDartInt;
    } catch (_) {
      Timer.run(() {
        onError(false, 'No fue posible iniciar la geolocalizacion del navegador.');
      });
    }

    return controller.stream;
  }

  // Libera el watchPosition activo en el navegador
  void detenerObservacion() {
    final JSObject? geo = _navigatorGeolocation;
    if (geo != null && _watchId != null) {
      try {
        geo.callMethod<JSAny?>('clearWatch'.toJS, _watchId!.toJS);
      } catch (_) {}
    }
    _watchId = null;
    _controller?.close();
    _controller = null;
  }
}
