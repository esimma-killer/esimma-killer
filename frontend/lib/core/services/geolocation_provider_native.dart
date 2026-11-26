import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'geolocation_provider_stub.dart';

export 'geolocation_provider_stub.dart' show LecturaGpsUsuario;

// Proveedor nativo que usa geolocator en Android, Windows y escritorio compatible
class GeolocationPlatformProvider {
  StreamController<LecturaGpsUsuario>? _controller;
  StreamSubscription<Position>? _suscripcion;
  bool _cancelado = false;

  // Solicita permiso de ubicacion y emite lecturas GPS reales del dispositivo
  Stream<LecturaGpsUsuario> observarUbicacion({
    required void Function(bool permisoDenegado, String mensaje) onError,
  }) {
    detenerObservacion();
    _cancelado = false;
    final StreamController<LecturaGpsUsuario> controller =
        StreamController<LecturaGpsUsuario>.broadcast();
    _controller = controller;
    _iniciarSeguimiento(controller, onError);
    return controller.stream;
  }

  // Configura servicios, permisos y el flujo continuo de posiciones del sistema
  Future<void> _iniciarSeguimiento(
    StreamController<LecturaGpsUsuario> controller,
    void Function(bool permisoDenegado, String mensaje) onError,
  ) async {
    try {
      final bool servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (_cancelado) {
        return;
      }
      if (!servicioActivo) {
        onError(
          false,
          'Activa el servicio de ubicacion del dispositivo para usar el GPS.',
        );
        await controller.close();
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (_cancelado) {
        return;
      }
      if (permiso == LocationPermission.denied) {
        onError(true, 'Permiso de ubicacion denegado. Usa el modo manual.');
        await controller.close();
        return;
      }
      if (permiso == LocationPermission.deniedForever) {
        onError(
          true,
          'Permiso de ubicacion denegado permanentemente. Usa el modo manual o habilitalo en Ajustes.',
        );
        await controller.close();
        return;
      }

      const LocationSettings settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      );
      _suscripcion = Geolocator.getPositionStream(locationSettings: settings)
          .listen(
            (Position posicion) {
              if (!controller.isClosed) {
                controller.add(
                  LecturaGpsUsuario(
                    latitud: posicion.latitude,
                    longitud: posicion.longitude,
                    precisionMetros: posicion.accuracy,
                  ),
                );
              }
            },
            onError: (Object error) {
              onError(
                false,
                'No se pudo obtener la senal GPS. Usa el modo manual.',
              );
              controller.close();
            },
          );
    } catch (_) {
      onError(
        false,
        'El GPS no esta disponible en este dispositivo. Usa el modo manual.',
      );
      await controller.close();
    }
  }

  // Cancela la suscripcion nativa y libera el controlador
  void detenerObservacion() {
    _cancelado = true;
    _suscripcion?.cancel();
    _suscripcion = null;
    _controller?.close();
    _controller = null;
  }
}
