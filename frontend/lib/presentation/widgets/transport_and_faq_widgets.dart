import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/portal_models.dart';

// Monitor de Transporte Universitario entre Campus Central y Sur (Pestana Servicios y Horarios)
class UniversityTransportMonitor extends StatelessWidget {
  final List<RutaTransporteUaa> rutas;

  const UniversityTransportMonitor({
    super.key,
    required this.rutas,
  });

  // Renderiza las tarjetas de proximas salidas de autobuses internos si existen rutas activas
  @override
  Widget build(BuildContext context) {
    if (rutas.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.directions_bus_filled_outlined,
                  color: isDark
                      ? AppColors.footerAccentBlue
                      : AppColors.primaryNavy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MONITOR DE TRANSPORTE UNIVERSITARIO GALLOS (RUTAS INTERCAMPUS)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.footerAccentBlue
                          : AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Salidas programadas entre Ciudad Universitaria (Campus Central) y Campus Sur:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double maxW = constraints.maxWidth;
                final int cols = maxW >= 960 ? 3 : (maxW >= 620 ? 2 : 1);
                const double spacing = 14;
                final double itemW = (maxW - (spacing * (cols - 1))) / cols;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: rutas.map((RutaTransporteUaa ruta) {
                    return SizedBox(
                      width: itemW,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceMuted
                              : AppColors.lightSurfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 8,
                              runSpacing: 4,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusActive,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ruta.proximaSalida,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  ruta.frecuencia,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ruta.nombreRuta,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Origen: ${ruta.paraderoOrigen}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Destino: ${ruta.paraderoDestino}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Guia interactiva paso a paso de tramites frecuentes (Pestana Calendario y Tramites)
class StepByStepProceduresFaq extends StatelessWidget {
  final List<GuiaTramiteFaqUaa> guias;

  const StepByStepProceduresFaq({
    super.key,
    required this.guias,
  });

  // Renderiza la lista de preguntas frecuentes con sus pasos y edificio responsable
  @override
  Widget build(BuildContext context) {
    if (guias.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'GUIA PASO A PASO DE TRAMITES ESCOLARES FRECUENTES (FAQ)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color:
                    isDark ? AppColors.footerAccentBlue : AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Resuelve dudas comunes sobre inasistencias medicas, cupos en E-SIIMA, constancias y creditos humanisticos:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            ...guias.map((GuiaTramiteFaqUaa item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceMuted
                        : AppColors.lightSurfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.pregunta,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Area donde se atiende: ${item.edificioResponsable}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.footerAccentBlue
                              : AppColors.secondaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...item.pasos.map((String paso) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            paso,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryTextColor,
                              height: 1.35,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
