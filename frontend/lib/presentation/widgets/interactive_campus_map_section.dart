import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/portal_repository.dart';
import '../../domain/entities/portal_models.dart';

// Pantalla completa de Mapa Universitario con croquis amplio, buscador y directorio de edificios
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

  @override
  void initState() {
    super.initState();
    _idCampusMapa = widget.initialCampusId;
  }

  // Actualiza el campus del mapa si cambia el campus principal detectado del usuario
  @override
  void didUpdateWidget(covariant InteractiveCampusMapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCampusId != widget.initialCampusId) {
      _idCampusMapa = widget.initialCampusId;
      _indiceEdificioSeleccionado = 0;
    }
  }

  // Cambia el campus visualizado en el croquis interactivo
  void _cambiarCampusMapa(int idCampus) {
    setState(() {
      _idCampusMapa = idCampus;
      _indiceEdificioSeleccionado = 0;
    });
  }

  // Construye el mapa universitario amplio con buscador de salones/edificios y ficha lateral
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
                      'CROQUIS INTERACTIVO DE EDIFICIOS, AULAS, LABORATORIOS Y CAJAS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.footerAccentBlue
                            : AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona un marcador en el mapa o filtra por nombre/tramite para ubicar cualquier edificio del campus:',
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
                      label: const Text('Campus Central (Ciudad Universitaria)'),
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
                    'Filtrar edificio por numero, carrera, laboratorio o tramite (ej. Edif 60, Cajas, Biblioteca, UMD)...',
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
                  _buildInteractiveCroquisCanvas(
                    listaActiva,
                    safeIndex,
                    isDark,
                    440,
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
                    child: _buildInteractiveCroquisCanvas(
                      listaActiva,
                      safeIndex,
                      isDark,
                      560,
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

  // Construye el lienzo amplio del croquis universitario con avenidas, cuadrantes y pines clickeables
  Widget _buildInteractiveCroquisCanvas(
    List<EdificioMapaUaa> edificios,
    int safeIndex,
    bool isDark,
    double mapHeight,
  ) {
    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2B) : const Color(0xFFE9F0F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          return Stack(
            children: <Widget>[
              // Trazado arquitectonico de andadores, estacionamientos y jardines del campus
              Positioned.fill(
                child: CustomPaint(
                  painter: _CampusCroquisPainter(isDark: isDark),
                ),
              ),
              // Etiqueta de orientacion norte y avenida principal
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _idCampusMapa == 1
                        ? 'MAPA CIUDAD UNIVERSITARIA - AV. UNIVERSIDAD #940 (NORTE ARRIBA)'
                        : 'MAPA CAMPUS SUR - BLVD. JOSE MARIA CHAVEZ (NORTE ARRIBA)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Leyenda inferior de colores del mapa
              Positioned(
                bottom: 12,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xD9171F2A)
                        : const Color(0xE6FFFFFF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Wrap(
                    spacing: 14,
                    children: <Widget>[
                      _buildLegendItem(
                        color: AppColors.accentCrimson,
                        label: 'Edificio Seleccionado',
                      ),
                      _buildLegendItem(
                        color: AppColors.primaryNavy,
                        label: 'Edificios y Laboratorios UAA',
                      ),
                    ],
                  ),
                ),
              ),
              // Marcadores interactivos de edificios sobre el croquis amplio
              ...edificios.asMap().entries.map(
                (MapEntry<int, EdificioMapaUaa> entry) {
                  final int idx = entry.key;
                  final EdificioMapaUaa edif = entry.value;
                  final bool activo = idx == safeIndex;
                  final double left =
                      (edif.posX * (width - 130)).clamp(14, width - 130);
                  final double top =
                      (edif.posY * (height - 56)).clamp(48, height - 56);

                  return Positioned(
                    left: left,
                    top: top,
                    child: AnimatedScale(
                      scale: activo ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _indiceEdificioSeleccionado = idx;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: activo
                                ? AppColors.accentCrimson
                                : AppColors.primaryNavy,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white,
                              width: activo ? 2.5 : 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                activo ? Icons.location_on : Icons.apartment,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                edif.codigo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Elemento de leyenda del mapa
  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Construye la ficha detallada del edificio seleccionado y la lista completa de edificios del campus
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
                  'Ubicacion en campus: ${edificioActivo.zona}',
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
          'Directorio completo de edificios en este campus (${edificios.length}):',
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
              child: Material(
                color: activo
                    ? (isDark
                        ? AppColors.darkSurfaceMuted
                        : const Color(0xFFE3ECF8))
                    : (isDark ? AppColors.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    setState(() {
                      _indiceEdificioSeleccionado = entry.key;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: activo
                            ? AppColors.secondaryBlue
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      ),
                    ),
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
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Pintor plano para dibujar las vialidades, cuadrantes y jardines del croquis universitario
class _CampusCroquisPainter extends CustomPainter {
  final bool isDark;

  const _CampusCroquisPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = isDark ? const Color(0xFF1F2D40) : const Color(0xFFD3DFEE)
      ..strokeWidth = 1;

    // Cuadricula arquitectonica de referencia
    const int step = 45;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Areas verdes / jardines centrales planos
    final Paint greenPaint = Paint()
      ..color = isDark ? const Color(0xFF182A26) : const Color(0xFFD7EAD9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.14,
          size.width * 0.76,
          size.height * 0.72,
        ),
        const Radius.circular(8),
      ),
      greenPaint,
    );

    // Andadores peatonales principales del campus
    final Paint pathPaint = Paint()
      ..color = isDark ? const Color(0xFF28374C) : const Color(0xFFC2D1E5)
      ..strokeWidth = 14;

    canvas.drawLine(
      Offset(size.width * 0.06, size.height * 0.50),
      Offset(size.width * 0.94, size.height * 0.50),
      pathPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.08),
      Offset(size.width * 0.48, size.height * 0.92),
      pathPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.14),
      Offset(size.width * 0.25, size.height * 0.86),
      pathPaint..strokeWidth = 8,
    );
    canvas.drawLine(
      Offset(size.width * 0.74, size.height * 0.14),
      Offset(size.width * 0.74, size.height * 0.86),
      pathPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CampusCroquisPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
