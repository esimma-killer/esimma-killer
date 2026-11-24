import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/portal_models.dart';
import 'hover_animated_card.dart';

// Seccion interactiva de actividades de creditos humanisticos con tarjetas animadas
class UniversityActivitiesSection extends StatefulWidget {
  final List<ActividadUniversitaria> todasLasActividades;
  final ValueChanged<String> onInscribirseActividad;

  const UniversityActivitiesSection({
    super.key,
    required this.todasLasActividades,
    required this.onInscribirseActividad,
  });

  @override
  State<UniversityActivitiesSection> createState() =>
      _UniversityActivitiesSectionState();
}

class _UniversityActivitiesSectionState
    extends State<UniversityActivitiesSection> {
  String _categoriaSeleccionada = 'Todas';

  static const List<String> _categorias = <String>[
    'Todas',
    'Formacion Humanistica',
    'Deportes y Cultura',
    'Talleres y Congresos',
    'Apoyo Docente',
  ];

  // Construye las pestanas de filtro por tipo de actividad y la lista animada de tarjetas
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final List<ActividadUniversitaria> filtradas =
        _categoriaSeleccionada == 'Todas'
            ? widget.todasLasActividades
            : widget.todasLasActividades
                .where(
                  (ActividadUniversitaria a) =>
                      a.categoria == _categoriaSeleccionada,
                )
                .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _categorias.map((String cat) {
            final bool seleccionada = _categoriaSeleccionada == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: seleccionada,
              onSelected: (_) {
                setState(() {
                  _categoriaSeleccionada = cat;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          child: LayoutBuilder(
            key: ValueKey<String>(_categoriaSeleccionada),
            builder: (BuildContext context, BoxConstraints constraints) {
              final double maxW = constraints.maxWidth;
              final int cols = maxW >= 1020 ? 3 : (maxW >= 640 ? 2 : 1);
              const double spacing = 16;
              final double itemW = (maxW - (spacing * (cols - 1))) / cols;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: filtradas.map((ActividadUniversitaria act) {
                  return SizedBox(
                    width: itemW,
                    child: _buildActivityCard(
                      theme,
                      act,
                      isDark,
                      secondaryTextColor,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // Construye la tarjeta animada de una actividad universitaria con insignia de creditos
  Widget _buildActivityCard(
    ThemeData theme,
    ActividadUniversitaria act,
    bool isDark,
    Color secondaryTextColor,
  ) {
    final bool esCreditoHumanistico =
        act.categoria == 'Formacion Humanistica';

    return HoverAnimatedCard(
      padding: const EdgeInsets.all(18),
      activeBorderColor:
          esCreditoHumanistico ? AppColors.accentCrimson : AppColors.secondaryBlue,
      onTap: () => widget.onInscribirseActividad(act.titulo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: esCreditoHumanistico
                      ? AppColors.accentCrimson
                      : AppColors.secondaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  act.beneficio,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceMuted
                      : AppColors.lightSurfaceMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  act.categoria,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            act.titulo,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                Icons.event_outlined,
                size: 15,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  act.fechaHora,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  act.lugar,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: 15,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  act.modalidadCupo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => widget.onInscribirseActividad(act.titulo),
              child: const Text('Registrar Asistencia en E-SIIMA'),
            ),
          ),
        ],
      ),
    );
  }
}
