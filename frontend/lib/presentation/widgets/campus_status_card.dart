import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/campus_info.dart';

// Widget plano que muestra la tarjeta de estado de un campus universitario
class CampusStatusCard extends StatelessWidget {
  final CampusInfo campus;

  const CampusStatusCard({
    super.key,
    required this.campus,
  });

  // Construye la interfaz visual plana de la tarjeta del campus
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    campus.nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: campus.activo
                        ? AppColors.statusActive
                        : AppColors.statusWarning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    campus.activo ? 'Operativo' : 'Mantenimiento',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ID de Fragmentacion (Shard Key): ${campus.idCampus}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ubicacion: ${campus.ubicacion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nodo: ${campus.nodoBaseDatos}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
