import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/portal_repository.dart';
import '../../domain/entities/portal_models.dart';

// Croquis y ubicador interactivo de edificios de Campus Central y Campus Sur
class InteractiveCampusMapSection extends StatefulWidget {
  final PortalRepository repository;

  const InteractiveCampusMapSection({
    super.key,
    required this.repository,
  });

  @override
  State<InteractiveCampusMapSection> createState() =>
      _InteractiveCampusMapSectionState();
}

class _InteractiveCampusMapSectionState
    extends State<InteractiveCampusMapSection> {
  int _idCampusMapa = 1;
  int _indiceEdificioSeleccionado = 0;

  // Cambia el campus visualizado en el croquis interactivo
  void _cambiarCampusMapa(int idCampus) {
    setState(() {
      _idCampusMapa = idCampus;
      _indiceEdificioSeleccionado = 0;
    });
  }

  // Construye el croquis visual a la izquierda y el detalle del edificio a la derecha
  @override
  Widget build(BuildContext context) {
    final List<EdificioMapaUaa> edificios =
        widget.repository.obtenerEdificiosMapa(idCampus: _idCampusMapa);
    final EdificioMapaUaa edificioActivo =
        edificios[_indiceEdificioSeleccionado];

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 920;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      'UBICADOR INTERACTIVO DE EDIFICIOS, LABORATORIOS Y CAJAS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.footerAccentBlue
                            : AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Haz clic en cualquier marcador del croquis o de la lista para ver que tramites y salones se encuentran ahi:',
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
                      label: const Text('Campus Central (C.U.)'),
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
            const SizedBox(height: 20),
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildInteractiveCroquisCanvas(edificios, isDark),
                  const SizedBox(height: 16),
                  _buildBuildingDirectoryAndDetail(
                    theme,
                    edificios,
                    edificioActivo,
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
                    flex: 6,
                    child: _buildInteractiveCroquisCanvas(edificios, isDark),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 5,
                    child: _buildBuildingDirectoryAndDetail(
                      theme,
                      edificios,
                      edificioActivo,
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

  // Construye el lienzo del croquis universitario con avenidas y pines clickeables
  Widget _buildInteractiveCroquisCanvas(
    List<EdificioMapaUaa> edificios,
    bool isDark,
  ) {
    return Container(
      height: 360,
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
              // Trazado arquitectonico de andadores y jardines del campus
              Positioned.fill(
                child: CustomPaint(
                  painter: _CampusCroquisPainter(isDark: isDark),
                ),
              ),
              // Etiqueta de orientacion norte y avenida principal
              Positioned(
                top: 12,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _idCampusMapa == 1
                        ? 'CROQUIS CIUDAD UNIVERSITARIA (AV. UNIVERSIDAD #940)'
                        : 'CROQUIS CAMPUS SUR (BLVD. JOSE MARIA CHAVEZ)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Marcadores interactivos de edificios sobre el croquis
              ...edificios.asMap().entries.map(
                (MapEntry<int, EdificioMapaUaa> entry) {
                  final int idx = entry.key;
                  final EdificioMapaUaa edif = entry.value;
                  final bool activo = idx == _indiceEdificioSeleccionado;
                  final double left = (edif.posX * (width - 110)).clamp(12, width - 110);
                  final double top = (edif.posY * (height - 48)).clamp(42, height - 48);

                  return Positioned(
                    left: left,
                    top: top,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _indiceEdificioSeleccionado = idx;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: activo
                              ? AppColors.accentCrimson
                              : AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white,
                            width: activo ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              activo ? Icons.location_on : Icons.apartment,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              edif.codigo,
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
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Construye la lista seleccionable de edificios y la ficha informativa del edificio activo
  Widget _buildBuildingDirectoryAndDetail(
    ThemeData theme,
    List<EdificioMapaUaa> edificios,
    EdificioMapaUaa edificioActivo,
    bool isDark,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.darkSurfaceMuted : AppColors.lightSurfaceMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.accentCrimson,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentCrimson,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      edificioActivo.codigo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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
              const SizedBox(height: 10),
              Text(
                edificioActivo.nombre,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                edificioActivo.zona,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.footerAccentBlue
                      : AppColors.secondaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tramites y espacios: ${edificioActivo.tramitesServicios}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Selecciona otro edificio del campus:',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: edificios.asMap().entries.map(
            (MapEntry<int, EdificioMapaUaa> entry) {
              final bool activo = entry.key == _indiceEdificioSeleccionado;
              return ChoiceChip(
                label: Text('${entry.value.codigo} - ${entry.value.nombre.split('(').first.trim()}'),
                selected: activo,
                onSelected: (_) {
                  setState(() {
                    _indiceEdificioSeleccionado = entry.key;
                  });
                },
              );
            },
          ).toList(),
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
          size.width * 0.14,
          size.height * 0.18,
          size.width * 0.72,
          size.height * 0.64,
        ),
        const Radius.circular(8),
      ),
      greenPaint,
    );

    // Andadores peatonales principales del campus
    final Paint pathPaint = Paint()
      ..color = isDark ? const Color(0xFF28374C) : const Color(0xFFC2D1E5)
      ..strokeWidth = 12;

    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.50),
      Offset(size.width * 0.92, size.height * 0.50),
      pathPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.12),
      Offset(size.width * 0.50, size.height * 0.88),
      pathPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CampusCroquisPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
