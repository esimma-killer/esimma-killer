import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/portal_models.dart';
import 'hover_animated_card.dart';

// Panel de herramientas rapidas con tarjetas animadas al pasar el cursor o tocar
class ProfileQuickSwitcher extends StatelessWidget {
  final SesionUsuarioUaa sesionActiva;
  final int idCampusSeleccionado;
  final ValueChanged<int> onCampusChanged;
  final List<AccionPerfilUaa> acciones;
  final ValueChanged<String> onAccionPressed;

  const ProfileQuickSwitcher({
    super.key,
    required this.sesionActiva,
    required this.idCampusSeleccionado,
    required this.onCampusChanged,
    required this.acciones,
    required this.onAccionPressed,
  });

  // Construye las herramientas correspondientes al usuario logueado y selector limpio de campus
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bool esProfesor = sesionActiva.esProfesor;

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
                      esProfesor
                          ? 'HERRAMIENTAS RAPIDAS PARA DOCENTES UAA'
                          : 'HERRAMIENTAS RAPIDAS PARA ALUMNOS UAA',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.footerAccentBlue
                            : AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      esProfesor
                          ? 'Operaciones directas de E-SIIMA y Aula Virtual para tus grupos activos:'
                          : 'Operaciones directas de E-SIIMA y Aula Virtual para tu semestre actual:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('Campus Central'),
                      selected: idCampusSeleccionado == 1,
                      onSelected: (_) => onCampusChanged(1),
                    ),
                    ChoiceChip(
                      label: const Text('Campus Sur'),
                      selected: idCampusSeleccionado == 2,
                      onSelected: (_) => onCampusChanged(2),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              child: LayoutBuilder(
                key: ValueKey<String>(
                  '${sesionActiva.identificador}_$idCampusSeleccionado',
                ),
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double maxW = constraints.maxWidth;
                  final int cols = maxW >= 1150
                      ? 5
                      : (maxW >= 720 ? 3 : (maxW >= 460 ? 2 : 1));
                  const double spacing = 12;
                  final double cardW = (maxW - (spacing * (cols - 1))) / cols;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: acciones.map((AccionPerfilUaa item) {
                      return SizedBox(
                        width: cardW,
                        child: _buildActionCard(
                          context,
                          item,
                          esProfesor,
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
        ),
      ),
    );
  }

  // Construye cada tarjeta de accion rapida con animacion hover y tactil
  Widget _buildActionCard(
    BuildContext context,
    AccionPerfilUaa item,
    bool esProfesor,
    bool isDark,
    Color secondaryTextColor,
  ) {
    final ThemeData theme = Theme.of(context);
    final Color accentColor =
        esProfesor ? AppColors.accentCrimson : AppColors.secondaryBlue;

    return HoverAnimatedCard(
      padding: const EdgeInsets.all(14),
      backgroundColor:
          isDark ? AppColors.darkSurfaceMuted : AppColors.lightSurfaceMuted,
      activeBorderColor: accentColor,
      onTap: () => onAccionPressed(item.titulo),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  item.icono,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.etiquetaModulo,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.footerAccentBlue
                        : AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.titulo,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.descripcion,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryTextColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
