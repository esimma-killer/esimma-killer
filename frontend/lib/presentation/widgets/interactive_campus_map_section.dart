import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/campus_vector_layers.dart';
import '../../data/repositories/portal_repository.dart';
import '../../domain/entities/portal_models.dart';

// Navegador interactivo a pantalla completa con vectorizacion 1:1 de los 172 edificios oficiales UAA
class InteractiveCampusMapSection extends StatefulWidget {
  final PortalRepository repository;
  final int initialCampusId;

  const InteractiveCampusMapSection({
    super.key,
    required this.repository,
    this.initialCampusId = 1,
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
  bool _mostrarSugerencias = false;
  bool _panelIndicacionesExpandido = true;
  bool _modoVectorialEstilizado = true;

  Size _tamanoVisor = Size.zero;
  double _ultimoOffsetX = 0.0;
  double _ultimoOffsetY = 0.0;
  double _ultimoImgW = 1.0;
  double _ultimoImgH = 1.0;

  final TransformationController _zoomController = TransformationController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _idCampusMapa = widget.initialCampusId;
    _inicializarRutaPorDefecto(_idCampusMapa);
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
      _zoomController.value = Matrix4.identity();
    }
  }

  // Alterna entre Campus Central (153 edificios) y Campus Sur (19 edificios)
  void _cambiarCampusMapa(int idCampus) {
    setState(() {
      _idCampusMapa = idCampus;
      _inicializarRutaPorDefecto(idCampus);
      _busquedaTexto = '';
      _mostrarSugerencias = false;
      _searchController.clear();
      _zoomController.value = Matrix4.identity();
    });
  }

