import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/portal_models.dart';
import 'hover_animated_card.dart';

// Seccion de directorio de servicios fisicos y digitales del campus con tarjetas animadas
class CampusServicesSection extends StatelessWidget {
  final List<ServicioCampusUaa> servicios;
  final ValueChanged<String> onSelectService;

  const CampusServicesSection({
    super.key,
    required this.servicios,
    required this.onSelectService,
  });

  // Construye la cuadricula responsiva de servicios universitarios
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxW = constraints.maxWidth;
        final int cols = maxW >= 1020 ? 3 : (maxW >= 640 ? 2 : 1);
        const double spacing = 16;
        final double itemW = (maxW - (spacing * (cols - 1))) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: servicios.map((ServicioCampusUaa servicio) {
            return SizedBox(
              width: itemW,
              child: _buildServiceCard(
                theme,
                servicio,
                isDark,
                secondaryTextColor,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Construye una tarjeta individual animada con ubicacion, horario y telefono del servicio
  Widget _buildServiceCard(
    ThemeData theme,
    ServicioCampusUaa servicio,
    bool isDark,
    Color secondaryTextColor,
  ) {
    final String etiquetaCampus =
        servicio.idCampus == 1 ? 'Campus Central' : 'Campus Sur';

    return HoverAnimatedCard(
      padding: const EdgeInsets.all(18),
      onTap: () => onSelectService(servicio.nombre),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  servicio.icono,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              Wrap(
                spacing: 6,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      etiquetaCampus,
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
                      color: AppColors.statusActive,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      servicio.estadoActual,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            servicio.nombre,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            servicio.descripcion,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryTextColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.place_outlined,
                size: 16,
                color: isDark
                    ? AppColors.footerAccentBlue
                    : AppColors.secondaryBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  servicio.ubicacion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.access_time_outlined,
                size: 16,
                color: isDark
                    ? AppColors.footerAccentBlue
                    : AppColors.secondaryBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  servicio.horario,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.phone_outlined,
                size: 16,
                color: isDark
                    ? AppColors.footerAccentBlue
                    : AppColors.secondaryBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  servicio.telefonoExtension,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
