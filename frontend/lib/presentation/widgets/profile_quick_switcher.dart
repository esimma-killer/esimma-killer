import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/portal_models.dart';

// Conmutador rapido por perfil (Soy Alumno / Soy Profesor) con herramientas diarias
class ProfileQuickSwitcher extends StatelessWidget {
  final bool esProfesor;
  final ValueChanged<bool> onProfileChanged;
  final int? idCampusSeleccionado;
  final ValueChanged<int?> onCampusChanged;
  final List<AccionPerfilUaa> acciones;
  final ValueChanged<String> onAccionPressed;

  const ProfileQuickSwitcher({
    super.key,
    required this.esProfesor,
    required this.onProfileChanged,
    required this.idCampusSeleccionado,
    required this.onCampusChanged,
    required this.acciones,
    required this.onAccionPressed,
  });

  // Construye el panel interactivo de herramientas rapidas por rol y campus
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
                      'HERRAMIENTAS RAPIDAS PARA COMUNIDAD UAA',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.footerAccentBlue
                            : AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona tu perfil y tu campus para mostrar los accesos que utilizas a diario:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    // Selector de perfil Alumno vs Profesor
                    Container(
                      padding: const EdgeInsets.all(3),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _buildRoleTabButton(
                            label: 'Soy Alumno',
                            icon: Icons.school_outlined,
                            selected: !esProfesor,
                            onTap: () => onProfileChanged(false),
                          ),
                          const SizedBox(width: 4),
                          _buildRoleTabButton(
                            label: 'Soy Profesor',
                            icon: Icons.co_present_outlined,
                            selected: esProfesor,
                            onTap: () => onProfileChanged(true),
                          ),
                        ],
                      ),
                    ),
                    // Selector de filtro por campus
                    Wrap(
                      spacing: 6,
                      children: <Widget>[
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: idCampusSeleccionado == null,
                          onSelected: (_) => onCampusChanged(null),
                        ),
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
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double maxW = constraints.maxWidth;
                final int cols =
                    maxW >= 1150 ? 5 : (maxW >= 720 ? 3 : (maxW >= 460 ? 2 : 1));
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
                        isDark,
                        secondaryTextColor,
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

  // Construye una pestana del selector Soy Alumno / Soy Profesor
  Widget _buildRoleTabButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primaryNavy : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.slateBlue,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.slateBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construye cada tarjeta de accion rapida para el rol activo
  Widget _buildActionCard(
    BuildContext context,
    AccionPerfilUaa item,
    bool isDark,
    Color secondaryTextColor,
  ) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: isDark ? AppColors.darkSurfaceMuted : AppColors.lightSurfaceMuted,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onAccionPressed(item.titulo),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: esProfesor
                          ? AppColors.accentCrimson
                          : AppColors.secondaryBlue,
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
                      color: isDark
                          ? AppColors.darkBackground
                          : Colors.white,
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
        ),
      ),
    );
  }
}
