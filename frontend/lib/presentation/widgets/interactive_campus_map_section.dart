import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/campus_vector_layers.dart';
import '../../data/repositories/portal_repository.dart';
import '../../domain/entities/portal_models.dart';

// Navegador interactivo a pantalla completa con estructura estilo Google Maps (PC, Tablet y Celular)
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

  // Historial reciente de edificios consultados en la sesion actual
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
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _chipsScrollController.dispose();
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
    _categoriaFiltroActiva = '';
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
        _aplicarEncuadreInicialAmplio();
      });
    }
  }

  // Aplica un encuadre inicial amplio para que el mapa domine toda la pantalla sin margenes vacios
  void _aplicarEncuadreInicialAmplio() {
    if (!mounted || _tamanoVisor.width <= 0 || _tamanoVisor.height <= 0) {
      return;
    }
    final double scale = _idCampusMapa == 1 ? 1.42 : 1.22;
    final double targetX = _idCampusMapa == 1 ? 0.56 : 0.62;
    final double targetY = _idCampusMapa == 1 ? 0.66 : 0.44;

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
      _aplicarEncuadreInicialAmplio();
    });
  }

  // Registra un edificio en la lista de recientes y lo fija como destino
  void _seleccionarEdificioDestino(
    EdificioMapaUaa edificio, {
    bool enfocarCamara = true,
  }) {
    setState(() {
      _idNodoDestino = edificio.idNodo;
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
      final RutaPeatonalUaa nuevaRuta = widget.repository.calcularRutaPeatonal(
        idCampus: _idCampusMapa,
        idNodoOrigen: _idNodoOrigen,
        idNodoDestino: edificio.idNodo,
      );
      _enfocarRutaEnCamara(nuevaRuta);
    }
  }

  // Fija la ubicacion actual del usuario en el acceso principal del campus activo
  void _fijarMiUbicacionActual() {
    setState(() {
      _idNodoOrigen =
          _idCampusMapa == 1 ? 'CEN-B-ACCESO_SUR' : 'SUR-B-ACCESO_SUR';
    });
    _aplicarEncuadreInicialAmplio();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _idCampusMapa == 1
              ? 'Ubicacion actual centrada en: Acceso Principal Av. Universidad (Campus Central).'
              : 'Ubicacion actual centrada en: Plaza de Acceso Prol. Mahatma Gandhi (Campus Sur).',
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
    final double nextScale = (currentScale * factor).clamp(0.85, 5.5);
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
    final double targetScale = math.min(scaleX, scaleY).clamp(1.30, 2.85);

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

  // Evalua si un edificio pertenece a una de las categorias rapidas de la barra superior tipo Google Maps
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
    final bool isPcOrLaptop = screenWidth >= 1024;
    final bool isMobile = screenWidth < 700;

    final String mapAsset = _idCampusMapa == 1
        ? AppConstants.mapaOficialCentralAsset
        : AppConstants.mapaOficialSurAsset;

    final double aspectRatioMapa =
        _idCampusMapa == 1 ? (1692.0 / 1650.0) : (1810.0 / 799.0);

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
                ? (isDark ? const Color(0xFF131D2B) : const Color(0xFFE9EEF5))
                : Colors.white,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // 1. LIENZO DEL MAPA A PANTALLA COMPLETA (Protagonista de la interfaz)
                InteractiveViewer(
                  transformationController: _zoomController,
                  minScale: 0.85,
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

                // 2. BARRA SUPERIOR FLOTANTE ESTILO GOOGLE MAPS (Pildora de Busqueda + Chips de Categorias)
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

                // 4. BOTON CUADRADO INFERIOR IZQUIERDO "CAPAS" (Identico a Google Maps en PC, Tablet y Movil)
                Positioned(
                  bottom: 22,
                  left: 14,
                  child: _buildGoogleMapsCapasSquareButton(isDark),
                ),

                // 5. PILDORA COMPACTA INFERIOR CENTRAL DE RUTA ACTIVA (No estorba la vista del mapa)
                Positioned(
                  bottom: 22,
                  left: isMobile ? 86 : 94,
                  right: 68,
                  child: Align(
                    alignment:
                        isMobile ? Alignment.bottomLeft : Alignment.bottomCenter,
                    child: _buildCompactRouteBottomPill(
                      isDark: isDark,
                      isMobile: isMobile,
                      rutaActiva: rutaActiva,
                    ),
                  ),
                ),

                // 6. CONTROLES INFERIORES DERECHOS: CIRCULO MI UBICACION + PILDORA VERTICAL (+ / -)
                Positioned(
                  bottom: 22,
                  right: 14,
                  child: _buildGoogleMapsRightControls(isDark, rutaActiva),
                ),

                // 7. BARRA INFERIOR DERECHA DE DATOS DEL MAPA Y ESCALA (Como el pie de 14px de Google Maps)
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
                            'Datos del plano oficial DGIU UAA 2026 • ${_idCampusMapa == 1 ? 'Campus Central (153 edificios)' : 'Campus Sur (19 edificios)'} • 50 m ',
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
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                                right: BorderSide(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                                bottom: BorderSide(
                                  color: isDark ? Colors.white70 : Colors.black87,
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
    final Color borderCol =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color iconCol =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF3C4043);

    return Container(
      width: 68,
      decoration: BoxDecoration(
        color: railBg,
        border: Border(
          right: BorderSide(color: borderCol),
        ),
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
          // Boton miniatura para alternar entre Campus Central y Campus Sur
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
            onTap: _aplicarEncuadreInicialAmplio,
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
    final Color activeCol =
        isDark ? AppColors.footerAccentBlue : AppColors.secondaryBlue;
    final Color normalCol =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF444746);

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
                border: activo ? Border.all(color: activeCol, width: 1.4) : null,
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

  // Encabezado flotante superior estilo Google Maps:
  // En PC y Tablet: Pildora de busqueda a la izquierda y Chips de categorias a la derecha en la misma fila.
  // En Celular: Pildora de busqueda arriba (ancho completo) y Chips de categorias justo debajo.
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
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 380,
          child: searchPillColumn,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: categoryChipsRow,
          ),
        ),
      ],
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
    final Color borderCol =
        isDark ? AppColors.darkBorder : const Color(0xFFDADCE0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Pildora principal "Buscar en Mapa UAA"
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
              // Icono de Rombo Azul de Indicaciones ("Como llegar") identico a Google Maps
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

        // Desplegable 1: Sugerencias en tiempo real al escribir o filtrar por categoria
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

        // Desplegable 2: Panel de Ruta y Paso a Paso (se abre al tocar el rombo azul o "Ver pasos")
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

  // Barra horizontal de pildoras de filtro rapido estilo Google Maps ("Restaurantes, Hoteles..." -> Categorias UAA)
  Widget _buildGoogleMapsCategoryChipsBar({
    required bool isDark,
    required List<EdificioMapaUaa> todosEdificios,
  }) {
    final List<Map<String, Object>> categorias = <Map<String, Object>>[
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
    final Color borderCol =
        isDark ? AppColors.darkBorder : const Color(0xFFDADCE0);

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
          final bool esSwitchCampus = id == 'CAMPUS_SWITCH';
          final bool activo =
              esSwitchCampus || (_categoriaFiltroActiva == id);

          return Material(
            color: activo
                ? (esSwitchCampus
                    ? AppColors.primaryNavy
                    : AppColors.secondaryBlue)
                : chipBg,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
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
                        fontWeight: FontWeight.w700,
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

  // Panel desplegable de configuracion de ruta e indicaciones paso a paso (cerrable con X)
  Widget _buildCollapsibleRouteDrawerCard({
    required ThemeData theme,
    required bool isDark,
    required List<EdificioMapaUaa> todosEdificios,
    required RutaPeatonalUaa rutaActiva,
  }) {
    final Color cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol =
        isDark ? AppColors.darkBorder : const Color(0xFFDADCE0);

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
                    'Ruta Peatonal: ${rutaActiva.tiempoMinutos} min (${rutaActiva.distanciaMetros} m)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Cerrar panel de ruta',
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
          // Selector de Origen ("Desde donde partes")
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
                    value: todosEdificios.any(
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
          // Destino actual
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
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rutaActiva.indicacionesPasoAPaso.map((String paso) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
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
                        const SizedBox(width: 6),
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
      ),
    );
  }

  // Boton cuadrado inferior izquierdo "Capas" identico a las 3 capturas de referencia de Google Maps
  Widget _buildGoogleMapsCapasSquareButton(bool isDark) {
    final Color borderCol =
        isDark ? AppColors.darkBorder : Colors.white;

    return Tooltip(
      message: _modoVectorialEstilizado
          ? 'Cambiar a Plano Oficial DGIU'
          : 'Cambiar a Mapa Vectorial 1:1',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _modoVectorialEstilizado = !_modoVectorialEstilizado;
          });
        },
        child: Container(
          width: 66,
          height: 66,
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
              // Miniatura del otro modo de mapa
              Opacity(
                opacity: 0.72,
                child: Image.asset(
                  _idCampusMapa == 1
                      ? AppConstants.mapaOficialCentralAsset
                      : AppConstants.mapaOficialSurAsset,
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  color: Colors.black.withValues(alpha: 0.68),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.layers, color: Colors.white, size: 12),
                      SizedBox(width: 3),
                      Text(
                        'Capas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pildora inferior compacta de una sola linea con el resumen de la ruta activa (sin tapar el mapa)
  Widget _buildCompactRouteBottomPill({
    required bool isDark,
    required bool isMobile,
    required RutaPeatonalUaa rutaActiva,
  }) {
    final Color pillBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color borderCol =
        isDark ? AppColors.darkBorder : const Color(0xFFDADCE0);

    return Material(
      color: pillBg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          setState(() {
            _mostrarPanelRutas = !_mostrarPanelRutas;
            _mostrarSugerencias = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderCol, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.directions_walk,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${rutaActiva.tiempoMinutos} min (${rutaActiva.distanciaMetros} m)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isMobile
                      ? 'Hacia ${rutaActiva.destino.codigo}'
                      : '${rutaActiva.origen.codigo} -> ${rutaActiva.destino.codigo} (${rutaActiva.destino.nombre})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.secondaryBlue,
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
    final Color borderCol =
        isDark ? AppColors.darkBorder : const Color(0xFFDADCE0);
    final Color iconCol =
        isDark ? Colors.white : const Color(0xFF3C4043);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Boton circular de Ubicacion Actual / Enfocar Ruta
        Material(
          color: cardBg,
          shape: CircleBorder(side: BorderSide(color: borderCol)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _fijarMiUbicacionActual,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.my_location,
                size: 19,
                color: iconCol,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Pildora vertical compacta con + y -
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
            _aplicarEncuadreInicialAmplio();
          });
        }

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
                      ),
                    ),
                  ),
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

    final Path verdePath = _construirPathEvenOdd(
      esSur ? CampusVectorLayers.surVerde : CampusVectorLayers.centralVerde,
    );
    canvas.drawPath(
      verdePath,
      Paint()
        ..color = isDark ? const Color(0xFF435426) : const Color(0xFF88943A)
        ..style = PaintingStyle.fill,
    );

    final Path grisPath = _construirPathEvenOdd(
      esSur ? CampusVectorLayers.surGris : CampusVectorLayers.centralGris,
    );
    canvas.drawPath(
      grisPath,
      Paint()
        ..color = isDark ? const Color(0xFF6B7485) : const Color(0xFFBCBEC4)
        ..style = PaintingStyle.fill,
    );

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

    final Path azulPath = _construirPathEvenOdd(
      esSur ? CampusVectorLayers.surAzul : CampusVectorLayers.centralAzul,
    );
    canvas.drawPath(
      azulPath,
      Paint()
        ..color = isDark ? const Color(0xFF4B6C9E) : const Color(0xFF475C88)
        ..style = PaintingStyle.fill,
    );

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

    final Path rojoPath = _construirPathEvenOdd(
      esSur ? CampusVectorLayers.surRojo : CampusVectorLayers.centralRojo,
    );
    canvas.drawPath(
      rojoPath,
      Paint()
        ..color = isDark ? const Color(0xFFE02F3C) : const Color(0xFFE4222C)
        ..style = PaintingStyle.fill,
    );

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

    _dibujarPoligonoEdificio(
      canvas,
      rutaActiva.origen,
      colorBorde: AppColors.secondaryBlue,
      opacidadRelleno: 0.30,
      grosorBorde: 2.8,
    );

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
