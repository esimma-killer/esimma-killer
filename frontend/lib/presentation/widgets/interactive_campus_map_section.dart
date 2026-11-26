import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/geolocation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/campus_vector_layers.dart';
import '../../data/repositories/portal_repository.dart';
import '../../domain/entities/portal_models.dart';

// Navegador interactivo a pantalla completa con estructura estilo Google Maps y vectorizacion 1:1 completa
class InteractiveCampusMapSection extends StatefulWidget {
  final PortalRepository repository;
  final int initialCampusId;
  final VoidCallback? onBackToHome;

  const InteractiveCampusMapSection({
    super.key,
    required this.repository,
    this.initialCampusId = 1,
    this.onBackToHome,
  });

  @override
  State<InteractiveCampusMapSection> createState() =>
      _InteractiveCampusMapSectionState();
}

class _InteractiveCampusMapSectionState
    extends State<InteractiveCampusMapSection> {
  late int _idCampusMapa;
  late String _idNodoOrigen;
  late String _idNodoDestino;
  String? _idNodoHover;
  String _busquedaTexto = '';
  String _categoriaFiltroActiva = '';
  bool _mostrarSugerencias = false;
  bool _mostrarPanelRutas = false;
  bool _modoVectorialEstilizado = true;
  bool _zoomInicialAplicado = false;

  // Estado de geolocalizacion automatica en tiempo real y recorte progresivo de ruta
  final GeolocationServiceUaa _geolocationService = GeolocationServiceUaa();
  StreamSubscription<LecturaGpsUsuario>? _gpsSubscription;
  Timer? _timerSimulacionCaminata;
  EstadoUbicacionMapaUaa _estadoUbicacion =
      EstadoUbicacionMapaUaa.buscandoPermiso;
  String _mensajeEstadoUbicacion =
      'Detectando tu ubicacion actual automaticamente...';
  double _distanciaFueraCampusMetros = 0.0;
  double _progresoRecorridoUsuario = 0.0;
  PuntoMapaUaa? _posicionUsuarioEnVivo;
  bool _ocultarBannerUbicacion = false;
  bool _modoMoverGpsConClic = false;
  LecturaGpsUsuario? _ultimaLecturaGps;
  DateTime? _tiempoUltimaLecturaGps;

  // Memoria de la ruta y de la capa base para evitar recalculos y repintados costosos
  RutaPeatonalUaa? _rutaCache;
  String _claveRutaCache = '';
  ui.Picture? _pictureBase;
  String _clavePictureBase = '';

  final List<String> _historialRecientesIds = <String>[
    'CEN-B-202',
    'CEN-B-65',
    'CEN-B-1-A',
    'CEN-B-38',
    'CEN-B-43',
  ];

  Size _tamanoVisor = Size.zero;
  double _ultimoOffsetX = 0.0;
  double _ultimoOffsetY = 0.0;
  double _ultimoImgW = 1.0;
  double _ultimoImgH = 1.0;

  final TransformationController _zoomController = TransformationController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _chipsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _idCampusMapa = widget.initialCampusId;
    _inicializarRutaPorDefecto(_idCampusMapa);
    _iniciarDeteccionUbicacionAutomatica();
  }

  @override
  void dispose() {
    _timerSimulacionCaminata?.cancel();
    _gpsSubscription?.cancel();
    _geolocationService.detenerSeguimiento();
    _pictureBase?.dispose();
    _zoomController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _chipsScrollController.dispose();
    super.dispose();
  }

  // Inicia automaticamente la escucha de GPS en tiempo real y maneja los 3 escenarios (Dentro, Fuera o Manual)
  void _iniciarDeteccionUbicacionAutomatica() {
    _timerSimulacionCaminata?.cancel();
    _gpsSubscription?.cancel();
    _ultimaLecturaGps = null;
    _tiempoUltimaLecturaGps = null;

    setState(() {
      _estadoUbicacion = EstadoUbicacionMapaUaa.buscandoPermiso;
      _mensajeEstadoUbicacion =
          'Detectando tu ubicacion actual en tiempo real...';
      _ocultarBannerUbicacion = false;
    });

    final Stream<LecturaGpsUsuario> stream = _geolocationService
        .iniciarSeguimientoTiempoReal(
          onError: (bool permisoDenegado, String mensaje) {
            if (!mounted) {
              return;
            }
            setState(() {
              _estadoUbicacion = EstadoUbicacionMapaUaa.permisoDenegadoManual;
              _mensajeEstadoUbicacion = 'Modo manual activo: selecciona tu punto de partida y edificio de destino.';
              _progresoRecorridoUsuario = 0.0;
              _posicionUsuarioEnVivo = null;
            });
          },
        );

    _gpsSubscription = stream.listen(
      (LecturaGpsUsuario lectura) {
        if (!mounted) {
          return;
        }
        _procesarLecturaGpsEnTiempoReal(lectura);
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _estadoUbicacion = EstadoUbicacionMapaUaa.permisoDenegadoManual;
          _mensajeEstadoUbicacion =
              'GPS no disponible. Usa el modo manual para trazar tu ruta.';
          _progresoRecorridoUsuario = 0.0;
          _posicionUsuarioEnVivo = null;
        });
      },
    );
  }

  // Procesa cada coordenada GPS recibida del dispositivo: detecta si esta dentro o fuera de la UAA y recorta el camino
  void _procesarLecturaGpsEnTiempoReal(LecturaGpsUsuario lectura) {
    if (_estadoUbicacion == EstadoUbicacionMapaUaa.simulacionEnVivo) {
      return;
    }

    final DateTime ahora = DateTime.now();
    final LecturaGpsUsuario? anterior = _ultimaLecturaGps;
    final DateTime? tiempoAnterior = _tiempoUltimaLecturaGps;
    if (anterior != null && tiempoAnterior != null) {
      final double metros =
          GeolocationServiceUaa.calcularDistanciaHaversineMetros(
            anterior.latitud,
            anterior.longitud,
            lectura.latitud,
            lectura.longitud,
          );
      final int milisegundos = ahora.difference(tiempoAnterior).inMilliseconds;
      if (metros < 5.0 && milisegundos < 3000) {
        return;
      }
    }
    _ultimaLecturaGps = lectura;
    _tiempoUltimaLecturaGps = ahora;

    final ProyeccionUbicacionUaa proyeccion =
        GeolocationServiceUaa.proyectarGpsAlMapa(
          latitud: lectura.latitud,
          longitud: lectura.longitud,
          idCampusActivo: _idCampusMapa,
        );

    if (!proyeccion.estaDentroDelCampus) {
      // El usuario esta fuera del mapa de la UAA: sugiere siempre primero el Acceso Principal (Av. Universidad)
      final List<EntradaSugeridaUaa> entradas =
          GeolocationServiceUaa.obtenerEntradasPorCampus(_idCampusMapa);
      final bool yaTieneEntradaOficial = entradas.any(
        (EntradaSugeridaUaa e) => e.idNodoEdificio == _idNodoOrigen,
      );
      final String idEntradaSugerida = yaTieneEntradaOficial
          ? _idNodoOrigen
          : entradas.first.idNodoEdificio;

      setState(() {
        _estadoUbicacion = EstadoUbicacionMapaUaa.fueraDelCampus;
        _distanciaFueraCampusMetros = proyeccion.distanciaAlCampusMetros;
        _idNodoOrigen = idEntradaSugerida;
        _progresoRecorridoUsuario = 0.0;
        _posicionUsuarioEnVivo = null;
        final String kmTexto = (_distanciaFueraCampusMetros / 1000.0)
            .clamp(0.1, 999.0)
            .toStringAsFixed(1);
        _mensajeEstadoUbicacion =
            'Ubicacion fuera de la UAA ($kmTexto km) • Entrada sugerida (Principal primero):';
      });
      return;
    }

    // El usuario esta dentro del campus UAA: actualiza su posicion en vivo y recorta la linea del camino recorrido
    final RutaPeatonalUaa rutaActual = _obtenerRutaActiva();

    final _ResultadoProyeccionPolilinea proyRuta = _proyectarPuntoSobreRuta(
      ruta: rutaActual,
      userX: proyeccion.posX,
      userY: proyeccion.posY,
    );

    // Si el usuario se alejo de la ruta trazada (ej. en area verde o calle aledana), recalcula desde el punto optimo de su sector
    if (proyRuta.distanciaNormalizada > 0.035) {
      final String nuevoOrigenId = _seleccionarOrigenParaCoordenadaEnMapa(
        proyeccion.posX,
        proyeccion.posY,
      );
      setState(() {
        _estadoUbicacion = EstadoUbicacionMapaUaa.dentroDelCampus;
        _idNodoOrigen = nuevoOrigenId;
        _posicionUsuarioEnVivo = PuntoMapaUaa(proyeccion.posX, proyeccion.posY);
        _progresoRecorridoUsuario = 0.0;
        _mensajeEstadoUbicacion = 'Ubicacion GPS en tiempo real dentro de la UAA • El camino se va recortando conforme avanzas.';
      });
      return;
    }

    setState(() {
      _estadoUbicacion = EstadoUbicacionMapaUaa.dentroDelCampus;
      _posicionUsuarioEnVivo = PuntoMapaUaa(proyeccion.posX, proyeccion.posY);
      _progresoRecorridoUsuario = proyRuta.progreso.clamp(0.0, 1.0);
      _mensajeEstadoUbicacion = 'Ubicacion GPS en tiempo real dentro de la UAA • El camino se va recortando conforme avanzas.';
    });
  }

  // Determina si una coordenada (nx, ny) cae en las calles exteriores que rodean la UAA
  bool _esCalleExteriorAlrededorDeUaa(double nx, double ny, int idCampus) {
    if (idCampus == 2) {
      return ny < 0.16 || ny > 0.94 || nx < 0.05 || nx > 0.93;
    }
    // Borde sur (Av. Universidad)
    if (ny > 0.948) {
      return true;
    }
    // Borde poniente inclinado (Calle Guadalupe Gonzalez)
    final double limitePonienteX = 0.075 + (0.95 - ny) * 0.34;
    if (nx < limitePonienteX) {
      return true;
    }
    // Borde norte / Rio San Pedro y oriente exterior
    if (ny < 0.095 || nx > 0.975) {
      return true;
    }
    if (nx > 0.52 && ny < 0.11 + (nx - 0.52) * 0.42) {
      return true;
    }
    return false;
  }

  // Identifica en cual de los 3 sectores fisicos de Campus Central (divididos por avenidas) se ubica un punto
  int _obtenerSectorFisicoCentral(double nx, double ny) {
    // Sector 3: Zona Norte (Unidad Deportiva, 300s y 400s al norte de Guadalupe Gonzalez)
    if (ny < 0.448 && nx < 0.87) {
      return 3;
    }
    // Sector 2: Zona Oriente (Edificios 101-130 al oriente de Av. Aguascalientes Norte)
    final double ejeAvenidaX = 0.775 + (0.70 - ny).clamp(-0.25, 0.30) * 0.18;
    if (nx > ejeAvenidaX + 0.028) {
      return 2;
    }
    // Franja vial de Av. Aguascalientes Norte o Av. Guadalupe Gonzalez Norte
    if ((nx >= ejeAvenidaX - 0.018 && nx <= ejeAvenidaX + 0.028) ||
        (ny >= 0.442 && ny <= 0.478 && nx < 0.78)) {
      return 0;
    }
    // Sector 1: Campus Central Principal
    return 1;
  }

  // Selecciona el nodo de origen optimo para cualquier coordenada (calles exteriores, avenidas o areas verdes)
  String _seleccionarOrigenParaCoordenadaEnMapa(double nx, double ny) {
    final List<EdificioMapaUaa> edificios = widget.repository
        .obtenerEdificiosMapa(idCampus: _idCampusMapa);

    // 1. Si esta en las calles de alrededor de la UAA, ingresa siempre por la Entrada Oficial de la UAA mas cercana
    if (_esCalleExteriorAlrededorDeUaa(nx, ny, _idCampusMapa)) {
      final List<EntradaSugeridaUaa> entradas =
          GeolocationServiceUaa.obtenerEntradasPorCampus(_idCampusMapa);
      EntradaSugeridaUaa mejorEntrada = entradas.first;
      double minD = double.infinity;
      for (final EntradaSugeridaUaa e in entradas) {
        final double d = math.sqrt(
          math.pow(e.posX - nx, 2) + math.pow(e.posY - ny, 2),
        );
        if (d < minD) {
          minD = d;
          mejorEntrada = e;
        }
      }
      return mejorEntrada.idNodoEdificio;
    }

    if (_idCampusMapa == 1) {
      final int sectorUsuario = _obtenerSectorFisicoCentral(nx, ny);
      // 2. Si esta sobre la avenida divisoria, conecta al tunel subterraneo o acceso mas cercano
      if (sectorUsuario == 0) {
        if (ny < 0.52) {
          return (nx < 0.54) ? 'CEN-B-208' : 'CEN-B-ACCESO_DEPORTIVA';
        }
        return (nx < 0.815) ? 'CEN-B-22' : 'CEN-B-110';
      }

      // 3. Si esta en un area verde o pasillo interior, busca el edificio mas cercano dentro de su mismo sector fisico
      EdificioMapaUaa? mejorEdif;
      double mejorDistancia = double.infinity;
      for (final EdificioMapaUaa e in edificios) {
        final int sectorEdif = _obtenerSectorFisicoCentral(e.posX, e.posY);
        if (sectorEdif != sectorUsuario && sectorEdif != 0) {
          continue;
        }
        final double distAlUsuario = math.sqrt(
          math.pow(e.posX - nx, 2) + math.pow(e.posY - ny, 2),
        );
        if (distAlUsuario < 0.14 && distAlUsuario < mejorDistancia) {
          mejorDistancia = distAlUsuario;
          mejorEdif = e;
        }
      }
      if (mejorEdif != null) {
        return mejorEdif.idNodo;
      }
    }

    EdificioMapaUaa? masCercano;
    double minD = double.infinity;
    for (final EdificioMapaUaa e in edificios) {
      final double d = math.sqrt(
        math.pow(e.posX - nx, 2) + math.pow(e.posY - ny, 2),
      );
      if (d < minD) {
        minD = d;
        masCercano = e;
      }
    }
    return masCercano?.idNodo ?? _idNodoOrigen;
  }

  // Permite probar el GPS en tiempo real haciendo clic en cualquier pasillo, area verde o calle exterior de la UAA
  void _moverGpsSimuladoACoordenadaLocal(Offset localPosition) {
    if (_ultimoImgW <= 0 || _ultimoImgH <= 0) {
      return;
    }
    final double nx = ((localPosition.dx - _ultimoOffsetX) / _ultimoImgW).clamp(
      0.02,
      0.98,
    );
    final double ny = ((localPosition.dy - _ultimoOffsetY) / _ultimoImgH).clamp(
      0.02,
      0.98,
    );

    _timerSimulacionCaminata?.cancel();

    final bool enCalleExterior = _esCalleExteriorAlrededorDeUaa(
      nx,
      ny,
      _idCampusMapa,
    );

    final RutaPeatonalUaa rutaActual = _obtenerRutaActiva();

    final _ResultadoProyeccionPolilinea proy = _proyectarPuntoSobreRuta(
      ruta: rutaActual,
      userX: nx,
      userY: ny,
    );

    // Si hizo clic en una calle exterior, area verde o punto alejado del trazo actual, reencamina desde esa posicion
    if (enCalleExterior || proy.distanciaNormalizada > 0.032) {
      final String nuevoOrigenId = _seleccionarOrigenParaCoordenadaEnMapa(
        nx,
        ny,
      );
      setState(() {
        _estadoUbicacion = EstadoUbicacionMapaUaa.dentroDelCampus;
        _idNodoOrigen = nuevoOrigenId;
        _posicionUsuarioEnVivo = PuntoMapaUaa(nx, ny);
        _progresoRecorridoUsuario = 0.0;
        _mensajeEstadoUbicacion = enCalleExterior
            ? 'Ubicacion en calle exterior de la UAA • Trazando ruta desde tu posicion hacia el acceso mas cercano.'
            : 'Ubicacion en campus / area verde • Trazando camino continuo desde tu posicion hasta el destino.';
      });
      return;
    }

    setState(() {
      _estadoUbicacion = EstadoUbicacionMapaUaa.dentroDelCampus;
      _posicionUsuarioEnVivo = proy.puntoProyectado;
      _progresoRecorridoUsuario = proy.progreso.clamp(0.0, 1.0);
      _mensajeEstadoUbicacion =
          'Avance GPS en ruta (${(_progresoRecorridoUsuario * 100).round()}% recorrido) • Haz clic mas adelante sobre la linea azul para avanzar.';
    });
  }

  // Proyecta la posicion en vivo del usuario sobre los segmentos del camino para recortar el tramo ya recorrido
  _ResultadoProyeccionPolilinea _proyectarPuntoSobreRuta({
    required RutaPeatonalUaa ruta,
    required double userX,
    required double userY,
  }) {
    final List<NodoPasilloUaa> pts = ruta.puntosTrayecto;
    if (pts.length < 2) {
      return _ResultadoProyeccionPolilinea(
        progreso: 0.0,
        distanciaNormalizada: 0.0,
        puntoProyectado: PuntoMapaUaa(userX, userY),
      );
    }

    double longitudTotal = 0.0;
    final List<double> segLens = <double>[];
    for (int i = 0; i < pts.length - 1; i++) {
      final double dx = pts[i + 1].posX - pts[i].posX;
      final double dy = pts[i + 1].posY - pts[i].posY;
      final double l = math.sqrt(dx * dx + dy * dy);
      segLens.add(l);
      longitudTotal += l;
    }

    if (longitudTotal <= 1e-6) {
      return _ResultadoProyeccionPolilinea(
        progreso: 0.0,
        distanciaNormalizada: 0.0,
        puntoProyectado: PuntoMapaUaa(userX, userY),
      );
    }

    double mejorDist = double.infinity;
    double mejorRecorrido = 0.0;
    PuntoMapaUaa mejorPunto = PuntoMapaUaa(pts.first.posX, pts.first.posY);
    double acumulado = 0.0;

    for (int i = 0; i < pts.length - 1; i++) {
      final double ax = pts[i].posX;
      final double ay = pts[i].posY;
      final double bx = pts[i + 1].posX;
      final double by = pts[i + 1].posY;
      final double abx = bx - ax;
      final double aby = by - ay;
      final double len2 = abx * abx + aby * aby;

      double t = 0.0;
      if (len2 > 1e-9) {
        t = (((userX - ax) * abx) + ((userY - ay) * aby)) / len2;
        t = t.clamp(0.0, 1.0);
      }

      final double qx = ax + t * abx;
      final double qy = ay + t * aby;
      final double dist = math.sqrt(
        math.pow(userX - qx, 2) + math.pow(userY - qy, 2),
      );

      if (dist < mejorDist) {
        mejorDist = dist;
        mejorRecorrido = acumulado + t * segLens[i];
        mejorPunto = PuntoMapaUaa(qx, qy);
      }
      acumulado += segLens[i];
    }

    return _ResultadoProyeccionPolilinea(
      progreso: (mejorRecorrido / longitudTotal).clamp(0.0, 1.0),
      distanciaNormalizada: mejorDist,
      puntoProyectado: mejorPunto,
    );
  }

  // Permite demostrar en vivo como el camino se va borrando/recortando conforme avanza la ubicacion del usuario
  void _alternarSimulacionAvanceEnVivo(RutaPeatonalUaa rutaActiva) {
    if (_timerSimulacionCaminata != null &&
        _timerSimulacionCaminata!.isActive) {
      _timerSimulacionCaminata?.cancel();
      setState(() {
        _progresoRecorridoUsuario = 0.0;
        _posicionUsuarioEnVivo = null;
        _estadoUbicacion = EstadoUbicacionMapaUaa.fueraDelCampus;
      });
      return;
    }

    _enfocarRutaEnCamara(rutaActiva);
    setState(() {
      _estadoUbicacion = EstadoUbicacionMapaUaa.simulacionEnVivo;
      _progresoRecorridoUsuario = 0.02;
      _posicionUsuarioEnVivo = _interpolarPuntoEnRuta(rutaActiva, 0.02);
      _mensajeEstadoUbicacion = 'Avance GPS en tiempo real activo • Observa como el camino se va recortando conforme avanzas.';
    });

    _timerSimulacionCaminata = Timer.periodic(const Duration(milliseconds: 250), (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final RutaPeatonalUaa rutaActual = _obtenerRutaActiva();
      final double siguiente = _progresoRecorridoUsuario + 0.03;
      if (siguiente >= 1.0) {
        timer.cancel();
        setState(() {
          _progresoRecorridoUsuario = 1.0;
          _posicionUsuarioEnVivo = PuntoMapaUaa(
            rutaActual.destino.posX,
            rutaActual.destino.posY,
          );
          _mensajeEstadoUbicacion =
              'Has llegado a tu destino: ${rutaActual.destino.codigo} (${rutaActual.destino.nombre}).';
        });
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (!mounted) {
            return;
          }
          setState(() {
            _progresoRecorridoUsuario = 0.0;
            _posicionUsuarioEnVivo = null;
          });
        });
      } else {
        setState(() {
          _progresoRecorridoUsuario = siguiente;
          _posicionUsuarioEnVivo = _interpolarPuntoEnRuta(
            rutaActual,
            siguiente,
          );
        });
      }
    });
  }

  // Obtiene la coordenada normalizada exacta (posX, posY) para un porcentaje de avance (0.0 a 1.0) sobre la ruta
  PuntoMapaUaa _interpolarPuntoEnRuta(RutaPeatonalUaa ruta, double progreso) {
    final List<NodoPasilloUaa> pts = ruta.puntosTrayecto;
    if (pts.isEmpty) {
      return PuntoMapaUaa(ruta.origen.posX, ruta.origen.posY);
    }
    if (pts.length == 1) {
      return PuntoMapaUaa(pts.first.posX, pts.first.posY);
    }

    double total = 0.0;
    final List<double> lens = <double>[];
    for (int i = 0; i < pts.length - 1; i++) {
      final double d = math.sqrt(
        math.pow(pts[i + 1].posX - pts[i].posX, 2) +
            math.pow(pts[i + 1].posY - pts[i].posY, 2),
      );
      lens.add(d);
      total += d;
    }

    final double target = total * progreso.clamp(0.0, 1.0);
    double acum = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      if (acum + lens[i] >= target && lens[i] > 1e-9) {
        final double t = ((target - acum) / lens[i]).clamp(0.0, 1.0);
        return PuntoMapaUaa(
          pts[i].posX + (pts[i + 1].posX - pts[i].posX) * t,
          pts[i].posY + (pts[i + 1].posY - pts[i].posY) * t,
        );
      }
      acum += lens[i];
    }
    return PuntoMapaUaa(pts.last.posX, pts.last.posY);
  }

  // Configura el punto de partida (Acceso Principal) y un edificio destino inicial por campus
  void _inicializarRutaPorDefecto(int idCampus) {
    if (idCampus == 2) {
      _idNodoOrigen = 'SUR-B-ACCESO_SUR';
      _idNodoDestino = 'SUR-B-7';
    } else {
      _idNodoOrigen = 'CEN-B-ACCESO_SUR';
      _idNodoDestino = 'CEN-B-202';
    }
    _idNodoHover = null;
    _categoriaFiltroActiva = '';
  }

  // Devuelve la ruta activa reutilizando el calculo previo mientras no cambien origen, destino o campus
  RutaPeatonalUaa _obtenerRutaActiva() {
    final String clave = '$_idCampusMapa|$_idNodoOrigen|$_idNodoDestino';
    final RutaPeatonalUaa? rutaGuardada = _rutaCache;
    if (rutaGuardada != null && _claveRutaCache == clave) {
      return rutaGuardada;
    }
    final RutaPeatonalUaa nuevaRuta = widget.repository.calcularRutaPeatonal(
      idCampus: _idCampusMapa,
      idNodoOrigen: _idNodoOrigen,
      idNodoDestino: _idNodoDestino,
    );
    _rutaCache = nuevaRuta;
    _claveRutaCache = clave;
    return nuevaRuta;
  }

  // Graba la capa base vectorial una sola vez por campus, tema y tamano para evitar redibujarla en cada frame
  ui.Picture _obtenerPictureBase({
    required bool isDark,
    required double offsetX,
    required double offsetY,
    required double imgW,
    required double imgH,
    required RutaPeatonalUaa rutaActiva,
    required List<EdificioMapaUaa> edificiosCampus,
  }) {
    final String clave =
        '$_idCampusMapa|$isDark|${imgW.round()}|${imgH.round()}|${offsetX.round()}|${offsetY.round()}';
    final ui.Picture? pictureGuardada = _pictureBase;
    if (pictureGuardada != null && _clavePictureBase == clave) {
      return pictureGuardada;
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final _VectorCampusOverlayPainter painter = _VectorCampusOverlayPainter(
      idCampus: _idCampusMapa,
      dibujarCapasBaseVectoriales: true,
      isDark: isDark,
      edificiosCampus: edificiosCampus,
      rutaActiva: rutaActiva,
      edificioHover: null,
      progresoAnimacion: 1.0,
      offsetX: offsetX,
      offsetY: offsetY,
      imgW: imgW,
      imgH: imgH,
    );
    painter._dibujarMapaBaseVectorial(canvas);
    final ui.Picture nuevaPicture = recorder.endRecording();
    _pictureBase = nuevaPicture;
    _clavePictureBase = clave;
    return nuevaPicture;
  }

  // Sincroniza el campus cuando cambia el perfil del usuario en el encabezado
  @override
  void didUpdateWidget(covariant InteractiveCampusMapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCampusId != widget.initialCampusId) {
      _idCampusMapa = widget.initialCampusId;
      _inicializarRutaPorDefecto(_idCampusMapa);
      _busquedaTexto = '';
      _mostrarSugerencias = false;
      _searchController.clear();
      _zoomInicialAplicado = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _aplicarEncuadreInicialConZoom();
      });
    }
  }

  // Aplica un zoom inicial cercano para que el mapa rebase la pantalla y el usuario navegue arrastrandolo
  void _aplicarEncuadreInicialConZoom() {
    if (!mounted || _tamanoVisor.width <= 0 || _tamanoVisor.height <= 0) {
      return;
    }
    final double scale = _idCampusMapa == 1 ? 2.15 : 1.78;
    final double targetX = _idCampusMapa == 1 ? 0.54 : 0.64;
    final double targetY = _idCampusMapa == 1 ? 0.70 : 0.42;

    final double centerPx = _ultimoOffsetX + targetX * _ultimoImgW;
    final double centerPy = _ultimoOffsetY + targetY * _ultimoImgH;

    final double tx = (_tamanoVisor.width / 2.0) - centerPx * scale;
    final double ty = (_tamanoVisor.height / 2.0) - centerPy * scale;

    final Matrix4 m = Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
    _zoomController.value = m;
  }

  // Alterna entre Campus Central (153 edificios) y Campus Sur (19 edificios)
  void _cambiarCampusMapa(int idCampus) {
    setState(() {
      _idCampusMapa = idCampus;
      _inicializarRutaPorDefecto(idCampus);
      _busquedaTexto = '';
      _mostrarSugerencias = false;
      _searchController.clear();
      _zoomInicialAplicado = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aplicarEncuadreInicialConZoom();
    });
  }

  // Registra un edificio en la lista de recientes y mantiene el Acceso Principal como primera entrada sugerida
  void _seleccionarEdificioDestino(
    EdificioMapaUaa edificio, {
    bool enfocarCamara = true,
  }) {
    _timerSimulacionCaminata?.cancel();
    setState(() {
      _idNodoDestino = edificio.idNodo;
      _progresoRecorridoUsuario = 0.0;
      if (_estadoUbicacion == EstadoUbicacionMapaUaa.simulacionEnVivo) {
        _estadoUbicacion = EstadoUbicacionMapaUaa.fueraDelCampus;
        _posicionUsuarioEnVivo = null;
      }
      if (_estadoUbicacion == EstadoUbicacionMapaUaa.fueraDelCampus) {
        final List<EntradaSugeridaUaa> entradas =
            GeolocationServiceUaa.obtenerEntradasPorCampus(_idCampusMapa);
        final bool tieneEntradaOficial = entradas.any(
          (EntradaSugeridaUaa e) => e.idNodoEdificio == _idNodoOrigen,
        );
        if (!tieneEntradaOficial) {
          _idNodoOrigen = entradas.first.idNodoEdificio;
        }
      }
      _busquedaTexto = '${edificio.codigo} - ${edificio.nombre}';
      _searchController.text = _busquedaTexto;
      _mostrarSugerencias = false;
      _historialRecientesIds.remove(edificio.idNodo);
      _historialRecientesIds.insert(0, edificio.idNodo);
      if (_historialRecientesIds.length > 8) {
        _historialRecientesIds.removeLast();
      }
    });
    _searchFocusNode.unfocus();
    if (enfocarCamara) {
      final RutaPeatonalUaa nuevaRuta = _obtenerRutaActiva();
      _enfocarRutaEnCamara(nuevaRuta);
    }
  }

  // Solicita o refresca la ubicacion GPS real del usuario y centra el encuadre del mapa
  void _fijarMiUbicacionActual() {
    _iniciarDeteccionUbicacionAutomatica();
    _aplicarEncuadreInicialConZoom();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Actualizando tu ubicacion GPS en tiempo real...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Intercambia el punto de partida actual con el edificio destino
  void _invertirRuta() {
    setState(() {
      final String temp = _idNodoOrigen;
      _idNodoOrigen = _idNodoDestino;
      _idNodoDestino = temp;
    });
  }

  // Acerca el zoom sobre el mapa manteniendo el centro del visor
  void _acercarZoom() {
    _aplicarFactorZoom(1.30);
  }

  // Aleja el zoom sobre el mapa respetando la escala minima
  void _alejarZoom() {
    final double currentScale = _zoomController.value.getMaxScaleOnAxis();
    if (currentScale <= 0.95) {
      _zoomController.value = Matrix4.identity();
      return;
    }
    _aplicarFactorZoom(0.77);
  }

  // Aplica un factor de escala centrado sobre el punto medio del visor actual
  void _aplicarFactorZoom(double factor) {
    final Matrix4 current = _zoomController.value.clone();
    final double currentScale = current.getMaxScaleOnAxis();
    final double nextScale = (currentScale * factor).clamp(0.85, 6.0);
    final double effectiveFactor = nextScale / currentScale;

    final double cx = _tamanoVisor.width > 0 ? _tamanoVisor.width / 2.0 : 400.0;
    final double cy = _tamanoVisor.height > 0
        ? _tamanoVisor.height / 2.0
        : 300.0;

    final Matrix4 zoomMatrix = Matrix4.identity()
      ..translateByDouble(cx, cy, 0.0, 1.0)
      ..scaleByDouble(effectiveFactor, effectiveFactor, 1.0, 1.0)
      ..translateByDouble(-cx, -cy, 0.0, 1.0);

    _zoomController.value = zoomMatrix.multiplied(current);
  }

  // Centra y ajusta el zoom automaticamente para encuadrar la ruta activa
  void _enfocarRutaEnCamara(RutaPeatonalUaa ruta) {
    if (_tamanoVisor.width <= 0 || _tamanoVisor.height <= 0) {
      return;
    }

    double minX = math.min(ruta.origen.posX, ruta.destino.posX);
    double maxX = math.max(ruta.origen.posX, ruta.destino.posX);
    double minY = math.min(ruta.origen.posY, ruta.destino.posY);
    double maxY = math.max(ruta.origen.posY, ruta.destino.posY);

    for (final NodoPasilloUaa n in ruta.puntosTrayecto) {
      minX = math.min(minX, n.posX);
      maxX = math.max(maxX, n.posX);
      minY = math.min(minY, n.posY);
      maxY = math.max(maxY, n.posY);
    }

    final double centerPx =
        _ultimoOffsetX + ((minX + maxX) / 2.0) * _ultimoImgW;
    final double centerPy =
        _ultimoOffsetY + ((minY + maxY) / 2.0) * _ultimoImgH;

    final double spanW = math.max(0.14, (maxX - minX) + 0.14) * _ultimoImgW;
    final double spanH = math.max(0.14, (maxY - minY) + 0.16) * _ultimoImgH;

    final double scaleX = _tamanoVisor.width / spanW;
    final double scaleY = _tamanoVisor.height / spanH;
    final double targetScale = math.min(scaleX, scaleY).clamp(1.65, 3.25);

    final double tx = (_tamanoVisor.width / 2.0) - centerPx * targetScale;
    final double ty = (_tamanoVisor.height / 2.0) - centerPy * targetScale;

    final Matrix4 m = Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
    _zoomController.value = m;
  }

  // Extrae el numero puro del codigo del edificio (por ejemplo "EDIF 38" -> "38")
  String _extraerNumeroEdificio(String codigo) {
    return codigo.toUpperCase().replaceFirst('EDIF ', '').trim();
  }

  // Evalua si un edificio pertenece a una de las categorias rapidas de la barra superior
  bool _cumpleCategoriaRapida(EdificioMapaUaa e, String cat) {
    if (cat.isEmpty) {
      return true;
    }
    final String nom = e.nombre.toLowerCase();
    final String zon = e.zona.toLowerCase();
    final String cod = e.codigo.toLowerCase();

    switch (cat) {
      case 'Administrativos':
        return zon.contains('administrativo');
      case 'Bibliotecas':
        return nom.contains('biblioteca') || nom.contains('infoteca');
      case 'Cafeterias':
        return nom.contains('cafeteria') || nom.contains('comedor');
      case 'Aulas y Labs':
        return zon.contains('aulas') ||
            nom.contains('laboratorio') ||
            nom.contains('taller');
      case 'Cajas y Control':
        return nom.contains('cajas') ||
            nom.contains('control escolar') ||
            nom.contains('finanzas') ||
            nom.contains('servicios estudiantiles');
      case 'Deportes y Cultura':
        return nom.contains('alberca') ||
            nom.contains('gimnasio') ||
            nom.contains('polyforum') ||
            nom.contains('poliforum') ||
            nom.contains('deport') ||
            nom.contains('auditorio') ||
            nom.contains('artes') ||
            cod == 'pdc';
      default:
        return true;
    }
  }

  // Filtra y ordena los edificios dando prioridad absoluta a la coincidencia exacta de numero
  List<EdificioMapaUaa> _filtrarYOrdenarEdificios(
    List<EdificioMapaUaa> todos,
    String queryRaw,
  ) {
    final List<EdificioMapaUaa> base = _categoriaFiltroActiva.isEmpty
        ? todos
        : todos
              .where(
                (EdificioMapaUaa e) =>
                    _cumpleCategoriaRapida(e, _categoriaFiltroActiva),
              )
              .toList();

    final String q = queryRaw.trim().toLowerCase();
    if (q.isEmpty) {
      return base;
    }

    final String qSinPrefijo = q
        .replaceFirst('edificio ', '')
        .replaceFirst('edif. ', '')
        .replaceFirst('edif ', '')
        .trim();

    final List<MapEntry<int, EdificioMapaUaa>> coincidencias =
        <MapEntry<int, EdificioMapaUaa>>[];

    for (final EdificioMapaUaa e in base) {
      final String numPuro = _extraerNumeroEdificio(e.codigo).toLowerCase();
      final String numSinGuion = numPuro.replaceAll('-', '');
      final String qSinGuion = qSinPrefijo.replaceAll('-', '');
      final String codLower = e.codigo.toLowerCase();
      final String nomLower = e.nombre.toLowerCase();
      final String zonaLower = e.zona.toLowerCase();

      int? prioridad;
      if (numPuro == qSinPrefijo || numSinGuion == qSinGuion || codLower == q) {
        prioridad = 0;
      } else if (numPuro.startsWith(qSinPrefijo) ||
          numSinGuion.startsWith(qSinGuion)) {
        prioridad = 1;
      } else if (nomLower.contains(q) || nomLower.contains(qSinPrefijo)) {
        prioridad = 2;
      } else if (codLower.contains(qSinPrefijo) || zonaLower.contains(q)) {
        prioridad = 3;
      }

      if (prioridad != null) {
        coincidencias.add(MapEntry<int, EdificioMapaUaa>(prioridad, e));
      }
    }

    coincidencias.sort((
      MapEntry<int, EdificioMapaUaa> a,
      MapEntry<int, EdificioMapaUaa> b,
    ) {
      if (a.key != b.key) {
        return a.key.compareTo(b.key);
      }
      return a.value.codigo.length.compareTo(b.value.codigo.length);
    });

    return coincidencias
        .map((MapEntry<int, EdificioMapaUaa> item) => item.value)
        .toList();
  }

  // Verifica mediante Ray-Casting si un punto normalizado (nx, ny) cae dentro del poligono
  bool _puntoDentroDePoligono(double nx, double ny, List<PuntoMapaUaa> poly) {
    if (poly.length < 3) {
      return false;
    }
    bool dentro = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final double xi = poly[i].x;
      final double yi = poly[i].y;
      final double xj = poly[j].x;
      final double yj = poly[j].y;

      final bool intersecta =
          ((yi > ny) != (yj > ny)) &&
          (nx <
              (xj - xi) * (ny - yi) / ((yj - yi) == 0 ? 1e-9 : (yj - yi)) + xi);
      if (intersecta) {
        dentro = !dentro;
      }
    }
    return dentro;
  }

  // Detecta que edificio individual se encuentra bajo las coordenadas locales del cursor o toque
  EdificioMapaUaa? _detectarEdificioEnCoordenada(
    Offset localPos,
    List<EdificioMapaUaa> edificios,
  ) {
    if (_ultimoImgW <= 0 || _ultimoImgH <= 0) {
      return null;
    }
    final double nx = (localPos.dx - _ultimoOffsetX) / _ultimoImgW;
    final double ny = (localPos.dy - _ultimoOffsetY) / _ultimoImgH;
    if (nx < 0.0 || nx > 1.0 || ny < 0.0 || ny > 1.0) {
      return null;
    }

    for (final EdificioMapaUaa e in edificios) {
      if (_puntoDentroDePoligono(nx, ny, e.poligono)) {
        return e;
      }
    }

    EdificioMapaUaa? masCercano;
    double menorDist = 0.018;
    for (final EdificioMapaUaa e in edificios) {
      final double d = math.sqrt(
        math.pow(e.posX - nx, 2) + math.pow(e.posY - ny, 2),
      );
      if (d < menorDist) {
        menorDist = d;
        masCercano = e;
      }
    }
    return masCercano;
  }

  // Abre un modal rapido con los edificios Frecuentes o Recientes desde la barra lateral de PC
  void _abrirModalFrecuentesORecientes({
    required bool mostrarRecientes,
    required List<EdificioMapaUaa> todosEdificios,
  }) {
    final List<EdificioMapaUaa> lista = mostrarRecientes
        ? _historialRecientesIds
              .map(
                (String id) => todosEdificios
                    .where((EdificioMapaUaa e) => e.idNodo == id)
                    .firstOrNull,
              )
              .whereType<EdificioMapaUaa>()
              .toList()
        : todosEdificios
              .where((EdificioMapaUaa e) => e.esPuntoPartidaFrecuente)
              .toList();

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(
            mostrarRecientes
                ? 'Edificios Consultados Recientemente'
                : 'Edificios y Destinos Frecuentes UAA',
          ),
          content: SizedBox(
            width: 440,
            child: lista.isEmpty
                ? const Text('Aun no hay edificios en esta lista.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final EdificioMapaUaa item = lista[index];
                      return ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.codigo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          item.nombre,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          item.zona,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _seleccionarEdificioDestino(item);
                        },
                      );
                    },
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Construye la estructura responsiva identica a Google Maps para PC/Laptop, Tablet y Telefono
  @override
  Widget build(BuildContext context) {
    final List<EdificioMapaUaa> todosEdificios = widget.repository
        .obtenerEdificiosMapa(idCampus: _idCampusMapa);

    final List<EdificioMapaUaa> sugerencias = _filtrarYOrdenarEdificios(
      todosEdificios,
      _busquedaTexto,
    );

    final RutaPeatonalUaa rutaActiva = _obtenerRutaActiva();

    final EdificioMapaUaa? edificioHover = _idNodoHover == null
        ? null
        : todosEdificios
              .where((EdificioMapaUaa e) => e.idNodo == _idNodoHover)
              .firstOrNull;

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isPcOrLaptop = screenWidth >= 1024;
    final bool isMobile = screenWidth < 700;

    final String mapAsset = _idCampusMapa == 1
        ? AppConstants.mapaOficialCentralAsset
        : AppConstants.mapaOficialSurAsset;

    final double aspectRatioMapa = _idCampusMapa == 1
        ? (1692.0 / 1650.0)
        : (1810.0 / 799.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // En PC/Laptop: Barra vertical izquierda estilo Google Maps (Rutas, Guardado, Recientes, Campus)
        if (isPcOrLaptop)
          _buildGoogleMapsLeftRail(
            isDark: isDark,
            todosEdificios: todosEdificios,
          ),

        // Area central del Mapa ocupando el 100% del espacio restante
        Expanded(
          child: Container(
            color: _modoVectorialEstilizado
                ? (isDark ? const Color(0xFF131D2B) : const Color(0xFFF7F9FC))
                : Colors.white,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // 1. LIENZO DEL MAPA A PANTALLA COMPLETA CON ZOOM INICIAL CERCANO
                InteractiveViewer(
                  transformationController: _zoomController,
                  minScale: 0.85,
                  maxScale: 6.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: _buildFullscreenVectorMapCanvas(
                    mapAsset: mapAsset,
                    aspectRatioMapa: aspectRatioMapa,
                    rutaActiva: rutaActiva,
                    edificioHover: edificioHover,
                    edificiosCampus: todosEdificios,
                    isDark: isDark,
                  ),
                ),

                // 2. BARRA SUPERIOR FLOTANTE ESTILO GOOGLE MAPS (Pildora de Busqueda + Tiempo de Ruta + Chips)
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  child: _buildTopGoogleMapsFloatingHeader(
                    theme: theme,
                    isDark: isDark,
                    isMobile: isMobile,
                    todosEdificios: todosEdificios,
                    sugerencias: sugerencias,
                    rutaActiva: rutaActiva,
                  ),
                ),

                // 3. FICHA COMPACTA DE HOVER AL PASAR EL CURSOR SOBRE UN EDIFICIO
                if (edificioHover != null && !_mostrarSugerencias)
                  Positioned(
                    top: isMobile ? 114 : 68,
                    right: 14,
                    child: IgnorePointer(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '${edificioHover.codigo} • ${edificioHover.zona}',
                              style: const TextStyle(
                                color: AppColors.footerAccentBlue,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              edificioHover.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 4. BOTON CUADRADO INFERIOR IZQUIERDO DE CAMBIO DE VISTA (ORIGINAL / INTERACTIVO)
                Positioned(
                  bottom: 22,
                  left: 14,
                  child: _buildGoogleMapsCapasSquareButton(isDark),
                ),

                // 5. CONTROLES INFERIORES DERECHOS: CIRCULO MI UBICACION + PILDORA VERTICAL (+ / -)
                Positioned(
                  bottom: 22,
                  right: 14,
                  child: _buildGoogleMapsRightControls(isDark, rutaActiva),
                ),

                // 6. BARRA INFERIOR DERECHA DE DATOS DEL MAPA Y ESCALA
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      color: (isDark ? AppColors.darkSurface : Colors.white)
                          .withValues(alpha: 0.85),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Datos del plano oficial DGIU UAA 2026 • ${_idCampusMapa == 1 ? 'Campus Central (154 edificios)' : 'Campus Sur (19 edificios)'} • 50 m ',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 5,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                                right: BorderSide(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                                bottom: BorderSide(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Barra vertical izquierda exclusiva de PC/Laptop (copia fiel de la captura 1 de Google Maps)
  Widget _buildGoogleMapsLeftRail({
    required bool isDark,
    required List<EdificioMapaUaa> todosEdificios,
  }) {
    final Color railBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol = isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;
    final Color iconCol = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF3C4043);

    return Container(
      width: 68,
      decoration: BoxDecoration(
        color: railBg,
        border: Border(right: BorderSide(color: borderCol)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: <Widget>[
          if (widget.onBackToHome != null) ...<Widget>[
            IconButton(
              tooltip: 'Volver a Inicio del Portal',
              onPressed: widget.onBackToHome,
              icon: Icon(Icons.arrow_back, color: iconCol, size: 22),
            ),
            const SizedBox(height: 8),
          ],
          _buildLeftRailItem(
            icono: Icons.directions_outlined,
            etiqueta: 'Rutas',
            activo: _mostrarPanelRutas,
            isDark: isDark,
            onTap: () {
              setState(() {
                _mostrarPanelRutas = !_mostrarPanelRutas;
                _mostrarSugerencias = false;
              });
            },
          ),
          const SizedBox(height: 14),
          _buildLeftRailItem(
            icono: Icons.bookmark_border,
            etiqueta: 'Guardado',
            activo: false,
            isDark: isDark,
            onTap: () => _abrirModalFrecuentesORecientes(
              mostrarRecientes: false,
              todosEdificios: todosEdificios,
            ),
          ),
          const SizedBox(height: 14),
          _buildLeftRailItem(
            icono: Icons.history,
            etiqueta: 'Recientes',
            activo: false,
            isDark: isDark,
            onTap: () => _abrirModalFrecuentesORecientes(
              mostrarRecientes: true,
              todosEdificios: todosEdificios,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _cambiarCampusMapa(_idCampusMapa == 1 ? 2 : 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondaryBlue,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _idCampusMapa == 1 ? 'C.U.' : 'SUR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _idCampusMapa == 1 ? 'Central' : 'Sur',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: iconCol,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _buildLeftRailItem(
            icono: Icons.center_focus_strong_outlined,
            etiqueta: 'Encuadrar',
            activo: false,
            isDark: isDark,
            onTap: _aplicarEncuadreInicialConZoom,
          ),
        ],
      ),
    );
  }

  // Elemento individual con icono y etiqueta de la barra vertical izquierda de PC
  Widget _buildLeftRailItem({
    required IconData icono,
    required String etiqueta,
    required bool activo,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final Color activeCol = isDark
        ? AppColors.footerAccentBlue
        : AppColors.secondaryBlue;
    final Color normalCol = isDark
        ? AppColors.darkTextSecondary
        : const Color(0xFF444746);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 42,
              height: 32,
              decoration: BoxDecoration(
                color: activo
                    ? activeCol.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: activo
                    ? Border.all(color: activeCol, width: 1.4)
                    : null,
              ),
              child: Icon(
                icono,
                size: 20,
                color: activo ? activeCol : normalCol,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
                color: activo ? activeCol : normalCol,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Encabezado flotante superior estilo Google Maps con insignia de tiempo de recorrido arriba
  Widget _buildTopGoogleMapsFloatingHeader({
    required ThemeData theme,
    required bool isDark,
    required bool isMobile,
    required List<EdificioMapaUaa> todosEdificios,
    required List<EdificioMapaUaa> sugerencias,
    required RutaPeatonalUaa rutaActiva,
  }) {
    final Widget searchPillColumn = _buildGoogleMapsSearchPillAndDropdowns(
      theme: theme,
      isDark: isDark,
      isMobile: isMobile,
      todosEdificios: todosEdificios,
      sugerencias: sugerencias,
      rutaActiva: rutaActiva,
    );

    final Widget categoryChipsRow = _buildGoogleMapsCategoryChipsBar(
      isDark: isDark,
      todosEdificios: todosEdificios,
      rutaActiva: rutaActiva,
    );

    final Widget? locationBanner = _ocultarBannerUbicacion
        ? null
        : _buildBannerUbicacionYEntradasSugeridas(
            isDark: isDark,
            rutaActiva: rutaActiva,
          );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          searchPillColumn,
          if (!_mostrarSugerencias && !_mostrarPanelRutas) ...<Widget>[
            const SizedBox(height: 8),
            categoryChipsRow,
            if (locationBanner != null) ...<Widget>[
              const SizedBox(height: 6),
              locationBanner,
            ],
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 380, child: searchPillColumn),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: categoryChipsRow,
                  ),
                  if (locationBanner != null &&
                      !_mostrarSugerencias &&
                      !_mostrarPanelRutas) ...<Widget>[
                    const SizedBox(height: 6),
                    locationBanner,
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Barra informativa de ubicacion GPS en tiempo real, entradas sugeridas cuando esta fuera de la UAA y simulacion de avance
  Widget _buildBannerUbicacionYEntradasSugeridas({
    required bool isDark,
    required RutaPeatonalUaa rutaActiva,
  }) {
    final Color cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol = isDark
        ? AppColors.darkBorder
        : const Color(0xFFDADCE0);
    final bool simulando =
        _estadoUbicacion == EstadoUbicacionMapaUaa.simulacionEnVivo;
    final bool fueraDeUaa =
        _estadoUbicacion == EstadoUbicacionMapaUaa.fueraDelCampus;
    final List<EntradaSugeridaUaa> entradas =
        GeolocationServiceUaa.obtenerEntradasPorCampus(_idCampusMapa);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Icon(
            fueraDeUaa
                ? Icons.near_me_outlined
                : (simulando ||
                          _estadoUbicacion ==
                              EstadoUbicacionMapaUaa.dentroDelCampus
                      ? Icons.gps_fixed
                      : Icons.edit_location_alt_outlined),
            size: 15,
            color: fueraDeUaa
                ? AppColors.accentCrimson
                : AppColors.secondaryBlue,
          ),
          Text(
            _mensajeEstadoUbicacion,
            style: TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : const Color(0xFF1E293B),
            ),
          ),
          if (fueraDeUaa ||
              _estadoUbicacion ==
                  EstadoUbicacionMapaUaa.permisoDenegadoManual) ...<Widget>[
            ...entradas.map((EntradaSugeridaUaa ent) {
              final bool seleccionada = _idNodoOrigen == ent.idNodoEdificio;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _timerSimulacionCaminata?.cancel();
                  setState(() {
                    _idNodoOrigen = ent.idNodoEdificio;
                    _progresoRecorridoUsuario = 0.0;
                    _posicionUsuarioEnVivo = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: seleccionada
                        ? AppColors.primaryNavy
                        : (isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: seleccionada ? AppColors.secondaryBlue : borderCol,
                    ),
                  ),
                  child: Text(
                    ent.nombreCorto,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: seleccionada
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                ),
              );
            }),
          ],
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _alternarSimulacionAvanceEnVivo(rutaActiva),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: simulando
                    ? AppColors.accentCrimson
                    : AppColors.secondaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    simulando
                        ? Icons.stop_circle_outlined
                        : Icons.directions_run,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    simulando ? 'Detener avance' : 'Simular avance en ruta',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _timerSimulacionCaminata?.cancel();
              setState(() {
                _modoMoverGpsConClic = !_modoMoverGpsConClic;
                if (_modoMoverGpsConClic) {
                  _mensajeEstadoUbicacion = 'Modo prueba GPS activo: haz clic en cualquier punto o pasillo del mapa para colocar tu GPS ahi.';
                } else {
                  _progresoRecorridoUsuario = 0.0;
                  _posicionUsuarioEnVivo = null;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: _modoMoverGpsConClic
                    ? const Color(0xFF0F766E)
                    : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _modoMoverGpsConClic
                      ? const Color(0xFF14B8A6)
                      : borderCol,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.touch_app_outlined,
                    size: 13,
                    color: _modoMoverGpsConClic
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _modoMoverGpsConClic
                        ? 'Salir de GPS con clic'
                        : 'Probar GPS con clic',
                    style: TextStyle(
                      color: _modoMoverGpsConClic
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _ocultarBannerUbicacion = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.close,
                size: 15,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pildora de busqueda redondeada estilo Google Maps con el rombo azul de indicaciones a la derecha
  Widget _buildGoogleMapsSearchPillAndDropdowns({
    required ThemeData theme,
    required bool isDark,
    required bool isMobile,
    required List<EdificioMapaUaa> todosEdificios,
    required List<EdificioMapaUaa> sugerencias,
    required RutaPeatonalUaa rutaActiva,
  }) {
    final Color pillBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol = isDark
        ? AppColors.darkBorder
        : const Color(0xFFDADCE0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderCol, width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: <Widget>[
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: widget.onBackToHome != null
                    ? 'Volver a Inicio'
                    : 'Mostrar opciones de ruta',
                onPressed: () {
                  if (isMobile && widget.onBackToHome != null) {
                    widget.onBackToHome!();
                  } else {
                    setState(() {
                      _mostrarPanelRutas = !_mostrarPanelRutas;
                      _mostrarSugerencias = false;
                    });
                  }
                },
                icon: Icon(
                  isMobile ? Icons.arrow_back : Icons.menu,
                  size: 20,
                  color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: _idCampusMapa == 1
                        ? 'Buscar en Mapa UAA (ej. 38, 43, 202)...'
                        : 'Buscar en Campus Sur (ej. 7, 16, PDC)...',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white54 : const Color(0xFF70757A),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onTap: () {
                    setState(() {
                      _mostrarSugerencias = true;
                    });
                  },
                  onChanged: (String valor) {
                    final List<EdificioMapaUaa> ordenados =
                        _filtrarYOrdenarEdificios(todosEdificios, valor);
                    setState(() {
                      _busquedaTexto = valor;
                      _mostrarSugerencias = true;
                      if (valor.trim().isNotEmpty && ordenados.isNotEmpty) {
                        _idNodoDestino = ordenados.first.idNodo;
                      }
                    });
                  },
                  onSubmitted: (_) {
                    if (sugerencias.isNotEmpty) {
                      _seleccionarEdificioDestino(sugerencias.first);
                    }
                  },
                ),
              ),
              if (_busquedaTexto.isNotEmpty || _mostrarSugerencias)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Limpiar busqueda',
                  onPressed: () {
                    setState(() {
                      _busquedaTexto = '';
                      _categoriaFiltroActiva = '';
                      _mostrarSugerencias = false;
                      _searchController.clear();
                    });
                    _searchFocusNode.unfocus();
                  },
                  icon: Icon(
                    Icons.close,
                    size: 19,
                    color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                  ),
                )
              else
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Buscar edificio',
                  onPressed: () {
                    setState(() {
                      _mostrarSugerencias = !_mostrarSugerencias;
                    });
                  },
                  icon: Icon(
                    Icons.search,
                    size: 20,
                    color: isDark ? Colors.white70 : const Color(0xFF5F6368),
                  ),
                ),
              Container(
                width: 1,
                height: 24,
                color: borderCol,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              Tooltip(
                message: 'Como llegar / Configurar punto de partida y ruta',
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    setState(() {
                      _mostrarPanelRutas = !_mostrarPanelRutas;
                      _mostrarSugerencias = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Transform.rotate(
                          angle: -math.pi / 4,
                          child: const Icon(
                            Icons.turn_right,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        if (_mostrarSugerencias) ...<Widget>[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol, width: 1.2),
            ),
            child: sugerencias.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'No se encontraron edificios con ese numero o nombre.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: sugerencias.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final EdificioMapaUaa item = sugerencias[index];
                      final bool esDestino =
                          item.idNodo == rutaActiva.destino.idNodo;
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: esDestino
                                ? AppColors.accentCrimson
                                : AppColors.primaryNavy,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.codigo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          item.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          item.zona,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: TextButton(
                          onPressed: () {
                            setState(() {
                              _idNodoOrigen = item.idNodo;
                              _mostrarSugerencias = false;
                            });
                            _searchFocusNode.unfocus();
                          },
                          child: const Text(
                            'Estoy aqui',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        onTap: () => _seleccionarEdificioDestino(item),
                      );
                    },
                  ),
          ),
        ],

        if (_mostrarPanelRutas && !_mostrarSugerencias) ...<Widget>[
          const SizedBox(height: 6),
          _buildCollapsibleRouteDrawerCard(
            theme: theme,
            isDark: isDark,
            todosEdificios: todosEdificios,
            rutaActiva: rutaActiva,
          ),
        ],
      ],
    );
  }

  // Barra horizontal superior: primero muestra la insignia de Tiempo Estimado (actualizada con el avance) y luego los chips
  Widget _buildGoogleMapsCategoryChipsBar({
    required bool isDark,
    required List<EdificioMapaUaa> todosEdificios,
    required RutaPeatonalUaa rutaActiva,
  }) {
    final double factorRestante = (1.0 - _progresoRecorridoUsuario).clamp(
      0.0,
      1.0,
    );
    final int metrosRestantes = (rutaActiva.distanciaMetros * factorRestante)
        .round();
    final int minutosRestantes = metrosRestantes <= 0
        ? 0
        : math.max(1, (rutaActiva.tiempoMinutos * factorRestante).ceil());

    final List<Map<String, Object>> categorias = <Map<String, Object>>[
      <String, Object>{
        'id': 'TIME_BADGE',
        'label':
            '$minutosRestantes min a pie ($metrosRestantes m) • ${rutaActiva.destino.codigo}',
        'icon': Icons.directions_walk,
      },
      <String, Object>{
        'id': 'CAMPUS_SWITCH',
        'label': _idCampusMapa == 1 ? 'Campus Central' : 'Campus Sur',
        'icon': Icons.domain_outlined,
      },
      <String, Object>{
        'id': 'Administrativos',
        'label': 'Administrativos',
        'icon': Icons.account_balance_outlined,
      },
      <String, Object>{
        'id': 'Cajas y Control',
        'label': 'Cajas y Control Escolar',
        'icon': Icons.receipt_long_outlined,
      },
      <String, Object>{
        'id': 'Bibliotecas',
        'label': 'Bibliotecas',
        'icon': Icons.local_library_outlined,
      },
      <String, Object>{
        'id': 'Cafeterias',
        'label': 'Cafeterias y Comedor',
        'icon': Icons.restaurant_outlined,
      },
      <String, Object>{
        'id': 'Aulas y Labs',
        'label': 'Aulas y Laboratorios',
        'icon': Icons.school_outlined,
      },
      <String, Object>{
        'id': 'Deportes y Cultura',
        'label': 'Deportes y Auditorios',
        'icon': Icons.sports_basketball_outlined,
      },
    ];

    final Color chipBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol = isDark
        ? AppColors.darkBorder
        : const Color(0xFFDADCE0);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        controller: _chipsScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, Object> cat = categorias[index];
          final String id = cat['id']! as String;
          final String label = cat['label']! as String;
          final IconData icon = cat['icon']! as IconData;
          final bool esTimeBadge = id == 'TIME_BADGE';
          final bool esSwitchCampus = id == 'CAMPUS_SWITCH';
          final bool activo =
              esTimeBadge || esSwitchCampus || (_categoriaFiltroActiva == id);

          final Color bgColor = esTimeBadge
              ? AppColors.accentCrimson
              : (activo
                    ? (esSwitchCampus
                          ? AppColors.primaryNavy
                          : AppColors.secondaryBlue)
                    : chipBg);

          return Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                if (esTimeBadge) {
                  _enfocarRutaEnCamara(rutaActiva);
                  return;
                }
                if (esSwitchCampus) {
                  _cambiarCampusMapa(_idCampusMapa == 1 ? 2 : 1);
                  return;
                }
                setState(() {
                  if (_categoriaFiltroActiva == id) {
                    _categoriaFiltroActiva = '';
                    _mostrarSugerencias = false;
                  } else {
                    _categoriaFiltroActiva = id;
                    _mostrarSugerencias = true;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: activo ? Colors.transparent : borderCol,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      icon,
                      size: 15,
                      color: activo
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF3C4043)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      esSwitchCampus ? '$label (Cambiar)' : label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: activo
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF3C4043)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Panel desplegable de configuracion de punto de partida y destino (cerrable con X)
  Widget _buildCollapsibleRouteDrawerCard({
    required ThemeData theme,
    required bool isDark,
    required List<EdificioMapaUaa> todosEdificios,
    required RutaPeatonalUaa rutaActiva,
  }) {
    final Color cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol = isDark
        ? AppColors.darkBorder
        : const Color(0xFFDADCE0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.directions_walk,
                    size: 18,
                    color: AppColors.secondaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tiempo estimado: ${rutaActiva.tiempoMinutos} min (${rutaActiva.distanciaMetros} m)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Cerrar selector de ruta',
                onPressed: () {
                  setState(() {
                    _mostrarPanelRutas = false;
                  });
                },
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(
                Icons.trip_origin,
                size: 15,
                color: AppColors.secondaryBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    isDense: true,
                    value:
                        todosEdificios.any(
                          (EdificioMapaUaa e) => e.idNodo == _idNodoOrigen,
                        )
                        ? _idNodoOrigen
                        : todosEdificios.first.idNodo,
                    items: todosEdificios.map((EdificioMapaUaa e) {
                      return DropdownMenuItem<String>(
                        value: e.idNodo,
                        child: Text(
                          'Origen: ${e.codigo} - ${e.nombre}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() {
                          _idNodoOrigen = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Invertir origen y destino',
                onPressed: _invertirRuta,
                icon: const Icon(Icons.swap_vert, size: 18),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            children: <Widget>[
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.accentCrimson,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Destino: ${rutaActiva.destino.codigo} - ${rutaActiva.destino.nombre}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Boton cuadrado inferior izquierdo para alternar entre vista Interactiva (por defecto) y Mapa Original
  Widget _buildGoogleMapsCapasSquareButton(bool isDark) {
    final Color borderCol = isDark ? AppColors.darkBorder : Colors.white;
    final String etiquetaBoton = _modoVectorialEstilizado
        ? 'Original'
        : 'Interactivo';

    return Tooltip(
      message: _modoVectorialEstilizado
          ? 'Cambiar a mapa original'
          : 'Cambiar a mapa interactivo',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _modoVectorialEstilizado = !_modoVectorialEstilizado;
          });
        },
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: _modoVectorialEstilizado
                ? const Color(0xFF435426)
                : AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderCol, width: 2.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Opacity(
                opacity: 0.72,
                child: Image.asset(
                  _idCampusMapa == 1
                      ? AppConstants.mapaOficialCentralAsset
                      : AppConstants.mapaOficialSurAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  cacheWidth: 192,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  color: Colors.black.withValues(alpha: 0.72),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.layers,
                            color: Colors.white,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            etiquetaBoton,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Controles inferiores derechos identicos a Google Maps: Circulo de Mi Ubicacion arriba y Pildora (+ / -) abajo
  Widget _buildGoogleMapsRightControls(
    bool isDark,
    RutaPeatonalUaa rutaActiva,
  ) {
    final Color cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol = isDark
        ? AppColors.darkBorder
        : const Color(0xFFDADCE0);
    final Color iconCol = isDark ? Colors.white : const Color(0xFF3C4043);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: cardBg,
          shape: CircleBorder(side: BorderSide(color: borderCol)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _fijarMiUbicacionActual,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.my_location, size: 19, color: iconCol),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 38,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InkWell(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                onTap: _acercarZoom,
                child: SizedBox(
                  height: 36,
                  width: 38,
                  child: Icon(Icons.add, size: 20, color: iconCol),
                ),
              ),
              Divider(height: 1, color: borderCol),
              InkWell(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                onTap: _alejarZoom,
                child: SizedBox(
                  height: 36,
                  width: 38,
                  child: Icon(Icons.remove, size: 20, color: iconCol),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Lienzo a pantalla completa con renderizado vectorial nativo 1:1 y hit-testing poligonal directo
  Widget _buildFullscreenVectorMapCanvas({
    required String mapAsset,
    required double aspectRatioMapa,
    required RutaPeatonalUaa rutaActiva,
    required EdificioMapaUaa? edificioHover,
    required List<EdificioMapaUaa> edificiosCampus,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availW = constraints.maxWidth;
        final double availH = constraints.maxHeight;

        double imgW = availW;
        double imgH = availW / aspectRatioMapa;
        if (imgH > availH) {
          imgH = availH;
          imgW = availH * aspectRatioMapa;
        }
        final double offsetX = (availW - imgW) / 2.0;
        final double offsetY = (availH - imgH) / 2.0;

        _tamanoVisor = Size(availW, availH);
        _ultimoOffsetX = offsetX;
        _ultimoOffsetY = offsetY;
        _ultimoImgW = imgW;
        _ultimoImgH = imgH;

        if (!_zoomInicialAplicado && availW > 100 && availH > 100) {
          _zoomInicialAplicado = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _aplicarEncuadreInicialConZoom();
          });
        }

        final String routeKey =
            '${rutaActiva.origen.idNodo}->${rutaActiva.destino.idNodo}';

        final ui.Picture? pictureBase = _modoVectorialEstilizado
            ? _obtenerPictureBase(
                isDark: isDark,
                offsetX: offsetX,
                offsetY: offsetY,
                imgW: imgW,
                imgH: imgH,
                rutaActiva: rutaActiva,
                edificiosCampus: edificiosCampus,
              )
            : null;
        final int anchoCacheMapa = math.min(
          2400,
          math.max(
            512,
            (imgW * MediaQuery.devicePixelRatioOf(context)).round(),
          ),
        );

        return MouseRegion(
          cursor: _idNodoHover != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.grab,
          onHover: (PointerHoverEvent event) {
            final EdificioMapaUaa? detectado = _detectarEdificioEnCoordenada(
              event.localPosition,
              edificiosCampus,
            );
            final String? nuevoHoverId = detectado?.idNodo;
            if (nuevoHoverId != _idNodoHover) {
              setState(() {
                _idNodoHover = nuevoHoverId;
              });
            }
          },
          onExit: (_) {
            if (_idNodoHover != null) {
              setState(() {
                _idNodoHover = null;
              });
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (TapUpDetails details) {
              if (_mostrarSugerencias) {
                setState(() {
                  _mostrarSugerencias = false;
                });
                _searchFocusNode.unfocus();
              }
              if (_modoMoverGpsConClic) {
                _moverGpsSimuladoACoordenadaLocal(details.localPosition);
                return;
              }
              final EdificioMapaUaa? edificioTocado =
                  _detectarEdificioEnCoordenada(
                    details.localPosition,
                    edificiosCampus,
                  );
              if (edificioTocado != null) {
                _seleccionarEdificioDestino(
                  edificioTocado,
                  enfocarCamara: false,
                );
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (!_modoVectorialEstilizado)
                  Center(
                    child: SizedBox(
                      width: imgW,
                      height: imgH,
                      child: Image.asset(
                        mapAsset,
                        key: ValueKey<String>(mapAsset),
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                        cacheWidth: anchoCacheMapa,
                      ),
                    ),
                  ),
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>(routeKey),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 460),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double progress, _) {
                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        if (pictureBase != null)
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: _StaticMapPicturePainter(pictureBase),
                            ),
                          ),
                        CustomPaint(
                          painter: _VectorCampusOverlayPainter(
                            idCampus: _idCampusMapa,
                            dibujarCapasBaseVectoriales: false,
                            isDark: isDark,
                            edificiosCampus: edificiosCampus,
                            rutaActiva: rutaActiva,
                            edificioHover: edificioHover,
                            progresoAnimacion: progress,
                            progresoRecorridoUsuario: _progresoRecorridoUsuario,
                            posicionUsuarioEnVivo: _posicionUsuarioEnVivo,
                            offsetX: offsetX,
                            offsetY: offsetY,
                            imgW: imgW,
                            imgH: imgH,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Oculta el label flotante cuando hay ubicacion en vivo para no tapar el mapa (solo muestra el punto azul)
                if (_posicionUsuarioEnVivo == null)
                  _buildEndpointPin(
                    posX: offsetX + rutaActiva.origen.posX * imgW,
                    posY: offsetY + rutaActiva.origen.posY * imgH,
                    maxW: availW,
                    maxH: availH,
                    colorFondo: AppColors.secondaryBlue,
                    icono: Icons.my_location,
                    etiqueta: 'ORIGEN: ${rutaActiva.origen.codigo}',
                  ),
                if (rutaActiva.origen.idNodo != rutaActiva.destino.idNodo)
                  _buildEndpointPin(
                    posX: offsetX + rutaActiva.destino.posX * imgW,
                    posY: offsetY + rutaActiva.destino.posY * imgH,
                    maxW: availW,
                    maxH: availH,
                    colorFondo: AppColors.accentCrimson,
                    icono: Icons.flag,
                    etiqueta: 'DESTINO: ${rutaActiva.destino.codigo}',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Marcador flotante de Origen o Destino sobre la coordenada exacta del edificio
  Widget _buildEndpointPin({
    required double posX,
    required double posY,
    required double maxW,
    required double maxH,
    required Color colorFondo,
    required IconData icono,
    required String etiqueta,
  }) {
    final double left = (posX - 62).clamp(6.0, math.max(8.0, maxW - 148.0));
    final double top = (posY - 36).clamp(6.0, math.max(8.0, maxH - 42.0));

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icono, color: Colors.white, size: 13),
              const SizedBox(width: 4),
              Text(
                etiqueta,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Resultado auxiliar de proyectar la coordenada GPS del usuario sobre la polilinea de la ruta
class _ResultadoProyeccionPolilinea {
  final double progreso;
  final double distanciaNormalizada;
  final PuntoMapaUaa puntoProyectado;

  const _ResultadoProyeccionPolilinea({
    required this.progreso,
    required this.distanciaNormalizada,
    required this.puntoProyectado,
  });
}

// Pintor ligero que solo reproduce la capa base vectorial ya grabada
class _StaticMapPicturePainter extends CustomPainter {
  final ui.Picture picture;

  const _StaticMapPicturePainter(this.picture);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(covariant _StaticMapPicturePainter oldDelegate) {
    return oldDelegate.picture != picture;
  }
}

// Pintor vectorial 1:1 que renderiza el mapa completo con vectores, bandera de Mexico, banos, guardias, E y rutas
class _VectorCampusOverlayPainter extends CustomPainter {
  final int idCampus;
  final bool dibujarCapasBaseVectoriales;
  final bool isDark;
  final List<EdificioMapaUaa> edificiosCampus;
  final RutaPeatonalUaa rutaActiva;
  final EdificioMapaUaa? edificioHover;
  final double progresoAnimacion;
  final double progresoRecorridoUsuario;
  final PuntoMapaUaa? posicionUsuarioEnVivo;
  final double offsetX;
  final double offsetY;
  final double imgW;
  final double imgH;

  const _VectorCampusOverlayPainter({
    required this.idCampus,
    required this.dibujarCapasBaseVectoriales,
    required this.isDark,
    required this.edificiosCampus,
    required this.rutaActiva,
    required this.edificioHover,
    required this.progresoAnimacion,
    this.progresoRecorridoUsuario = 0.0,
    this.posicionUsuarioEnVivo,
    required this.offsetX,
    required this.offsetY,
    required this.imgW,
    required this.imgH,
  });

  // Construye un Path con regla Even-Odd a partir de la lista de contornos extraidos del plano oficial
  Path _construirPathEvenOdd(List<List<double>> poligonos) {
    final Path path = Path()..fillType = PathFillType.evenOdd;
    for (final List<double> poly in poligonos) {
      if (poly.length < 6) {
        continue;
      }
      path.moveTo(offsetX + poly[0] * imgW, offsetY + poly[1] * imgH);
      for (int i = 2; i < poly.length; i += 2) {
        path.lineTo(offsetX + poly[i] * imgW, offsetY + poly[i + 1] * imgH);
      }
      path.close();
    }
    return path;
  }

  // Dibuja la Bandera Monumental de Mexico (136) ondulando con bordes suaves continuos sobre su glorieta gris
  void _dibujarBanderaMonumentalMexico(Canvas canvas, double escala) {
    final double poleX = offsetX + 0.583 * imgW;
    final double fy = offsetY + 0.319 * imgH;
    final double fw = 28.5 * escala;
    final double fh = 16.8 * escala;
    final double sw = fw / 3.0;

    // 1. Glorieta circular gris completa de la bandera
    final Offset centroGlorieta = Offset(poleX, offsetY + 0.355 * imgH);
    canvas.drawCircle(
      centroGlorieta,
      14.0 * escala,
      Paint()
        ..color = isDark ? const Color(0xFF6B7485) : const Color(0xFFBCBEC4)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // 2. Asta bandera vertical desde el centro de la glorieta hasta el tope de la bandera
    canvas.drawLine(
      Offset(poleX, fy - 1.0 * escala),
      centroGlorieta,
      Paint()
        ..color = const Color(0xFF334155)
        ..strokeWidth = 2.0 * escala
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    // 3. Contorno unico continuo en curva S suave (cubicTo de extremo a extremo sin escalones)
    final double c1x = poleX + fw * 0.36;
    final double c1yTop = fy + 2.4 * escala;
    final double c2x = poleX + fw * 0.66;
    final double c2yTop = fy - 2.2 * escala;
    final double endX = poleX + fw;
    final double endYTop = fy + 0.6 * escala;

    final Path outerFlagPath = Path()
      ..moveTo(poleX, fy)
      ..cubicTo(c1x, c1yTop, c2x, c2yTop, endX, endYTop)
      ..lineTo(endX, endYTop + fh)
      ..cubicTo(c2x, c2yTop + fh, c1x, c1yTop + fh, poleX, fy + fh)
      ..close();

    // Recorta las 3 franjas dentro del contorno suave unico para evitar uniones dentadas
    canvas.save();
    canvas.clipPath(outerFlagPath);

    final double topBound = fy - 4.0 * escala;
    final double botBound = fy + fh + 4.0 * escala;

    // Franja 1: Verde Bandera Oficial (#006847)
    canvas.drawRect(
      Rect.fromLTRB(poleX - 1.0, topBound, poleX + sw + 0.5, botBound),
      Paint()
        ..color = const Color(0xFF006847)
        ..isAntiAlias = true,
    );

    // Franja 2: Blanco (#FFFFFF)
    canvas.drawRect(
      Rect.fromLTRB(poleX + sw, topBound, poleX + sw * 2.0 + 0.5, botBound),
      Paint()
        ..color = Colors.white
        ..isAntiAlias = true,
    );

    // Franja 3: Rojo Bandera Oficial (#CE1126)
    canvas.drawRect(
      Rect.fromLTRB(poleX + sw * 2.0, topBound, endX + 1.0, botBound),
      Paint()
        ..color = const Color(0xFFCE1126)
        ..isAntiAlias = true,
    );

    // Sombras suaves de pliegue para dar volumen natural al ondeo
    canvas.drawRect(
      Rect.fromLTRB(poleX + sw * 0.85, topBound, poleX + sw * 1.08, botBound),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );
    canvas.drawRect(
      Rect.fromLTRB(poleX + sw * 1.92, topBound, poleX + sw * 2.15, botBound),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    // Escudo Nacional al centro de la franja blanca (Aguila y laurel)
    final Offset eagleCenter = Offset(poleX + sw * 1.50, fy + fh * 0.49);
    canvas.drawCircle(
      eagleCenter,
      2.2 * escala,
      Paint()
        ..color = const Color(0xFF6B3E16)
        ..isAntiAlias = true,
    );
    canvas.drawArc(
      Rect.fromCircle(center: eagleCenter, radius: 3.0 * escala),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = const Color(0xFF146B3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.95 * escala
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    canvas.restore();

    // Borde perimetral suavizado con anti-aliasing y esquinas redondeadas
    canvas.drawPath(
      outerFlagPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75 * escala
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  // Dibuja la geometria exacta en dos tonos y patio blanco interior del Edificio 1 (Infoteca) como en el original
  void _dibujarDetalleEdificio1Infoteca(Canvas canvas) {
    // Ala superior derecha en amarillo suave (#FAF089)
    final Rect alaSuave = Rect.fromLTRB(
      offsetX + 0.456 * imgW,
      offsetY + 0.831 * imgH,
      offsetX + 0.487 * imgW,
      offsetY + 0.870 * imgH,
    );
    canvas.drawRect(
      alaSuave,
      Paint()
        ..color = isDark ? const Color(0xFFF6E05E) : const Color(0xFFFAF089),
    );

    // Patio interior blanco donde se ubica el numero "1"
    final Rect patioBlanco = Rect.fromLTRB(
      offsetX + 0.459 * imgW,
      offsetY + 0.848 * imgH,
      offsetX + 0.473 * imgW,
      offsetY + 0.869 * imgH,
    );
    canvas.drawRect(patioBlanco, Paint()..color = Colors.white);
  }

  // Dibuja una cancha de futbol reglamentaria con areas grandes, areas chicas, medias lunas y circulo central
  void _dibujarTrazoCanchaFutbol(
    Canvas canvas, {
    required double cxNorm,
    required double cyNorm,
    required double wNorm,
    required double hNorm,
    required double anguloGrados,
    required bool ejeHorizontal,
    required Paint paint,
  }) {
    final double cx = offsetX + cxNorm * imgW;
    final double cy = offsetY + cyNorm * imgH;
    final double w = wNorm * imgW;
    final double h = hNorm * imgH;

    canvas.save();
    canvas.translate(cx, cy);
    if (anguloGrados != 0.0) {
      canvas.rotate(anguloGrados * math.pi / 180.0);
    }

    final Rect outer = Rect.fromCenter(
      center: Offset.zero,
      width: w,
      height: h,
    );
    canvas.drawRect(outer, paint);

    if (!ejeHorizontal) {
      // Porterias arriba y abajo (cancha vertical)
      canvas.drawLine(Offset(-w * 0.5, 0), Offset(w * 0.5, 0), paint);
      canvas.drawCircle(Offset.zero, w * 0.18, paint);

      final double penW = w * 0.56;
      final double penH = h * 0.17;
      final double goalW = w * 0.28;
      final double goalH = h * 0.07;

      // Area superior e inferior
      canvas.drawRect(Rect.fromLTWH(-penW * 0.5, -h * 0.5, penW, penH), paint);
      canvas.drawRect(
        Rect.fromLTWH(-goalW * 0.5, -h * 0.5, goalW, goalH),
        paint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(0, -h * 0.5 + penH),
          width: w * 0.22,
          height: h * 0.09,
        ),
        0.0,
        math.pi,
        false,
        paint,
      );

      canvas.drawRect(
        Rect.fromLTWH(-penW * 0.5, h * 0.5 - penH, penW, penH),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(-goalW * 0.5, h * 0.5 - goalH, goalW, goalH),
        paint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(0, h * 0.5 - penH),
          width: w * 0.22,
          height: h * 0.09,
        ),
        math.pi,
        math.pi,
        false,
        paint,
      );
    } else {
      // Porterias a la izquierda y derecha (cancha inclinada junto a la bandera)
      canvas.drawLine(Offset(0, -h * 0.5), Offset(0, h * 0.5), paint);
      canvas.drawCircle(Offset.zero, h * 0.18, paint);

      final double penW = w * 0.17;
      final double penH = h * 0.56;
      final double goalW = w * 0.07;
      final double goalH = h * 0.28;

      // Area izquierda y derecha
      canvas.drawRect(Rect.fromLTWH(-w * 0.5, -penH * 0.5, penW, penH), paint);
      canvas.drawRect(
        Rect.fromLTWH(-w * 0.5, -goalH * 0.5, goalW, goalH),
        paint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(-w * 0.5 + penW, 0),
          width: w * 0.09,
          height: h * 0.22,
        ),
        -math.pi * 0.5,
        math.pi,
        false,
        paint,
      );

      canvas.drawRect(
        Rect.fromLTWH(w * 0.5 - penW, -penH * 0.5, penW, penH),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(w * 0.5 - goalW, -goalH * 0.5, goalW, goalH),
        paint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(w * 0.5 - penW, 0),
          width: w * 0.09,
          height: h * 0.22,
        ),
        math.pi * 0.5,
        math.pi,
        false,
        paint,
      );
    }

    canvas.restore();
  }

  // Dibuja una cancha multiple / tenis con lineas interiores como las ubicadas al norponiente de la bandera
  void _dibujarTrazoCanchaMultiple(
    Canvas canvas, {
    required double cxNorm,
    required double cyNorm,
    required double wNorm,
    required double hNorm,
    required double anguloGrados,
    required Paint paint,
  }) {
    final double cx = offsetX + cxNorm * imgW;
    final double cy = offsetY + cyNorm * imgH;
    final double w = wNorm * imgW;
    final double h = hNorm * imgH;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(anguloGrados * math.pi / 180.0);

    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      paint,
    );
    final double iw = w * 0.78;
    final double ih = h * 0.72;
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: iw, height: ih),
      paint,
    );
    canvas.drawLine(Offset(0, -ih * 0.5), Offset(0, ih * 0.5), paint);
    canvas.drawLine(
      Offset(-iw * 0.25, -ih * 0.5),
      Offset(-iw * 0.25, ih * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(iw * 0.25, -ih * 0.5),
      Offset(iw * 0.25, ih * 0.5),
      paint,
    );
    canvas.drawLine(Offset(-iw * 0.25, 0), Offset(iw * 0.25, 0), paint);

    canvas.restore();
  }

  // Dibuja los 2 puentes subterraneos oficiales (208 y 22) y el sendero peatonal hacia la Unidad Deportiva
  void _dibujarTunelesSubterraneosYCaminoDeportiva(
    Canvas canvas,
    double escala,
  ) {
    final Color walkwayCol = isDark
        ? const Color(0xFF6B7485)
        : const Color(0xFFBCBEC4);
    final Color portalWallCol = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E293B);
    final Color tunnelFillCol = isDark
        ? const Color(0xFF334155)
        : const Color(0xFF94A3B8);

    // 1. Sendero peatonal desde la salida norte del Tunel 208 hasta la explanada de la Unidad Deportiva
    final List<Offset> ptsSenderoDeportiva = <Offset>[
      Offset(offsetX + 0.4158 * imgW, offsetY + 0.436 * imgH),
      Offset(offsetX + 0.5580 * imgW, offsetY + 0.435 * imgH),
      Offset(offsetX + 0.5850 * imgW, offsetY + 0.424 * imgH),
      Offset(offsetX + 0.6180 * imgW, offsetY + 0.435 * imgH),
      Offset(offsetX + 0.6580 * imgW, offsetY + 0.434 * imgH),
    ];

    final Path senderoPath = Path()
      ..moveTo(ptsSenderoDeportiva.first.dx, ptsSenderoDeportiva.first.dy);
    for (int i = 1; i < ptsSenderoDeportiva.length; i++) {
      senderoPath.lineTo(ptsSenderoDeportiva[i].dx, ptsSenderoDeportiva[i].dy);
    }

    // Base gris del sendero peatonal hacia Unidad Deportiva
    canvas.drawPath(
      senderoPath,
      Paint()
        ..color = walkwayCol
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.6 * escala
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    // Rampa oriente que conecta la salida del Tunel 22 (0.858, 0.686) con el andador del Edificio 110 (0.868, 0.695)
    canvas.drawLine(
      Offset(offsetX + 0.858 * imgW, offsetY + 0.686 * imgH),
      Offset(offsetX + 0.868 * imgW, offsetY + 0.695 * imgH),
      Paint()
        ..color = walkwayCol
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.2 * escala
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    // 2. Funcion auxiliar para dibujar un Tunel Subterraneo con muros de portal, guia punteada y etiqueta
    void dibujarTunel({
      required Offset p1,
      required Offset p2,
      required String etiqueta,
      required Offset labelOffset,
    }) {
      final double dx = p2.dx - p1.dx;
      final double dy = p2.dy - p1.dy;
      final double len = math.sqrt(dx * dx + dy * dy);
      if (len <= 1e-3) {
        return;
      }
      final double ux = dx / len;
      final double uy = dy / len;
      final double nx = -uy;
      final double ny = ux;
      final double halfW = 3.2 * escala;
      final double wingLen = 2.6 * escala;

      // Relleno interior sombreado del paso subterraneo
      final Path fillTunnel = Path()
        ..moveTo(p1.dx + nx * halfW, p1.dy + ny * halfW)
        ..lineTo(p2.dx + nx * halfW, p2.dy + ny * halfW)
        ..lineTo(p2.dx - nx * halfW, p2.dy - ny * halfW)
        ..lineTo(p1.dx - nx * halfW, p1.dy - ny * halfW)
        ..close();
      canvas.drawPath(
        fillTunnel,
        Paint()
          ..color = tunnelFillCol.withValues(alpha: 0.78)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );

      // Muros laterales del tunel con aletas de boca de entrada/salida
      final Paint wallPaint = Paint()
        ..color = portalWallCol
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.45 * escala
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      for (final double side in <double>[-1.0, 1.0]) {
        final Offset w1 = Offset(
          p1.dx + nx * halfW * side,
          p1.dy + ny * halfW * side,
        );
        final Offset w2 = Offset(
          p2.dx + nx * halfW * side,
          p2.dy + ny * halfW * side,
        );
        final Offset f1 = Offset(
          w1.dx + (-ux + nx * side * 0.85) * wingLen,
          w1.dy + (-uy + ny * side * 0.85) * wingLen,
        );
        final Offset f2 = Offset(
          w2.dx + (ux + nx * side * 0.85) * wingLen,
          w2.dy + (uy + ny * side * 0.85) * wingLen,
        );
        final Path wallPath = Path()
          ..moveTo(f1.dx, f1.dy)
          ..lineTo(w1.dx, w1.dy)
          ..lineTo(w2.dx, w2.dy)
          ..lineTo(f2.dx, f2.dy);
        canvas.drawPath(wallPath, wallPaint);
      }

      // Linea punteada central blanca que simboliza paso subterraneo
      final Paint dashPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25 * escala
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      final double dashStep = 4.2 * escala;
      for (double d = 2.0 * escala; d < len - 2.0 * escala; d += dashStep) {
        final double dEnd = math.min(d + 2.1 * escala, len - 1.5 * escala);
        canvas.drawLine(
          Offset(p1.dx + ux * d, p1.dy + uy * d),
          Offset(p1.dx + ux * dEnd, p1.dy + uy * dEnd),
          dashPaint,
        );
      }

      // Etiqueta institucional compacta del Tunel Subterraneo
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: etiqueta,
          style: TextStyle(
            color: Colors.white,
            fontSize: 6.2 * escala,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final RRect badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: labelOffset,
          width: tp.width + 7.5 * escala,
          height: tp.height + 3.2 * escala,
        ),
        Radius.circular(3.0 * escala),
      );
      canvas.drawRRect(
        badgeRect,
        Paint()..color = const Color(0xFF0F2942).withValues(alpha: 0.92),
      );
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * escala,
      );
      tp.paint(
        canvas,
        Offset(
          labelOffset.dx - tp.width / 2.0,
          labelOffset.dy - tp.height / 2.0,
        ),
      );
    }

    // Tunel Subterraneo 1: Junto al Edificio 208 hacia la Unidad Deportiva
    dibujarTunel(
      p1: Offset(offsetX + 0.4158 * imgW, offsetY + 0.480 * imgH),
      p2: Offset(offsetX + 0.4158 * imgW, offsetY + 0.436 * imgH),
      etiqueta: 'TUNEL SUBTERRANEO',
      labelOffset: Offset(offsetX + 0.456 * imgW, offsetY + 0.458 * imgH),
    );

    // Tunel Subterraneo 2: Junto al Edificio 22 hacia el Edificio 110 (Av. Aguascalientes Norte)
    dibujarTunel(
      p1: Offset(offsetX + 0.775 * imgW, offsetY + 0.684 * imgH),
      p2: Offset(offsetX + 0.858 * imgW, offsetY + 0.686 * imgH),
      etiqueta: 'TUNEL SUBTERRANEO',
      labelOffset: Offset(offsetX + 0.816 * imgW, offsetY + 0.672 * imgH),
    );
  }

  // Dibuja indicadores discretos y sobrios en las entradas oficiales de la UAA sin saturar el mapa ni tapar iconos
  void _dibujarMarcadoresEntradasOficiales(
    Canvas canvas,
    bool esSur,
    double escala,
  ) {
    final List<(String, double, double, bool)> entradas = esSur
        ? const <(String, double, double, bool)>[
            ('▼ ACCESO PRINCIPAL', 0.892, 0.168, true),
          ]
        : const <(String, double, double, bool)>[
            ('▲ ACCESO PRINCIPAL', 0.435, 0.956, true),
            ('► ACCESO PONIENTE', 0.105, 0.660, false),
            ('► ACCESO NORTE', 0.298, 0.196, false),
            ('▲ ACCESO DEPORTIVA', 0.668, 0.450, false),
            ('▲ ACCESO SALUD', 0.790, 0.968, false),
            ('▲ ACCESO CCDC', 0.910, 0.976, false),
          ];

    for (final (String texto, double nx, double ny, bool esPrincipal)
        in entradas) {
      final double cx = offsetX + nx * imgW;
      final double cy = offsetY + ny * imgH;

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: texto,
          style: TextStyle(
            color: Colors.white,
            fontSize: (esPrincipal ? 6.4 : 5.8) * escala,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.25,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final RRect pill = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: tp.width + 7.2 * escala,
          height: tp.height + 3.0 * escala,
        ),
        Radius.circular(3.2 * escala),
      );

      canvas.drawRRect(
        pill,
        Paint()
          ..color =
              (esPrincipal ? const Color(0xFFB91C1C) : const Color(0xFF0F2942))
                  .withValues(alpha: 0.92),
      );
      canvas.drawRRect(
        pill,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.85 * escala,
      );
      tp.paint(canvas, Offset(cx - tp.width / 2.0, cy - tp.height / 2.0));
    }
  }

  // Dibuja los detalles arquitectonicos finos del Estadio Universitario, las 7 Canchas junto a la Bandera y Flecha de Norte
  void _dibujarDetallesEstadioYCanchas(
    Canvas canvas,
    bool esSur,
    double escala,
  ) {
    final Paint grassCourtPaint = Paint()
      ..color = isDark ? const Color(0xFF61753A) : const Color(0xFFA4B252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85 * escala
      ..isAntiAlias = true;

    if (!esSur) {
      // 1. Lineas blancas centradas exactamente dentro del rectangulo verde del Estadio Universitario (0.7172, 0.3670)
      _dibujarTrazoCanchaFutbol(
        canvas,
        cxNorm: 0.7172,
        cyNorm: 0.3670,
        wNorm: 0.083,
        hNorm: 0.052,
        anguloGrados: 26.6,
        ejeHorizontal: true,
        paint: Paint()
          ..color = Colors.white.withValues(alpha: 0.78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * escala
          ..isAntiAlias = true,
      );

      // 2. Las 7 canchas deportivas alrededor de la Bandera (136) y edificios 301-303 (identicas al mapa original)
      // Cancha 1: Futbol vertical a la derecha del edificio 301
      _dibujarTrazoCanchaFutbol(
        canvas,
        cxNorm: 0.438,
        cyNorm: 0.362,
        wNorm: 0.028,
        hNorm: 0.048,
        anguloGrados: 0.0,
        ejeHorizontal: false,
        paint: grassCourtPaint,
      );
      // Cancha 2: Futbol vertical inferior izquierda (debajo del 302)
      _dibujarTrazoCanchaFutbol(
        canvas,
        cxNorm: 0.391,
        cyNorm: 0.405,
        wNorm: 0.029,
        hNorm: 0.048,
        anguloGrados: 4.5,
        ejeHorizontal: false,
        paint: grassCourtPaint,
      );
      // Cancha 3: Futbol vertical inferior derecha (debajo del 301)
      _dibujarTrazoCanchaFutbol(
        canvas,
        cxNorm: 0.422,
        cyNorm: 0.408,
        wNorm: 0.029,
        hNorm: 0.048,
        anguloGrados: 4.5,
        ejeHorizontal: false,
        paint: grassCourtPaint,
      );
      // Canchas 4 y 5: Dos canchas multiples / tenis inclinadas al norponiente de la bandera
      _dibujarTrazoCanchaMultiple(
        canvas,
        cxNorm: 0.528,
        cyNorm: 0.300,
        wNorm: 0.028,
        hNorm: 0.015,
        anguloGrados: 24.0,
        paint: grassCourtPaint,
      );
      _dibujarTrazoCanchaMultiple(
        canvas,
        cxNorm: 0.538,
        cyNorm: 0.324,
        wNorm: 0.028,
        hNorm: 0.015,
        anguloGrados: 24.0,
        paint: grassCourtPaint,
      );
      // Canchas 6 y 7: Dos canchas de futbol inclinadas inmediatamente al poniente de la bandera
      _dibujarTrazoCanchaFutbol(
        canvas,
        cxNorm: 0.524,
        cyNorm: 0.358,
        wNorm: 0.048,
        hNorm: 0.029,
        anguloGrados: 24.0,
        ejeHorizontal: true,
        paint: grassCourtPaint,
      );
      _dibujarTrazoCanchaFutbol(
        canvas,
        cxNorm: 0.510,
        cyNorm: 0.392,
        wNorm: 0.048,
        hNorm: 0.029,
        anguloGrados: 24.0,
        ejeHorizontal: true,
        paint: grassCourtPaint,
      );

      // 3. Escultura emblema UAA en la explanada de Acceso Sur (0.402, 0.922)
      final double ux = offsetX + 0.402 * imgW;
      final double uy = offsetY + 0.922 * imgH;
      canvas.drawCircle(
        Offset(ux, uy),
        6.5 * escala,
        Paint()..color = const Color(0xFF64748B),
      );

      // 4. Los 2 Puentes Subterraneos (208 y 22) y el sendero de acceso a la Unidad Deportiva
      _dibujarTunelesSubterraneosYCaminoDeportiva(canvas, escala);
    } else {
      // Detalles especificos de Campus Sur:
      // 1. Cancha de futbol en el area verde central (entre Edificio 16/17 y Edificio 10)
      _dibujarTrazoCanchaFutbol(
        canvas,
        cxNorm: 0.556,
        cyNorm: 0.495,
        wNorm: 0.022,
        hNorm: 0.068,
        anguloGrados: 0.0,
        ejeHorizontal: false,
        paint: grassCourtPaint,
      );

      // 2. Trazos internos de la Cancha de Basquetbol de Campus Sur (0.423..0.437, 0.515..0.574)
      _dibujarTrazoCanchaFutbol(
        canvas,
        cxNorm: 0.430,
        cyNorm: 0.5445,
        wNorm: 0.0115,
        hNorm: 0.052,
        anguloGrados: 0.0,
        ejeHorizontal: false,
        paint: Paint()
          ..color = isDark ? Colors.white38 : const Color(0xFF94A3B8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * escala
          ..isAntiAlias = true,
      );
    }

    // Flecha de Norte oficial (Rosa de los vientos DGIU)
    final double nx = offsetX + (esSur ? 0.750 : 0.922) * imgW;
    final double ny = offsetY + (esSur ? 0.140 : 0.115) * imgH;
    final Path northPath = Path()
      ..moveTo(nx, ny - 26 * escala)
      ..lineTo(nx + 12 * escala, ny + 14 * escala)
      ..lineTo(nx, ny + 4 * escala)
      ..lineTo(nx - 12 * escala, ny + 14 * escala)
      ..close();
    canvas.save();
    canvas.translate(nx, ny);
    canvas.rotate((esSur ? -55.0 : 28.0) * math.pi / 180.0);
    canvas.translate(-nx, -ny);
    canvas.drawPath(
      northPath,
      Paint()
        ..color = isDark ? Colors.white38 : const Color(0xFF94A3B8)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  // Dibuja cada uno de los pictogramas oficiales del plano DGIU (Banos, Vigilancia, E, Cafeteria, Biblioteca, Auditorio)
  void _dibujarPictogramasOficiales(Canvas canvas, bool esSur, double escala) {
    final List<IconoVectorialMapa> iconos = esSur
        ? CampusVectorLayers.iconosSur
        : CampusVectorLayers.iconosCentral;

    final double boxSize = (esSur ? 14.5 : 13.0) * escala;
    final double rad = 2.6 * escala;

    for (final IconoVectorialMapa item in iconos) {
      final double cx = offsetX + item.posX * imgW;
      final double cy = offsetY + item.posY * imgH;

      if (item.tipo == TipoIconoMapaUaa.estacionamiento) {
        // Simbolo oficial (E): Circulo blanco con anillo rojo y letra E negra al centro
        final double rE = boxSize * 0.56;
        canvas.drawCircle(Offset(cx, cy), rE, Paint()..color = Colors.white);
        canvas.drawCircle(
          Offset(cx, cy),
          rE,
          Paint()
            ..color = const Color(0xFFE11D2A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 * escala,
        );
        final TextPainter tpE = TextPainter(
          text: TextSpan(
            text: 'E',
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontSize: boxSize * 0.72,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tpE.paint(canvas, Offset(cx - tpE.width / 2.0, cy - tpE.height / 2.0));
        continue;
      }

      // Recuadro blanco con borde negro redondeado identico a la simbologia DGIU
      final RRect box = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: boxSize,
          height: boxSize,
        ),
        Radius.circular(rad),
      );
      canvas.drawRRect(box, Paint()..color = Colors.white);
      canvas.drawRRect(
        box,
        Paint()
          ..color = const Color(0xFF1E293B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.15 * escala,
      );

      IconData iconData;
      switch (item.tipo) {
        case TipoIconoMapaUaa.sanitarios:
          iconData = Icons.wc;
        case TipoIconoMapaUaa.vigilancia:
          iconData = Icons.local_police;
        case TipoIconoMapaUaa.cafeteria:
          iconData = Icons.restaurant;
        case TipoIconoMapaUaa.biblioteca:
          iconData = Icons.menu_book;
        case TipoIconoMapaUaa.auditorio:
          iconData = Icons.groups;
        case TipoIconoMapaUaa.estacionamiento:
          iconData = Icons.local_parking;
      }

      final TextPainter tpIcon = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: boxSize * 0.74,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: const Color(0xFF0F172A),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tpIcon.paint(
        canvas,
        Offset(cx - tpIcon.width / 2.0, cy - tpIcon.height / 2.0),
      );
    }
  }

  // Dibuja todas las capas vectoriales 1:1 del campus (areas verdes, andadores, agua, edificios, iconos y textos)
  void _dibujarMapaBaseVectorial(Canvas canvas) {
    final bool esSur = idCampus == 2;
    final double escala = (imgW / 950.0).clamp(0.65, 1.45);

    // 1. Areas verdes oficiales del campus
    final Path verdePath = _construirPathEvenOdd(
      esSur ? CampusVectorLayers.surVerde : CampusVectorLayers.centralVerde,
    );
    canvas.drawPath(
      verdePath,
      Paint()
        ..color = isDark ? const Color(0xFF435426) : const Color(0xFF88943A)
        ..style = PaintingStyle.fill,
    );

    // 2. Red completa de andadores peatonales grises
    final Path grisPath = _construirPathEvenOdd(
      esSur ? CampusVectorLayers.surGris : CampusVectorLayers.centralGris,
    );
    canvas.drawPath(
      grisPath,
      Paint()
        ..color = isDark ? const Color(0xFF6B7485) : const Color(0xFFBCBEC4)
        ..style = PaintingStyle.fill,
    );

    // 3. Cuerpos de agua (Rio San Pedro, Alberca Universitaria 209 y Canal Central)
    if (!esSur) {
      final Path aguaPath = _construirPathEvenOdd(
        CampusVectorLayers.centralAgua,
      );
      canvas.drawPath(
        aguaPath,
        Paint()
          ..color = isDark ? const Color(0xFF3978A8) : const Color(0xFF96CEF2)
          ..style = PaintingStyle.fill,
      );
    }

    // 4. Edificios de Aulas, Laboratorios y Talleres
    final Path azulPath = _construirPathEvenOdd(
      esSur ? CampusVectorLayers.surAzul : CampusVectorLayers.centralAzul,
    );
    canvas.drawPath(
      azulPath,
      Paint()
        ..color = esSur
            ? (isDark ? const Color(0xFF2B3558) : const Color(0xFF232A48))
            : (isDark ? const Color(0xFF4B6C9E) : const Color(0xFF475C88))
        ..style = PaintingStyle.fill,
    );

    // 5. Edificios de Apoyo (en Campus Sur usan tono ambar dorado #E8A818 y las cisternas/pozos amarillo brillante #FFF000)
    final Path amarilloPath = _construirPathEvenOdd(
      esSur
          ? CampusVectorLayers.surAmarillo
          : CampusVectorLayers.centralAmarillo,
    );
    canvas.drawPath(
      amarilloPath,
      Paint()
        ..color = esSur
            ? (isDark ? const Color(0xFFD99B16) : const Color(0xFFEBA818))
            : (isDark ? const Color(0xFFE5C71E) : const Color(0xFFF6DD0E))
        ..style = PaintingStyle.fill,
    );

    if (esSur) {
      final Path infraAmarillaPath = _construirPathEvenOdd(
        CampusVectorLayers.surInfraestructuraAmarilla,
      );
      canvas.drawPath(
        infraAmarillaPath,
        Paint()
          ..color = isDark ? const Color(0xFFF6E01E) : const Color(0xFFFFF000)
          ..style = PaintingStyle.fill,
      );
    }

    // 6. Edificios Administrativos
    final Path rojoPath = _construirPathEvenOdd(
      esSur ? CampusVectorLayers.surRojo : CampusVectorLayers.centralRojo,
    );
    canvas.drawPath(
      rojoPath,
      Paint()
        ..color = isDark ? const Color(0xFFE02F3C) : const Color(0xFFE4222C)
        ..style = PaintingStyle.fill,
    );

    // 7. Detalles del Edificio 1 (Infoteca), Estadio, Canchas, Flecha Norte y Bandera Monumental Ondulando
    if (!esSur) {
      _dibujarDetalleEdificio1Infoteca(canvas);
    }
    _dibujarDetallesEstadioYCanchas(canvas, esSur, escala);
    if (!esSur) {
      _dibujarBanderaMonumentalMexico(canvas, escala);
    }
    _dibujarMarcadoresEntradasOficiales(canvas, esSur, escala);

    // 8. Todos los Pictogramas Oficiales: Banos, Guardias/Vigilancia, Estacionamientos (E), Cafeterias, Bibliotecas y Auditorios
    _dibujarPictogramasOficiales(canvas, esSur, escala);

    // 9. Rotulos oficiales de vialidades, cisterna, pozo de agua, planta tratadora, subestacion CFE, etc.
    final List<EtiquetaVectorialMapa> etiquetas = esSur
        ? CampusVectorLayers.etiquetasSur
        : CampusVectorLayers.etiquetasCentral;

    for (final EtiquetaVectorialMapa et in etiquetas) {
      final double px = offsetX + et.posX * imgW;
      final double py = offsetY + et.posY * imgH;
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: et.texto,
          style: TextStyle(
            color: et.esVialidad
                ? (isDark ? Colors.white70 : const Color(0xFF1E293B))
                : const Color(0xFF0F172A),
            fontSize: et.tamanoFuente * escala,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(px, py);
      if (et.anguloGrados != 0.0) {
        canvas.rotate(et.anguloGrados * math.pi / 180.0);
      }
      tp.paint(canvas, Offset(-tp.width / 2.0, -tp.height / 2.0));
      canvas.restore();
    }

    // 10. Numeros vectoriales nitidos sobre cada uno de los 154 / 19 edificios individuales
    final double fontEdif = (esSur ? 11.8 : 7.6) * escala;
    for (final EdificioMapaUaa edif in edificiosCampus) {
      if (edif.codigo.startsWith('ACCESO')) {
        continue;
      }
      final String numTexto = edif.codigo.replaceFirst('EDIF ', '');
      final double px = offsetX + edif.posX * imgW;
      final double py = offsetY + edif.posY * imgH;
      final bool usarTextoOscuro = esSur || edif.zona.contains('Apoyo');

      final TextPainter tpHalo = TextPainter(
        text: TextSpan(
          text: numTexto,
          style: TextStyle(
            fontSize: fontEdif,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = esSur ? 1.8 : 2.2
              ..color = usarTextoOscuro
                  ? Colors.white.withValues(alpha: esSur ? 0.65 : 1.0)
                  : const Color(0xFF0F172A),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final TextPainter tpFill = TextPainter(
        text: TextSpan(
          text: numTexto,
          style: TextStyle(
            fontSize: fontEdif,
            fontWeight: FontWeight.w900,
            color: usarTextoOscuro ? const Color(0xFF1A1D24) : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset textOffset = Offset(
        px - tpFill.width / 2.0,
        py - tpFill.height / 2.0,
      );
      tpHalo.paint(canvas, textOffset);
      tpFill.paint(canvas, textOffset);
    }
  }

  // Dibuja el poligono vectorial de un edificio (Origen, Destino o Hover) con relleno y contorno de alto contraste
  void _dibujarPoligonoEdificio(
    Canvas canvas,
    EdificioMapaUaa edificio, {
    required Color colorBorde,
    required double opacidadRelleno,
    required double grosorBorde,
  }) {
    if (edificio.poligono.length < 3) {
      return;
    }

    final Path polyPath = Path();
    for (int i = 0; i < edificio.poligono.length; i++) {
      final double px = offsetX + edificio.poligono[i].x * imgW;
      final double py = offsetY + edificio.poligono[i].y * imgH;
      if (i == 0) {
        polyPath.moveTo(px, py);
      } else {
        polyPath.lineTo(px, py);
      }
    }
    polyPath.close();

    final Paint fillPaint = Paint()
      ..color = colorBorde.withValues(alpha: opacidadRelleno)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polyPath, fillPaint);

    final Paint haloPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosorBorde + 2.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(polyPath, haloPaint);

    final Paint borderPaint = Paint()
      ..color = colorBorde
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosorBorde
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(polyPath, borderPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (dibujarCapasBaseVectoriales) {
      _dibujarMapaBaseVectorial(canvas);
    }

    if (edificioHover != null &&
        edificioHover!.idNodo != rutaActiva.origen.idNodo &&
        edificioHover!.idNodo != rutaActiva.destino.idNodo) {
      _dibujarPoligonoEdificio(
        canvas,
        edificioHover!,
        colorBorde: AppColors.primaryNavy,
        opacidadRelleno: 0.28,
        grosorBorde: 2.4,
      );
    }

    // Solo resalta el poligono del edificio de origen cuando no se esta usando el punto GPS en vivo
    if (posicionUsuarioEnVivo == null) {
      _dibujarPoligonoEdificio(
        canvas,
        rutaActiva.origen,
        colorBorde: AppColors.secondaryBlue,
        opacidadRelleno: 0.30,
        grosorBorde: 2.8,
      );
    }

    if (rutaActiva.origen.idNodo != rutaActiva.destino.idNodo) {
      _dibujarPoligonoEdificio(
        canvas,
        rutaActiva.destino,
        colorBorde: AppColors.accentCrimson,
        opacidadRelleno: 0.36,
        grosorBorde: 3.2,
      );
    }

    final List<NodoPasilloUaa> nodosRuta = rutaActiva.puntosTrayecto;
    if (nodosRuta.isEmpty) {
      return;
    }

    List<Offset> puntos = nodosRuta
        .map(
          (NodoPasilloUaa n) =>
              Offset(offsetX + n.posX * imgW, offsetY + n.posY * imgH),
        )
        .toList();

    // Si hay ubicacion en vivo (en area verde, pasillo o calle exterior), evita que la ruta entre al centro del edificio
    // de origen y salga haciendo un bucle; conecta el punto GPS en vivo directo al pasillo o acceso mas cercano.
    if (posicionUsuarioEnVivo != null &&
        progresoRecorridoUsuario <= 0.005 &&
        puntos.length >= 2 &&
        !rutaActiva.origen.codigo.startsWith('ACCESO')) {
      puntos = puntos.sublist(1);
    }

    if (puntos.length == 1) {
      final Paint haloPaint = Paint()
        ..color = AppColors.secondaryBlue.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(puntos.first, 18, haloPaint);
      return;
    }

    double longitudTotal = 0.0;
    final List<double> longitudesSegmentos = <double>[];
    for (int i = 0; i < puntos.length - 1; i++) {
      final double segLen = (puntos[i + 1] - puntos[i]).distance;
      longitudesSegmentos.add(segLen);
      longitudTotal += segLen;
    }

    final double distanciaInicioRecorte =
        longitudTotal * progresoRecorridoUsuario.clamp(0.0, 1.0);
    final double distanciaVisible =
        longitudTotal * progresoAnimacion.clamp(0.0, 1.0);

    final Path rutaPath = Path();
    bool pathIniciado = false;
    Offset puntoInicioActivo = puntos.first;
    double acumulado = 0.0;

    for (int i = 0; i < puntos.length - 1; i++) {
      final double segLen = longitudesSegmentos[i];
      final double segStart = acumulado;
      final double segEnd = acumulado + segLen;
      acumulado = segEnd;

      // Omite por completo los tramos que ya quedaron atras de la ubicacion actual del usuario (se borran como en Google Maps)
      if (segEnd <= distanciaInicioRecorte) {
        continue;
      }
      if (segStart >= distanciaVisible) {
        break;
      }

      final double localStart = math.max(
        0.0,
        distanciaInicioRecorte - segStart,
      );
      final double localEnd = math.min(segLen, distanciaVisible - segStart);
      if (localEnd <= localStart || segLen <= 1e-6) {
        continue;
      }

      final double t0 = (localStart / segLen).clamp(0.0, 1.0);
      final double t1 = (localEnd / segLen).clamp(0.0, 1.0);
      final Offset pStart = Offset.lerp(puntos[i], puntos[i + 1], t0)!;
      final Offset pEnd = Offset.lerp(puntos[i], puntos[i + 1], t1)!;

      if (!pathIniciado) {
        rutaPath.moveTo(pStart.dx, pStart.dy);
        puntoInicioActivo = pStart;
        pathIniciado = true;
      }
      rutaPath.lineTo(pEnd.dx, pEnd.dy);
    }

    if (pathIniciado) {
      final Paint bordeBlancoPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(rutaPath, bordeBlancoPaint);

      final Paint lineaRutaPaint = Paint()
        ..color = AppColors.secondaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(rutaPath, lineaRutaPaint);
    }

    final Paint puntoBlancoPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint puntoPasilloPaint = Paint()
      ..color = AppColors.primaryNavy
      ..style = PaintingStyle.fill;

    // Solo dibuja los nodos intermedios que aun estan por delante del usuario
    double distNodo = 0.0;
    for (int i = 1; i < puntos.length - 1; i++) {
      distNodo += longitudesSegmentos[i - 1];
      if (distNodo > distanciaInicioRecorte + 2.0) {
        canvas.drawCircle(puntos[i], 3.8, puntoBlancoPaint);
        canvas.drawCircle(puntos[i], 2.3, puntoPasilloPaint);
      }
    }

    // Punto de ubicacion actual del usuario (estilo Google Maps con halo azul cuando esta avanzando)
    final Offset posMarcadorUsuario = posicionUsuarioEnVivo != null
        ? Offset(
            offsetX + posicionUsuarioEnVivo!.x * imgW,
            offsetY + posicionUsuarioEnVivo!.y * imgH,
          )
        : puntoInicioActivo;

    // Si el usuario esta en un area verde, explanada o calle exterior alejada del pasillo inicial,
    // traza el camino conector desde su punto azul hasta el inicio del pasillo para que nunca quede sin rastro.
    if (posicionUsuarioEnVivo != null &&
        pathIniciado &&
        (posMarcadorUsuario - puntoInicioActivo).distance > 3.0) {
      final Path conectorPath = Path()
        ..moveTo(posMarcadorUsuario.dx, posMarcadorUsuario.dy)
        ..lineTo(puntoInicioActivo.dx, puntoInicioActivo.dy);

      canvas.drawPath(
        conectorPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        conectorPath,
        Paint()
          ..color = AppColors.secondaryBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.8
          ..strokeCap = StrokeCap.round,
      );

      // Puntos guia sobre el tramo de aproximacion (area verde o calle exterior hacia el acceso/pasillo)
      final double distConector =
          (puntoInicioActivo - posMarcadorUsuario).distance;
      final int pasos = (distConector / 16.0).floor();
      for (int s = 1; s <= pasos; s++) {
        final double t = s / (pasos + 1);
        final Offset pt = Offset.lerp(
          posMarcadorUsuario,
          puntoInicioActivo,
          t,
        )!;
        canvas.drawCircle(pt, 3.4, puntoBlancoPaint);
        canvas.drawCircle(pt, 2.0, puntoPasilloPaint);
      }
    }

    if (posicionUsuarioEnVivo != null || progresoRecorridoUsuario > 0.0) {
      canvas.drawCircle(
        posMarcadorUsuario,
        14.5,
        Paint()..color = const Color(0xFF1A73E8).withValues(alpha: 0.22),
      );
      canvas.drawCircle(posMarcadorUsuario, 8.2, puntoBlancoPaint);
      canvas.drawCircle(
        posMarcadorUsuario,
        5.8,
        Paint()..color = const Color(0xFF1A73E8),
      );
    } else {
      canvas.drawCircle(puntos.first, 7.5, puntoBlancoPaint);
      canvas.drawCircle(
        puntos.first,
        5.2,
        Paint()..color = AppColors.secondaryBlue,
      );
    }

    canvas.drawCircle(puntos.last, 8.0, puntoBlancoPaint);
    canvas.drawCircle(
      puntos.last,
      5.6,
      Paint()..color = AppColors.accentCrimson,
    );
  }

  @override
  bool shouldRepaint(covariant _VectorCampusOverlayPainter oldDelegate) {
    return oldDelegate.progresoAnimacion != progresoAnimacion ||
        oldDelegate.progresoRecorridoUsuario != progresoRecorridoUsuario ||
        oldDelegate.posicionUsuarioEnVivo?.x != posicionUsuarioEnVivo?.x ||
        oldDelegate.posicionUsuarioEnVivo?.y != posicionUsuarioEnVivo?.y ||
        oldDelegate.dibujarCapasBaseVectoriales !=
            dibujarCapasBaseVectoriales ||
        oldDelegate.isDark != isDark ||
        oldDelegate.idCampus != idCampus ||
        oldDelegate.rutaActiva.origen.idNodo != rutaActiva.origen.idNodo ||
        oldDelegate.rutaActiva.destino.idNodo != rutaActiva.destino.idNodo ||
        oldDelegate.edificioHover != edificioHover ||
        oldDelegate.offsetX != offsetX ||
        oldDelegate.offsetY != offsetY ||
        oldDelegate.imgW != imgW ||
        oldDelegate.imgH != imgH;
  }
}
