import 'dart:math' as math;

import 'geolocation_provider_stub.dart'
    if (dart.library.io) 'geolocation_provider_native.dart'
    if (dart.library.js_interop) 'geolocation_provider_web.dart';

export 'geolocation_provider_stub.dart' show LecturaGpsUsuario;

// Estado actual del sistema de geolocalizacion en el mapa universitario
enum EstadoUbicacionMapaUaa {
  buscandoPermiso,
  dentroDelCampus,
  fueraDelCampus,
  permisoDenegadoManual,
  simulacionEnVivo,
}

// Entrada oficial sugerida cuando el usuario se encuentra fuera del poligono de la UAA
class EntradaSugeridaUaa {
  final String idNodoEdificio;
  final String nombreCorto;
  final String vialidadReferencia;
  final double latitudReal;
  final double longitudReal;
  final double posX;
  final double posY;

  const EntradaSugeridaUaa({
    required this.idNodoEdificio,
    required this.nombreCorto,
    required this.vialidadReferencia,
    required this.latitudReal,
    required this.longitudReal,
    required this.posX,
    required this.posY,
  });
}

// Resultado de proyectar una coordenada GPS real sobre los planos DGIU de la UAA
class ProyeccionUbicacionUaa {
  final bool estaDentroDelCampus;
  final int idCampusDetectado;
  final double posX;
  final double posY;
  final double distanciaAlCampusMetros;
  final EntradaSugeridaUaa entradaMasCercana;

  const ProyeccionUbicacionUaa({
    required this.estaDentroDelCampus,
    required this.idCampusDetectado,
    required this.posX,
    required this.posY,
    required this.distanciaAlCampusMetros,
    required this.entradaMasCercana,
  });
}

// Servicio que gestiona el GPS en tiempo real, proyeccion al plano UAA y sugerencia de entradas
class GeolocationServiceUaa {
  final GeolocationPlatformProvider _provider = GeolocationPlatformProvider();

  // Las 6 entradas oficiales de Campus Central marcadas en el plano DGIU (Acceso Principal siempre primero)
  static const List<EntradaSugeridaUaa> entradasCampusCentral =
      <EntradaSugeridaUaa>[
        EntradaSugeridaUaa(
          idNodoEdificio: 'CEN-B-ACCESO_SUR',
          nombreCorto: 'Acceso Principal (Av. Universidad)',
          vialidadReferencia:
              'Av. Universidad (frente a Infoteca y Control Escolar)',
          latitudReal: 21.9117,
          longitudReal: -102.3164,
          posX: 0.435,
          posY: 0.942,
        ),
        EntradaSugeridaUaa(
          idNodoEdificio: 'CEN-B-ACCESO_PONIENTE',
          nombreCorto: 'Acceso Poniente (Gpe. Gonzalez)',
          vialidadReferencia:
              'Calle Guadalupe Gonzalez (junto a Cafeteria 210 / 201)',
          latitudReal: 21.9154,
          longitudReal: -102.3186,
          posX: 0.165,
          posY: 0.658,
        ),
        EntradaSugeridaUaa(
          idNodoEdificio: 'CEN-B-ACCESO_NORTE',
          nombreCorto: 'Acceso Norte (Edif. 300)',
          vialidadReferencia:
              'Calle Guadalupe Gonzalez (junto a Edificios 310 y 324)',
          latitudReal: 21.9186,
          longitudReal: -102.3156,
          posX: 0.355,
          posY: 0.196,
        ),
        EntradaSugeridaUaa(
          idNodoEdificio: 'CEN-B-ACCESO_DEPORTIVA',
          nombreCorto: 'Acceso Unidad Deportiva',
          vialidadReferencia: 'Unidad Deportiva Prof. Enrique Olivares Santana',
          latitudReal: 21.9162,
          longitudReal: -102.3128,
          posX: 0.658,
          posY: 0.434,
        ),
        EntradaSugeridaUaa(
          idNodoEdificio: 'CEN-B-ACCESO_SALUD',
          nombreCorto: 'Acceso Salud (Edif. 101)',
          vialidadReferencia: 'Av. Universidad (Unidad Medico Didactica 101)',
          latitudReal: 21.9089,
          longitudReal: -102.3136,
          posX: 0.790,
          posY: 0.942,
        ),
        EntradaSugeridaUaa(
          idNodoEdificio: 'CEN-B-ACCESO_CCDC',
          nombreCorto: 'Acceso CCDC (Edif. 108)',
          vialidadReferencia:
              'Av. Universidad (Ciencias del Diseno y Construccion 108)',
          latitudReal: 21.9082,
          longitudReal: -102.3118,
          posX: 0.910,
          posY: 0.952,
        ),
      ];