  // Fija la ubicacion actual del usuario en el acceso principal del campus activo
  void _fijarMiUbicacionActual() {
    setState(() {
      _idNodoOrigen =
          _idCampusMapa == 1 ? 'CEN-B-ACCESO_SUR' : 'SUR-B-ACCESO_SUR';
      _zoomController.value = Matrix4.identity();
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _idCampusMapa == 1
              ? 'Ubicacion actual fijada en: Acceso Principal Av. Universidad (Campus Central).'
              : 'Ubicacion actual fijada en: Plaza de Acceso Prol. Mahatma Gandhi (Campus Sur).',
        ),
        duration: const Duration(seconds: 2),
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
    if (currentScale <= 1.05) {
      _zoomController.value = Matrix4.identity();
      return;
    }
    _aplicarFactorZoom(0.77);
  }

  // Aplica un factor de escala centrado sobre el punto medio del visor actual
  void _aplicarFactorZoom(double factor) {
    final Matrix4 current = _zoomController.value.clone();
    final double currentScale = current.getMaxScaleOnAxis();
    final double nextScale = (currentScale * factor).clamp(0.9, 5.5);
    final double effectiveFactor = nextScale / currentScale;

    final double cx = _tamanoVisor.width > 0 ? _tamanoVisor.width / 2.0 : 400.0;
    final double cy =
        _tamanoVisor.height > 0 ? _tamanoVisor.height / 2.0 : 300.0;

    final Matrix4 zoomMatrix = Matrix4.identity()
      ..translateByDouble(cx, cy, 0.0, 1.0)
      ..scaleByDouble(effectiveFactor, effectiveFactor, 1.0, 1.0)
      ..translateByDouble(-cx, -cy, 0.0, 1.0);

    _zoomController.value = zoomMatrix.multiplied(current);
  }

  // Restablece el zoom y centrado al 100%
  void _restablecerZoom() {
    _zoomController.value = Matrix4.identity();
  }

  // Centra y ajusta el zoom automaticamente para encuadrar la ruta activa o el edificio buscado
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
    final double targetScale = math.min(scaleX, scaleY).clamp(1.25, 2.85);

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

  // Filtra y ordena los edificios dando prioridad absoluta a la coincidencia exacta de numero
  List<EdificioMapaUaa> _filtrarYOrdenarEdificios(
    List<EdificioMapaUaa> todos,
    String queryRaw,
  ) {
    final String q = queryRaw.trim().toLowerCase();
    if (q.isEmpty) {
      return todos;
    }

    final String qSinPrefijo = q
        .replaceFirst('edificio ', '')
        .replaceFirst('edif. ', '')
        .replaceFirst('edif ', '')
        .trim();

    final List<MapEntry<int, EdificioMapaUaa>> coincidencias =
        <MapEntry<int, EdificioMapaUaa>>[];

    for (final EdificioMapaUaa e in todos) {
      final String numPuro = _extraerNumeroEdificio(e.codigo).toLowerCase();
      final String numSinGuion = numPuro.replaceAll('-', '');
      final String qSinGuion = qSinPrefijo.replaceAll('-', '');
      final String codLower = e.codigo.toLowerCase();
      final String nomLower = e.nombre.toLowerCase();
      final String zonaLower = e.zona.toLowerCase();

      int? prioridad;
      if (numPuro == qSinPrefijo ||
          numSinGuion == qSinGuion ||
          codLower == q) {
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

    coincidencias.sort(
      (
        MapEntry<int, EdificioMapaUaa> a,
        MapEntry<int, EdificioMapaUaa> b,
      ) {
        if (a.key != b.key) {
          return a.key.compareTo(b.key);
        }
        return a.value.codigo.length.compareTo(b.value.codigo.length);
      },
    );

    return coincidencias
        .map((MapEntry<int, EdificioMapaUaa> item) => item.value)
        .toList();
  }

  // Verifica mediante el algoritmo Ray-Casting si un punto normalizado (nx, ny) cae dentro del poligono
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

      final bool intersecta = ((yi > ny) != (yj > ny)) &&
          (nx <
              (xj - xi) * (ny - yi) / ((yj - yi) == 0 ? 1e-9 : (yj - yi)) +
                  xi);
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

  // Construye el lienzo a pantalla completa con vectorizacion 1:1 y paneles flotantes estilo Google Maps
  @override
  Widget build(BuildContext context) {
    final List<EdificioMapaUaa> todosEdificios =
        widget.repository.obtenerEdificiosMapa(idCampus: _idCampusMapa);

    final List<EdificioMapaUaa> sugerencias =
        _filtrarYOrdenarEdificios(todosEdificios, _busquedaTexto);

    final RutaPeatonalUaa rutaActiva = widget.repository.calcularRutaPeatonal(
      idCampus: _idCampusMapa,
      idNodoOrigen: _idNodoOrigen,
      idNodoDestino: _idNodoDestino,
    );

    final EdificioMapaUaa? edificioHover = _idNodoHover == null
        ? null
        : todosEdificios
            .where((EdificioMapaUaa e) => e.idNodo == _idNodoHover)
            .firstOrNull;

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 720;

    final String mapAsset = _idCampusMapa == 1
        ? AppConstants.mapaOficialCentralAsset
        : AppConstants.mapaOficialSurAsset;

    final double aspectRatioMapa =
        _idCampusMapa == 1 ? (1692.0 / 1650.0) : (1810.0 / 799.0);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _modoVectorialEstilizado
            ? (isDark ? const Color(0xFF101926) : const Color(0xFFF7F9FC))
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // CAPA 1: Mapa a pantalla completa con renderizado vectorial 1:1 y deteccion de los 172 edificios
          InteractiveViewer(
            transformationController: _zoomController,
            minScale: 0.9,
            maxScale: 5.5,
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

          // CAPA 2: Buscador Flotante Superior Izquierdo con Autocompletado Exacto por Numero o Nombre
          Positioned(
            top: 12,
            left: 12,
            right: isMobile ? 12 : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? screenWidth - 24 : 445,
              ),
              child: _buildFloatingSearchAndOriginPanel(
                theme: theme,
                isDark: isDark,
                todosEdificios: todosEdificios,
                sugerencias: sugerencias,
                rutaActiva: rutaActiva,
              ),
            ),
          ),

          // CAPA 3: Selector Flotante Superior Derecho de Campus, Modo Vectorial y Ubicacion (PC/Tablet)
          if (!isMobile)
            Positioned(
              top: 12,
              right: 14,
              child: _buildFloatingCampusAndLegendBar(isDark, rutaActiva),
            ),

          // CAPA 4: Etiqueta Flotante al pasar el cursor sobre cualquier edificio del mapa
          if (edificioHover != null)
            Positioned(
              top: isMobile ? 155 : 64,
              right: 14,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${edificioHover.codigo} • ${edificioHover.zona}',
                        style: const TextStyle(
                          color: AppColors.footerAccentBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        edificioHover.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Clic para trazar ruta peatonal hasta este edificio',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // CAPA 5: Tarjeta Flotante Inferior Izquierda con Ruta, Tiempo e Indicaciones Paso a Paso
          Positioned(
            bottom: 14,
            left: 12,
            right: isMobile ? 68 : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? screenWidth - 80 : 435,
              ),
              child: _buildFloatingRouteDirectionsCard(
                theme: theme,
                isDark: isDark,
                rutaActiva: rutaActiva,
              ),
            ),
          ),

          // CAPA 6: Controles Flotantes Inferiores Derechos de Zoom (+, -, Enfocar Ruta, 100%)
          Positioned(
            bottom: 14,
            right: 14,
            child: _buildFloatingZoomControls(isDark, rutaActiva),
          ),
        ],
      ),
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

        final String routeKey =
            '${rutaActiva.origen.idNodo}->${rutaActiva.destino.idNodo}';

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
              final EdificioMapaUaa? edificioTocado =
                  _detectarEdificioEnCoordenada(
                details.localPosition,
                edificiosCampus,
              );
              if (edificioTocado != null) {
                setState(() {
                  _idNodoDestino = edificioTocado.idNodo;
                  _busquedaTexto =
                      '${edificioTocado.codigo} - ${edificioTocado.nombre}';
                  _searchController.text = _busquedaTexto;
                });
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Si el usuario elige ver la imagen original debajo, se muestra el plano limpio DGIU
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
                      ),
                    ),
                  ),
                // Renderizador Vectorial 1:1: dibuja las capas vectoriales del campus, edificios, numeros y ruta
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>(routeKey),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 460),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double progress, _) {
                    return CustomPaint(
                      painter: _VectorCampusOverlayPainter(
                        idCampus: _idCampusMapa,
                        dibujarCapasBaseVectoriales: _modoVectorialEstilizado,
                        isDark: isDark,
                        edificiosCampus: edificiosCampus,
                        rutaActiva: rutaActiva,
                        edificioHover: edificioHover,
                        progresoAnimacion: progress,
                        offsetX: offsetX,
                        offsetY: offsetY,
                        imgW: imgW,
                        imgH: imgH,
                      ),
                    );
                  },
                ),
                // Pin Flotante de Origen (Tu Ubicacion Actual)
                _buildEndpointPin(
                  posX: offsetX + rutaActiva.origen.posX * imgW,
                  posY: offsetY + rutaActiva.origen.posY * imgH,
                  maxW: availW,
                  maxH: availH,
                  colorFondo: AppColors.secondaryBlue,
                  icono: Icons.my_location,
                  etiqueta: 'ORIGEN: ${rutaActiva.origen.codigo}',
                ),
                // Pin Flotante de Destino (Edificio exacto buscado o seleccionado)
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

  // Panel flotante superior izquierdo: Buscador con sugerencias exactas por numero o nombre de edificio
  Widget _buildFloatingSearchAndOriginPanel({
    required ThemeData theme,
    required bool isDark,
    required List<EdificioMapaUaa> todosEdificios,
    required List<EdificioMapaUaa> sugerencias,
    required RutaPeatonalUaa rutaActiva,
  }) {
    final Color cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol, width: 1.4),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: _idCampusMapa == 1
                  ? 'Buscar edificio por numero exacto o nombre (ej. 38, 43, 202, 1-A, 65, Biblioteca, Cajas)...'
                  : 'Buscar edificio en Campus Sur por numero o nombre (ej. 1 al 17, PDC, Biomedica, Biblioteca)...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _busquedaTexto.isNotEmpty || _mostrarSugerencias
                  ? IconButton(
                      tooltip: 'Limpiar busqueda',
                      onPressed: () {
                        setState(() {
                          _busquedaTexto = '';
                          _mostrarSugerencias = false;
                          _searchController.clear();
                        });
                        _searchFocusNode.unfocus();
                      },
                      icon: const Icon(Icons.close, size: 18),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurfaceMuted
                  : AppColors.lightSurfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
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
                final EdificioMapaUaa elegido = sugerencias.first;
                setState(() {
                  _idNodoDestino = elegido.idNodo;
                  _mostrarSugerencias = false;
                });
                final RutaPeatonalUaa nuevaRuta =
                    widget.repository.calcularRutaPeatonal(
                  idCampus: _idCampusMapa,
                  idNodoOrigen: _idNodoOrigen,
                  idNodoDestino: elegido.idNodo,
                );
                _enfocarRutaEnCamara(nuevaRuta);
              }
            },
          ),
          // Lista desplegable de sugerencias en tiempo real ordenada por coincidencia exacta de numero
          if (_mostrarSugerencias) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 230),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceMuted
                    : const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderCol),
              ),
              child: sugerencias.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No se encontro ningun edificio con ese numero o nombre.',
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                          onTap: () {
                            setState(() {
                              _idNodoDestino = item.idNodo;
                              _busquedaTexto =
                                  '${item.codigo} - ${item.nombre}';
                              _searchController.text = _busquedaTexto;
                              _mostrarSugerencias = false;
                            });
                            _searchFocusNode.unfocus();
                            final RutaPeatonalUaa nuevaRuta =
                                widget.repository.calcularRutaPeatonal(
                              idCampus: _idCampusMapa,
                              idNodoOrigen: _idNodoOrigen,
                              idNodoDestino: item.idNodo,
                            );
                            _enfocarRutaEnCamara(nuevaRuta);
                          },
                        );
                      },
                    ),
            ),
          ],
          const SizedBox(height: 8),
          // Selector rapido de Punto de Partida (Origen) e inversion de ruta
          Row(
            children: <Widget>[
              const Icon(
                Icons.trip_origin,
                size: 15,
                color: AppColors.secondaryBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    isDense: true,
                    value: todosEdificios.any(
                      (EdificioMapaUaa e) => e.idNodo == _idNodoOrigen,
                    )
                        ? _idNodoOrigen
                        : todosEdificios.first.idNodo,
                    items: todosEdificios.map((EdificioMapaUaa e) {
                      return DropdownMenuItem<String>(
                        value: e.idNodo,
                        child: Text(
                          'Desde: ${e.codigo} (${e.nombre})',
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
                icon: const Icon(Icons.swap_horiz, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Barra flotante superior derecha con selector de Campus, modo Vectorial/Original y Ubicacion
  Widget _buildFloatingCampusAndLegendBar(
    bool isDark,
    RutaPeatonalUaa rutaActiva,
  ) {
    final Color cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ChoiceChip(
            label: const Text('Campus Central'),
            selected: _idCampusMapa == 1,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => _cambiarCampusMapa(1),
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Campus Sur'),
            selected: _idCampusMapa == 2,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => _cambiarCampusMapa(2),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(
              _modoVectorialEstilizado ? 'Mapa Vectorial 1:1' : 'Plano Oficial',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
            selected: _modoVectorialEstilizado,
            visualDensity: VisualDensity.compact,
            onSelected: (bool value) {
              setState(() {
                _modoVectorialEstilizado = value;
              });
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            onPressed: _fijarMiUbicacionActual,
            icon: const Icon(
              Icons.my_location,
              size: 15,
              color: AppColors.secondaryBlue,
            ),
            label: const Text(
              'Mi ubicacion',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta flotante inferior izquierda con resumen de ruta e indicaciones paso a paso
  Widget _buildFloatingRouteDirectionsCard({
    required ThemeData theme,
    required bool isDark,
    required RutaPeatonalUaa rutaActiva,
  }) {
    final EdificioMapaUaa destino = rutaActiva.destino;
    final Color cardBg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.secondaryBlue,
          width: 1.6,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.directions_walk,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${rutaActiva.tiempoMinutos} min a pie (${rutaActiva.distanciaMetros} m)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentCrimson,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      destino.codigo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Acercar camara a esta ruta',
                    onPressed: () => _enfocarRutaEnCamara(rutaActiva),
                    icon: const Icon(
                      Icons.center_focus_weak,
                      size: 18,
                      color: AppColors.secondaryBlue,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: _panelIndicacionesExpandido
                        ? 'Minimizar indicaciones'
                        : 'Ver indicaciones paso a paso',
                    onPressed: () {
                      setState(() {
                        _panelIndicacionesExpandido =
                            !_panelIndicacionesExpandido;
                      });
                    },
                    icon: Icon(
                      _panelIndicacionesExpandido
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            destino.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_panelIndicacionesExpandido) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              'Categoria en plano oficial: ${destino.zona}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.footerAccentBlue
                    : AppColors.secondaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
            const Divider(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 115),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rutaActiva.indicacionesPasoAPaso.map((String paso) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.subdirectory_arrow_right,
                              size: 14,
                              color: AppColors.secondaryBlue,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              paso,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Controles flotantes inferiores derechos de Zoom (+, -, Enfocar Ruta, 100%)
  Widget _buildFloatingZoomControls(
    bool isDark,
    RutaPeatonalUaa rutaActiva,
  ) {
    final Color cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol, width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: 'Acercar mapa (+)',
            onPressed: _acercarZoom,
            icon: const Icon(Icons.add),
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Alejar mapa (-)',
            onPressed: _alejarZoom,
            icon: const Icon(Icons.remove),
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Enfocar ruta activa',
            onPressed: () => _enfocarRutaEnCamara(rutaActiva),
            icon: const Icon(
              Icons.route_outlined,
              size: 20,
              color: AppColors.secondaryBlue,
            ),
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Restablecer vista 100%',
            onPressed: _restablecerZoom,
            icon: const Icon(Icons.center_focus_strong, size: 20),
          ),
        ],
      ),
    );
  }
}

// Pintor vectorial 1:1 que renderiza el mapa completo con vectores, numeros de edificio y rutas
class _VectorCampusOverlayPainter extends CustomPainter {
  final int idCampus;
  final bool dibujarCapasBaseVectoriales;
  final bool isDark;
  final List<EdificioMapaUaa> edificiosCampus;
  final RutaPeatonalUaa rutaActiva;
  final EdificioMapaUaa? edificioHover;
  final double progresoAnimacion;
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

  // Dibuja todas las capas vectoriales 1:1 del campus (areas verdes, andadores, agua, edificios y textos)
  void _dibujarMapaBaseVectorial(Canvas canvas) {
    final bool esSur = idCampus == 2;

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
      final Path aguaPath =
          _construirPathEvenOdd(CampusVectorLayers.centralAgua);
      canvas.drawPath(
        aguaPath,
        Paint()
          ..color = isDark ? const Color(0xFF3978A8) : const Color(0xFF96CEF2)
          ..style = PaintingStyle.fill,
      );
    }

    // 4. Edificios de Aulas, Laboratorios y Talleres (Azul pizarra institucional)
    final Path azulPath = _construirPathEvenOdd(
      esSur ? CampusVectorLayers.surAzul : CampusVectorLayers.centralAzul,
    );
    canvas.drawPath(
      azulPath,
      Paint()
        ..color = isDark ? const Color(0xFF4B6C9E) : const Color(0xFF475C88)
        ..style = PaintingStyle.fill,
    );

    // 5. Edificios de Apoyo (Amarillo oficial del plano DGIU)
    final Path amarilloPath = _construirPathEvenOdd(
      esSur
          ? CampusVectorLayers.surAmarillo
          : CampusVectorLayers.centralAmarillo,
    );
    canvas.drawPath(
      amarilloPath,
      Paint()
        ..color = isDark ? const Color(0xFFE5C71E) : const Color(0xFFF6DD0E)
        ..style = PaintingStyle.fill,
    );

    // 6. Edificios Administrativos (Rojo oficial del plano DGIU)
    final Path rojoPath = _construirPathEvenOdd(
      esSur ? CampusVectorLayers.surRojo : CampusVectorLayers.centralRojo,
    );
    canvas.drawPath(
      rojoPath,
      Paint()
        ..color = isDark ? const Color(0xFFE02F3C) : const Color(0xFFE4222C)
        ..style = PaintingStyle.fill,
    );

    // 7. Rotulos oficiales de vialidades y referencias del plano DGIU
    final List<EtiquetaVectorialMapa> etiquetas = esSur
        ? CampusVectorLayers.etiquetasSur
        : CampusVectorLayers.etiquetasCentral;
    final double escalaTexto = (imgW / 950.0).clamp(0.65, 1.45);

    for (final EtiquetaVectorialMapa et in etiquetas) {
      final double px = offsetX + et.posX * imgW;
      final double py = offsetY + et.posY * imgH;
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: et.texto,
          style: TextStyle(
            color: et.esVialidad
                ? (isDark ? Colors.white70 : const Color(0xFF1E293B))
                : Colors.white,
            fontSize: et.tamanoFuente * escalaTexto,
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

    // 8. Numeros vectoriales nitidos sobre cada uno de los 153 / 19 edificios individuales
    final double fontEdif = (esSur ? 10.5 : 7.6) * escalaTexto;
    for (final EdificioMapaUaa edif in edificiosCampus) {
      if (edif.codigo.startsWith('ACCESO')) {
        continue;
      }
      final String numTexto =
          edif.codigo.replaceFirst('EDIF ', '').replaceAll('-', '');
      final double px = offsetX + edif.posX * imgW;
      final double py = offsetY + edif.posY * imgH;
      final bool esApoyoAmarillo = edif.zona.contains('Apoyo');

      final TextPainter tpHalo = TextPainter(
        text: TextSpan(
          text: numTexto,
          style: TextStyle(
            fontSize: fontEdif,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color =
                  esApoyoAmarillo ? Colors.white : const Color(0xFF0F172A),
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
            color: esApoyoAmarillo ? const Color(0xFF0F172A) : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset textOffset =
          Offset(px - tpFill.width / 2.0, py - tpFill.height / 2.0);
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
    // 0. Si esta activo el Modo Vectorial 1:1 (Opcion A), dibuja todas las capas del mapa como vectores nativos
    if (dibujarCapasBaseVectoriales) {
      _dibujarMapaBaseVectorial(canvas);
    }

    // 1. Ilumina el poligono exacto del edificio bajo el cursor (Hover)
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

    // 2. Ilumina el poligono exacto del edificio de Origen (Azul institucional)
    _dibujarPoligonoEdificio(
      canvas,
      rutaActiva.origen,
      colorBorde: AppColors.secondaryBlue,
      opacidadRelleno: 0.30,
      grosorBorde: 2.8,
    );

    // 3. Ilumina el poligono exacto del edificio de Destino (Guinda institucional)
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

    final List<Offset> puntos = nodosRuta
        .map(
          (NodoPasilloUaa n) => Offset(
            offsetX + n.posX * imgW,
            offsetY + n.posY * imgH,
          ),
        )
        .toList();

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

    final double distanciaVisible =
        longitudTotal * progresoAnimacion.clamp(0.0, 1.0);

    final Path rutaPath = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    double acumulado = 0.0;

    for (int i = 0; i < puntos.length - 1; i++) {
      final double segLen = longitudesSegmentos[i];
      if (acumulado + segLen <= distanciaVisible) {
        rutaPath.lineTo(puntos[i + 1].dx, puntos[i + 1].dy);
        acumulado += segLen;
      } else {
        final double restante = distanciaVisible - acumulado;
        if (restante > 0 && segLen > 0) {
          final double t = (restante / segLen).clamp(0.0, 1.0);
          final Offset parcial = Offset.lerp(puntos[i], puntos[i + 1], t)!;
          rutaPath.lineTo(parcial.dx, parcial.dy);
        }
        break;
      }
    }

    // 4. Halo exterior blanco de la ruta peatonal
    final Paint bordeBlancoPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(rutaPath, bordeBlancoPaint);

    // 5. Linea principal azul de la ruta peatonal por los pasillos internos
    final Paint lineaRutaPaint = Paint()
      ..color = AppColors.secondaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(rutaPath, lineaRutaPaint);

    // 6. Nodos de giro en los cruceros de pasillos y marcadores de Origen y Destino
    final Paint puntoBlancoPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint puntoPasilloPaint = Paint()
      ..color = AppColors.primaryNavy
      ..style = PaintingStyle.fill;

    for (int i = 1; i < puntos.length - 1; i++) {
      canvas.drawCircle(puntos[i], 3.8, puntoBlancoPaint);
      canvas.drawCircle(puntos[i], 2.3, puntoPasilloPaint);
    }

    canvas.drawCircle(puntos.first, 7.5, puntoBlancoPaint);
    canvas.drawCircle(
      puntos.first,
      5.2,
      Paint()..color = AppColors.secondaryBlue,
    );

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
        oldDelegate.dibujarCapasBaseVectoriales !=
            dibujarCapasBaseVectoriales ||
        oldDelegate.isDark != isDark ||
        oldDelegate.idCampus != idCampus ||
        oldDelegate.rutaActiva != rutaActiva ||
        oldDelegate.edificioHover != edificioHover ||
        oldDelegate.imgW != imgW ||
        oldDelegate.imgH != imgH;
  }
}
