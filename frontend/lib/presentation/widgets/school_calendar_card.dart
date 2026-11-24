import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/evento_calendario.dart';
import 'hover_animated_card.dart';

// Columna de eventos y calendario con tarjetas de fecha estilo UAA animadas
class SchoolCalendarCard extends StatelessWidget {
  final List<EventoCalendario> eventos;
  final VoidCallback? onVerCalendarioCompleto;

  const SchoolCalendarCard({
    super.key,
    required this.eventos,
    this.onVerCalendarioCompleto,
  });

  // Construye la lista de tarjetas de eventos con bloque de mes y dia a la izquierda
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final Color cardBgColor =
        isDark ? AppColors.darkSurfaceMuted : AppColors.lightSurfaceMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ...eventos.map((EventoCalendario item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HoverAnimatedCard(
              padding: const EdgeInsets.all(14),
              backgroundColor: cardBgColor,
              onTap: onVerCalendarioCompleto,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _buildDateBadge(item.mesAbreviado, item.diaNumero),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.evento,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.ubicacion,
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
        }),
        const SizedBox(height: 4),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentCrimson,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: onVerCalendarioCompleto,
          child: const Text(
            'CALENDARIO ESCOLAR 2026-2',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // Construye el recuadro de fecha estilo UAA (cabecera azul con mes y numero debajo)
  Widget _buildDateBadge(String mes, String dia) {
    return Container(
      width: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: const BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Text(
              mes,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              dia,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
