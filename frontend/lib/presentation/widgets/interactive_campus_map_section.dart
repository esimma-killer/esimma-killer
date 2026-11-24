import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/portal_repository.dart';
import '../../domain/entities/portal_models.dart';
import 'hover_animated_card.dart';

// Pantalla de Mapa Universitario con los mapas oficiales DGIU UAA (Central y Sur) y zoom interactivo
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
  int _indiceEdificioSeleccionado = 0;
  String _busquedaEdificio = '';
  final TransformationController _zoomController = TransformationController();

  @override
  void initState() {
    super.initState();
    _idCampusMapa = widget.initialCampusId;
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  // Actualiza el campus del mapa si cambia el campus principal detectado del usuario
  @override
  void didUpdateWidget(covariant InteractiveCampusMapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCampusId != widget.initialCampusId) {
      _idCampusMapa = widget.initialCampusId;
      _indiceEdificioSeleccionado = 0;
      _zoomController.value = Matrix4.identity();
    }
  }

  // Cambia entre el Mapa Oficial de Campus Central y el Mapa Oficial de Campus Sur
  void _cambiarCampusMapa(int idCampus) {
    setState(() {
      _idCampusMapa = idCampus;
      _indiceEdificioSeleccionado = 0;
      _zoomController.value = Matrix4.identity();
    });
  }

  // Aumenta el nivel de zoom sobre el mapa oficial
  void _acercarZoom() {
    final Matrix4 current = _zoomController.value.clone();
    current.scaleByDouble(1.25, 1.25, 1.0, 1.0);
    _zoomController.value = current;
  }

  // Restablece el zoom original del mapa oficial
  void _restablecerZoom() {
    _zoomController.value = Matrix4.identity();
  }

  // Abre el mapa oficial en un visor modal a pantalla completa con zoom libre
  void _abrirMapaPantallaCompleta(String mapAsset, String nombreCampus) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text('Mapa Oficial DGIU - $nombreCampus'),
              actions: <Widget>[
                TextButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'Cerrar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: Image.asset(
                    mapAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Construye el visor del mapa oficial DGIU UAA y el directorio interactivo de edificios
  @override
  Widget build(BuildContext context) {
    final List<EdificioMapaUaa> todosEdificios =
        widget.repository.obtenerEdificiosMapa(idCampus: _idCampusMapa);
    final List<EdificioMapaUaa> edificiosFiltrados =
        _busquedaEdificio.trim().isEmpty
            ? todosEdificios
            : todosEdificios.where((EdificioMapaUaa e) {
                final String q = _busquedaEdificio.toLowerCase();
                return e.codigo.toLowerCase().contains(q) ||
                    e.nombre.toLowerCase().contains(q) ||
                    e.tramitesServicios.toLowerCase().contains(q) ||
                    e.zona.toLowerCase().contains(q);
              }).toList();

    final List<EdificioMapaUaa> listaActiva =
        edificiosFiltrados.isNotEmpty ? edificiosFiltrados : todosEdificios;
    final int safeIndex =
        _indiceEdificioSeleccionado.clamp(0, listaActiva.length - 1);
    final EdificioMapaUaa edificioActivo = listaActiva[safeIndex];

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 980;

    final String mapAsset = _idCampusMapa == 1
        ? AppConstants.mapaOficialCentralAsset
        : AppConstants.mapaOficialSurAsset;
    final String nombreCampus =
        _idCampusMapa == 1 ? 'Campus Central (Ciudad Universitaria)' : 'Campus Sur';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'MAPA OFICIAL DGIU UAA Y UBICADOR DE EDIFICIOS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.footerAccentBlue
                            : AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Puedes hacer zoom y arrastrar el mapa oficial, o seleccionar cualquier edificio de la lista para resaltarlo:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('Campus Central'),
                      selected: _idCampusMapa == 1,
                      onSelected: (_) => _cambiarCampusMapa(1),
                    ),
                    ChoiceChip(
                      label: const Text('Campus Sur'),
                      selected: _idCampusMapa == 2,
                      onSelected: (_) => _cambiarCampusMapa(2),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Barra de filtro rapido de edificios o laboratorios
            TextField(
              decoration: InputDecoration(
                hintText:
                    'Filtrar edificio por numero, carrera, laboratorio o tramite (ej. 1-A, 224, 65, 202, Cajas, Biblioteca, UMD)...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceMuted
                    : AppColors.lightSurfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onChanged: (String value) {
                setState(() {
                  _busquedaEdificio = value;
                  _indiceEdificioSeleccionado = 0;
                });
              },
            ),
            const SizedBox(height: 20),
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildOfficialMapViewer(
                    mapAsset: mapAsset,
                    nombreCampus: nombreCampus,
                    edificioActivo: edificioActivo,
                    isDark: isDark,
                    mapHeight: 420,
                  ),
                  const SizedBox(height: 20),
                  _buildBuildingDirectoryAndDetail(
                    theme,
                    listaActiva,
                    edificioActivo,
                    safeIndex,
                    isDark,
                    secondaryTextColor,
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 7,
                    child: _buildOfficialMapViewer(
                      mapAsset: mapAsset,
                      nombreCampus: nombreCampus,
                      edificioActivo: edificioActivo,
                      isDark: isDark,
                      mapHeight: 580,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 5,
                    child: _buildBuildingDirectoryAndDetail(
                      theme,
                      listaActiva,
                      edificioActivo,
                      safeIndex,
                      isDark,
                      secondaryTextColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Visor interactivo con el mapa oficial de la UAA, controles de zoom y marcador del edificio activo
  Widget _buildOfficialMapViewer({
    required String mapAsset,
    required String nombreCampus,
    required EdificioMapaUaa edificioActivo,
    required bool isDark,
    required double mapHeight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Barra de herramientas superior del mapa oficial (Zoom +, Restablecer y Pantalla Completa)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              Text(
                'PLANO OFICIAL DGIU - ${nombreCampus.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _acercarZoom,
                    icon: const Icon(Icons.zoom_in, size: 16),
                    label: const Text('Acercar'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _restablecerZoom,
                    icon: const Icon(Icons.center_focus_strong, size: 16),
                    label: const Text('100%'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondaryBlue,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () =>
                        _abrirMapaPantallaCompleta(mapAsset, nombreCampus),
                    icon: const Icon(Icons.fullscreen, size: 16),
                    label: const Text('Pantalla Completa'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          height: mapHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: InteractiveViewer(
            transformationController: _zoomController,
            minScale: 1.0,
            maxScale: 4.0,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double w = constraints.maxWidth;
                final double h = constraints.maxHeight;
                final double pinLeft =
                    (edificioActivo.posX * w - 58).clamp(8.0, w - 124.0);
                final double pinTop =
                    (edificioActivo.posY * h - 38).clamp(8.0, h - 48.0);

                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    // Imagen oficial del mapa de Campus Central o Campus Sur con transicion suave
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Image.asset(
                        mapAsset,
                        key: ValueKey<String>(mapAsset),
                        width: w,
                        height: h,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Indicador animado que senala la zona aproximada del edificio seleccionado
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: pinLeft,
                      top: pinTop,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentCrimson,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              edificioActivo.codigo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Construye la ficha detallada del edificio seleccionado y la lista completa de edificios del mapa
  Widget _buildBuildingDirectoryAndDetail(
    ThemeData theme,
    List<EdificioMapaUaa> edificios,
    EdificioMapaUaa edificioActivo,
    int safeIndex,
    bool isDark,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          child: Container(
            key: ValueKey<String>(edificioActivo.codigo),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceMuted
                  : AppColors.lightSurfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.accentCrimson,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentCrimson,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'EDIFICIO SELECCIONADO: ${edificioActivo.codigo}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      'Horario: ${edificioActivo.horarioAtencion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  edificioActivo.nombre,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ubicacion en plano: ${edificioActivo.zona}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.footerAccentBlue
                        : AppColors.secondaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Tramites, laboratorios y espacios en este edificio:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  edificioActivo.tramitesServicios,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Edificios destacados en este plano (${edificios.length}):',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...edificios.asMap().entries.map(
          (MapEntry<int, EdificioMapaUaa> entry) {
            final bool activo = entry.key == safeIndex;
            final EdificioMapaUaa item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HoverAnimatedCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                backgroundColor: activo
                    ? (isDark
                        ? AppColors.darkSurfaceMuted
                        : const Color(0xFFE3ECF8))
                    : (isDark ? AppColors.darkSurface : Colors.white),
                activeBorderColor: AppColors.accentCrimson,
                onTap: () {
                  setState(() {
                    _indiceEdificioSeleccionado = entry.key;
                  });
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: activo
                            ? AppColors.accentCrimson
                            : AppColors.primaryNavy,
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.nombre,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            item.zona,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