  // Entradas peatonales oficiales de Campus Sur
  static const List<EntradaSugeridaUaa> entradasCampusSur =
      <EntradaSugeridaUaa>[
        EntradaSugeridaUaa(
          idNodoEdificio: 'SUR-B-ACCESO_SUR',
          nombreCorto: 'Plaza de Acceso Principal',
          vialidadReferencia: 'Prol. Mahatma Gandhi (Acceso Campus Sur)',
          latitudReal: 21.8205,
          longitudReal: -102.2795,
          posX: 0.892,
          posY: 0.225,
        ),
        EntradaSugeridaUaa(
          idNodoEdificio: 'SUR-B-2',
          nombreCorto: 'Acceso Servicios Estudiantiles',
          vialidadReferencia: 'Andador Oriente Campus Sur (Edificio 2)',
          latitudReal: 21.8201,
          longitudReal: -102.2806,
          posX: 0.795,
          posY: 0.484,
        ),
      ];

  // Obtiene las entradas sugeridas para el campus activo
  static List<EntradaSugeridaUaa> obtenerEntradasPorCampus(int idCampus) {
    return idCampus == 2 ? entradasCampusSur : entradasCampusCentral;
  }

  // Inicia el monitoreo GPS en tiempo real del navegador
  Stream<LecturaGpsUsuario> iniciarSeguimientoTiempoReal({
    required void Function(bool permisoDenegado, String mensaje) onError,
  }) {
    return _provider.observarUbicacion(onError: onError);
  }

  // Detiene el monitoreo GPS activo
  void detenerSeguimiento() {
    _provider.detenerObservacion();
  }

  // Calcula la distancia Haversine en metros entre dos coordenadas geograficas
  static double calcularDistanciaHaversineMetros(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double rTierra = 6371000.0;
    final double dLat = (lat2 - lat1) * math.pi / 180.0;
    final double dLng = (lng2 - lng1) * math.pi / 180.0;
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return rTierra * c;
  }

  // Convierte una lectura GPS (latitud, longitud) a coordenadas normalizadas (0..1) del plano UAA
  static ProyeccionUbicacionUaa proyectarGpsAlMapa({
    required double latitud,
    required double longitud,
    required int idCampusActivo,
  }) {
    final List<EntradaSugeridaUaa> entradas = obtenerEntradasPorCampus(
      idCampusActivo,
    );

    // 1. Determina cual de las entradas oficiales de la UAA esta mas cerca de la ubicacion real del usuario
    EntradaSugeridaUaa mejorEntrada = entradas.first;
    double menorDistEntrada = double.infinity;
    for (final EntradaSugeridaUaa e in entradas) {
      final double d = calcularDistanciaHaversineMetros(
        latitud,
        longitud,
        e.latitudReal,
        e.longitudReal,
      );
      if (d < menorDistEntrada) {
        menorDistEntrada = d;
        mejorEntrada = e;
      }
    }

    if (idCampusActivo == 1) {
      // Transformacion afin calibrada con el plano DGIU de Campus Central (rotado ~28 grados respecto al Norte)
      // Centro de referencia: Acceso Principal Av. Universidad (21.9117, -102.3164) -> (0.435, 0.942)
      final double dLat = latitud - 21.9117;
      final double dLng = longitud - (-102.3164);

      final double posX = 0.435 + (dLng * 82.0) - (dLat * 34.0);
      final double posY = 0.942 - (dLat * 76.0) - (dLng * 31.0);

      final bool dentroPoligono =
          posX >= 0.08 && posX <= 0.97 && posY >= 0.08 && posY <= 0.96;

      return ProyeccionUbicacionUaa(
        estaDentroDelCampus: dentroPoligono,
        idCampusDetectado: 1,
        posX: posX.clamp(0.04, 0.96),
        posY: posY.clamp(0.04, 0.96),
        distanciaAlCampusMetros: dentroPoligono ? 0.0 : menorDistEntrada,
        entradaMasCercana: mejorEntrada,
      );
    } else {
      // Transformacion calibrada con el plano DGIU de Campus Sur
      // Referencia: Plaza de Acceso Prol. Mahatma Gandhi (21.8205, -102.2795) -> (0.892, 0.225)
      final double dLat = latitud - 21.8205;
      final double dLng = longitud - (-102.2795);

      final double posX = 0.892 + (dLng * 98.0);
      final double posY = 0.225 - (dLat * 115.0);

      final bool dentroPoligono =
          posX >= 0.06 && posX <= 0.96 && posY >= 0.14 && posY <= 0.95;

      return ProyeccionUbicacionUaa(
        estaDentroDelCampus: dentroPoligono,
        idCampusDetectado: 2,
        posX: posX.clamp(0.06, 0.95),
        posY: posY.clamp(0.14, 0.95),
        distanciaAlCampusMetros: dentroPoligono ? 0.0 : menorDistEntrada,
        entradaMasCercana: mejorEntrada,
      );
    }
  }
}
