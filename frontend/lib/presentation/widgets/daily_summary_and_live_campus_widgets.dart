import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/portal_models.dart';

// Panel condicional "Tu Resumen de Hoy": oculta cualquier tarjeta o seccion cuyo valor sea null
class DailySummaryBanner extends StatelessWidget {
  final SesionUsuarioUaa sesion;
  final ValueChanged<String> onItemTap;

  const DailySummaryBanner({
    super.key,
    required this.sesion,
    required this.onItemTap,
  });

  // Renderiza unicamente las tarjetas cuyos datos existen; si todo es null devuelve SizedBox.shrink
  @override
  Widget build(BuildContext context) {
    final ResumenDiarioUaa? resumen = sesion.resumenDiario;
    if (resumen == null || !resumen.tieneElementosActivos) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final List<Widget> tarjetasActivas = <Widget>[];

    if (resumen.proximaClaseGrupo != null) {
      tarjetasActivas.add(
        _buildSummaryCard(
          theme: theme,
          isDark: isDark,
          secondaryTextColor: secondaryTextColor,
          etiqueta: sesion.esProfesor
              ? 'PROXIMO GRUPO A IMPARTIR HOY'
              : 'PROXIMA CLASE DE HOY',
          titulo: resumen.proximaClaseGrupo!,
          detalle: resumen.detalleProximaClase ?? '',
          icono: Icons.schedule_outlined,
          colorAcento: AppColors.primaryNavy,
          onTap: () => onItemTap(resumen.proximaClaseGrupo!),
        ),
      );
    }

    if (resumen.tareaEntregaPendiente != null) {
      tarjetasActivas.add(
        _buildSummaryCard(
          theme: theme,
          isDark: isDark,
          secondaryTextColor: secondaryTextColor,
          etiqueta: sesion.esProfesor
              ? 'ENTREGAS RECIBIDAS POR CALIFICAR'
              : 'ENTREGA PENDIENTE EN AULA VIRTUAL',
          titulo: resumen.tareaEntregaPendiente!,
          detalle: resumen.detalleTareaPendiente ?? '',
          icono: Icons.assignment_late_outlined,
          colorAcento: AppColors.secondaryBlue,
          onTap: () => onItemTap(resumen.tareaEntregaPendiente!),
        ),
      );
    }

    // Solo se muestra si realmente existe un adeudo pendiente (cuando es null no se renderiza nada)
    if (resumen.adeudoPendiente != null) {
      tarjetasActivas.add(
        _buildSummaryCard(
          theme: theme,
          isDark: isDark,
          secondaryTextColor: secondaryTextColor,
          etiqueta: 'ADEUDO PENDIENTE EN CAJAS / FINANZAS',
          titulo: resumen.adeudoPendiente!,
          detalle: resumen.detalleAdeudo ?? '',
          icono: Icons.warning_amber_outlined,
          colorAcento: AppColors.accentCrimson,
          onTap: () => onItemTap(resumen.adeudoPendiente!),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'TU RESUMEN DE HOY EN LA UAA',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.footerAccentBlue
                      : AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double maxW = constraints.maxWidth;
                  final int count = tarjetasActivas.length;
                  final int cols =
                      maxW >= 960 ? count : (maxW >= 620 ? (count > 1 ? 2 : 1) : 1);
                  const double spacing = 14;
                  final double itemW = (maxW - (spacing * (cols - 1))) / cols;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: tarjetasActivas.map((Widget card) {
                      return SizedBox(width: itemW, child: card);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construye una tarjeta individual de aviso activo del resumen diario
  Widget _buildSummaryCard({
    required ThemeData theme,
    required bool isDark,
    required Color secondaryTextColor,
    required String etiqueta,
    required String titulo,
    required String detalle,
    required IconData icono,
    required Color colorAcento,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.darkSurfaceMuted : AppColors.lightSurfaceMuted,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorAcento,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorAcento,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icono, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      etiqueta,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.footerAccentBlue : colorAcento,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      titulo,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (detalle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Seccion para la Pagina Principal: Disponibilidad en vivo de laboratorios y Comedor Universitario
class LiveCampusOccupancyAndDiningSection extends StatelessWidget {
  final List<EspacioDisponibleUaa> espacios;
  final List<MenuComedorUaa> menusComedor;
  final ValueChanged<String> onTapAction;

  const LiveCampusOccupancyAndDiningSection({
    super.key,
    required this.espacios,
    required this.menusComedor,
    required this.onTapAction,
  });

  // Renderiza la disponibilidad de laboratorios/cubiculos y el menu del comedor si existen datos
  @override
  Widget build(BuildContext context) {
    if (espacios.isEmpty && menusComedor.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 940;

    final Widget bloqueEspacios = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.computer_outlined,
                  size: 20,
                  color: isDark
                      ? AppColors.footerAccentBlue
                      : AppColors.primaryNavy,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DISPONIBILIDAD EN TIEMPO REAL DE SALAS Y LABORATORIOS',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.footerAccentBlue
                          : AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...espacios.map((EspacioDisponibleUaa esp) {
              final double porcentajeLibre =
                  (esp.lugaresLibres / esp.capacidadTotal).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      children: <Widget>[
                        Text(
                          esp.nombreEspacio,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${esp.lugaresLibres} libres de ${esp.capacidadTotal}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.footerAccentBlue
                                : AppColors.statusActive,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      esp.ubicacion,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: porcentajeLibre,
                        minHeight: 7,
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceMuted
                            : AppColors.lightSurfaceMuted,
                        color: AppColors.statusActive,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );

    final Widget bloqueComedor = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.restaurant_outlined,
                  size: 20,
                  color: isDark
                      ? AppColors.footerAccentBlue
                      : AppColors.primaryNavy,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MENU DEL DIA EN COMEDORES UNIVERSITARIOS UAA',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.footerAccentBlue
                          : AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...menusComedor.map((MenuComedorUaa menu) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 4,
                        children: <Widget>[
                          Text(
                            menu.nombreComedor,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              menu.horario,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Platillo: ${menu.platilloPrincipal}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Incluye: ${menu.guarnicionBebida}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          bloqueEspacios,
          const SizedBox(height: 16),
          bloqueComedor,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: 6, child: bloqueEspacios),
        const SizedBox(width: 24),
        Expanded(flex: 5, child: bloqueComedor),
      ],
    );
  }
}

// Seccion para la Pagina Principal: Convocatorias Abiertas del Mes con Contador de Dias
class OpenCallsSection extends StatelessWidget {
  final List<ConvocatoriaUaa> convocatorias;
  final ValueChanged<String> onSelectCall;

  const OpenCallsSection({
    super.key,
    required this.convocatorias,
    required this.onSelectCall,
  });

  // Renderiza la cuadricula de convocatorias vigentes si la lista no esta vacia
  @override
  Widget build(BuildContext context) {
    if (convocatorias.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxW = constraints.maxWidth;
        final int cols = maxW >= 1100 ? 4 : (maxW >= 620 ? 2 : 1);
        const double spacing = 14;
        final double itemW = (maxW - (spacing * (cols - 1))) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: convocatorias.map((ConvocatoriaUaa conv) {
            return SizedBox(
              width: itemW,
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => onSelectCall(conv.titulo),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: conv.urgente
                                    ? AppColors.accentCrimson
                                    : AppColors.secondaryBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                conv.diasRestantesTexto,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              conv.dirigidoA,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          conv.titulo,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          conv.descripcion,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Consultar bases en E-SIIMA ->',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.footerAccentBlue
                                : AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
