import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Modelo interno para recursos academicos y plataformas universitarias (3ra columna)
class QuickAccessItem {
  final String titulo;
  final String subtitulo;
  final String accionTexto;
  final IconData icono;
  final Color colorAcento;

  const QuickAccessItem({
    required this.titulo,
    required this.subtitulo,
    required this.accionTexto,
    required this.icono,
    required this.colorAcento,
  });
}

// Tercera columna: Recursos Academicos y Biblioteca Digital (sin repetir Herramientas Rapidas)
class QuickAccessGrid extends StatelessWidget {
  final ValueChanged<String> onSelectModule;

  const QuickAccessGrid({
    super.key,
    required this.onSelectModule,
  });

  static const List<QuickAccessItem> _recursos = <QuickAccessItem>[
    QuickAccessItem(
      titulo: 'Biblioteca Digital y Bases Cientificas',
      subtitulo: 'Acceso remoto a IEEE Xplore, Scopus, Springer y eLibro UAA',
      accionTexto: 'Consultar acervo digital ->',
      icono: Icons.menu_book_outlined,
      colorAcento: AppColors.primaryNavy,
    ),
    QuickAccessItem(
      titulo: 'Software Institucional y Licencias',
      subtitulo: 'Descarga gratuita de Office 365, MATLAB, AutoCAD y JetBrains',
      accionTexto: 'Obtener licencias ->',
      icono: Icons.developer_board_outlined,
      colorAcento: AppColors.secondaryBlue,
    ),
    QuickAccessItem(
      titulo: 'Repositorio de Tesis y Revistas UAA',
      subtitulo: 'Proyectos integradores, articulos y Gaceta Universitaria',
      accionTexto: 'Explorar publicaciones ->',
      icono: Icons.library_books_outlined,
      colorAcento: AppColors.statusActive,
    ),
    QuickAccessItem(
      titulo: 'Apoyo Psicologico y Tutoria de Pares',
      subtitulo: 'Asesoria academica en materias de ciencias e ingenieria',
      accionTexto: 'Solicitar asesoria ->',
      icono: Icons.support_agent_outlined,
      colorAcento: AppColors.accentCrimson,
    ),
  ];

  // Construye las tarjetas horizontales de recursos academicos
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
        ..._recursos.map((QuickAccessItem item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelectModule(item.titulo),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: item.colorAcento,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          item.icono,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.titulo,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.subtitulo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.accionTexto,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.footerAccentBlue
                                    : AppColors.secondaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
          onPressed: () =>
              onSelectModule('Catalogo Completo de Recursos Academicos UAA'),
          child: const Text(
            'TODOS LOS RECURSOS ACADEMICOS',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
