import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Modelo interno para definir cada servicio universitario de acceso directo
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

// Columna de accesos directos estilo Publicaciones/Servicios del portal UAA
class QuickAccessGrid extends StatelessWidget {
  final ValueChanged<String> onSelectModule;

  const QuickAccessGrid({
    super.key,
    required this.onSelectModule,
  });

  static const List<QuickAccessItem> _modulos = <QuickAccessItem>[
    QuickAccessItem(
      titulo: 'Aula Virtual - Entrega de Tareas',
      subtitulo: 'Envio de actividades y proyectos por asignatura',
      accionTexto: 'Entrar al Aula Virtual ->',
      icono: Icons.assignment_turned_in_outlined,
      colorAcento: AppColors.primaryNavy,
    ),
    QuickAccessItem(
      titulo: 'E-SIIMA - Inscripcion de Materias',
      subtitulo: 'Seleccion de grupos y horarios del semestre 2026-2',
      accionTexto: 'Realizar inscripcion ->',
      icono: Icons.how_to_reg_outlined,
      colorAcento: AppColors.secondaryBlue,
    ),
    QuickAccessItem(
      titulo: 'Kardex y Calificaciones Parciales',
      subtitulo: 'Consulta de notas y retroalimentacion de profesores',
      accionTexto: 'Consultar calificaciones ->',
      icono: Icons.school_outlined,
      colorAcento: AppColors.statusActive,
    ),
    QuickAccessItem(
      titulo: 'Ventanilla de Pagos de Colegiatura',
      subtitulo: 'Pago en linea y recibos oficiales por referencia',
      accionTexto: 'Pagar colegiatura ->',
      icono: Icons.account_balance_wallet_outlined,
      colorAcento: AppColors.accentCrimson,
    ),
  ];

  // Construye las tarjetas horizontales limpias con boton inferior de acceso general
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
        ..._modulos.map((QuickAccessItem item) {
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
          onPressed: () => onSelectModule('Todos los Servicios E-SIIMA'),
          child: const Text(
            'TODOS LOS SERVICIOS DIGITALES',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
