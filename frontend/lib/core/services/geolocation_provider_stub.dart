import 'dart:async';

// Modelo de lectura de ubicacion GPS en tiempo real
class LecturaGpsUsuario {
  final double latitud;
  final double longitud;
  final double precisionMetros;

  const LecturaGpsUsuario({
    required this.latitud,
    required this.longitud,
    required this.precisionMetros,
  });
}

// Implementacion base para entornos sin geolocalizacion disponible o pruebas
class GeolocationPlatformProvider {
  StreamController<LecturaGpsUsuario>? _controller;

  // Informa que el GPS no esta disponible y deja la app en modo manual
  Stream<LecturaGpsUsuario> observarUbicacion({
    required void Function(bool permisoDenegado, String mensaje) onError,
  }) {
    detenerObservacion();
    final StreamController<LecturaGpsUsuario> controller =
        StreamController<LecturaGpsUsuario>();
    _controller = controller;
    Timer.run(() {
      onError(
        false,
        'Geolocalizacion nativa en modo manual para este dispositivo.',
      );
      if (!controller.isClosed) {
        controller.close();
      }
    });
    return controller.stream;
  }

  // Cierra el controlador activo para no dejar recursos abiertos
  void detenerObservacion() {
    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
    }
    _controller = null;
  }
}
