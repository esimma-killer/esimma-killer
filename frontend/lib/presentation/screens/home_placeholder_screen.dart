import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/campus_repository.dart';
import '../../domain/entities/campus_info.dart';
import '../widgets/campus_status_card.dart';

// Pantalla inicial base que presenta el estado de la arquitectura modular
class HomePlaceholderScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final CampusRepository repository;

  const HomePlaceholderScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.repository = const CampusRepository(),
  });

  // Construye la vista responsiva adaptable a movil, web y escritorio
  @override
  Widget build(BuildContext context) {
    final List<CampusInfo> listaCampus = repository.obtenerCampusDisponibles();
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Image.asset(
                AppConstants.faviconUaaAsset,
                height: 26,
                width: 26,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text(AppConstants.appName),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: isDarkMode ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
            onPressed: onToggleTheme,
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildHeaderSection(theme, secondaryTextColor),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    'Nodos de Campus Configurados',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estructura preparada para enrutamiento por Shard Key e integracion con API REST.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildResponsiveCampusList(listaCampus),
                  const SizedBox(height: 24),
                  _buildArchitectureSummaryCard(theme, secondaryTextColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Construye el encabezado institucional con el logotipo oficial y datos del sistema
  Widget _buildHeaderSection(ThemeData theme, Color secondaryTextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Image.asset(
            AppConstants.logoUaaAsset,
            height: 64,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppConstants.institutionName,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.secondaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.appSubtitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Base de codigo unificada (Single Codebase) para Web, Movil y Escritorio.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Organiza las tarjetas de campus en fila o columna segun el ancho disponible
  Widget _buildResponsiveCampusList(List<CampusInfo> listaCampus) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 640;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listaCampus
                .map(
                  (CampusInfo campus) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: campus == listaCampus.last ? 0 : 16,
                      ),
                      child: CampusStatusCard(campus: campus),
                    ),
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: listaCampus
              .map(
                (CampusInfo campus) => Padding(
                  padding: EdgeInsets.only(
                    bottom: campus == listaCampus.last ? 0 : 12,
                  ),
                  child: CampusStatusCard(campus: campus),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // Construye una tarjeta informativa con las capas modulares inicializadas
  Widget _buildArchitectureSummaryCard(
    ThemeData theme,
    Color secondaryTextColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Estado de la Arquitectura Cliente (Entrega 2)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capas activas: core (constantes y temas), domain (entidades), data (repositorios) y presentation (pantallas y widgets).',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Endpoint objetivo configurado: ${AppConstants.apiBaseUrl}',
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
