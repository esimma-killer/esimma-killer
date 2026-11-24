import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/portal_repository.dart';
import '../../domain/entities/aviso_institucional.dart';
import '../../domain/entities/evento_calendario.dart';
import '../widgets/notices_carousel.dart';
import '../widgets/quick_access_grid.dart';
import '../widgets/school_calendar_card.dart';

// Pantalla principal publica (Landing Page) de la Universidad Autonoma de Aguascalientes
class LandingPageScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final PortalRepository repository;

  const LandingPageScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.repository = const PortalRepository(),
  });

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  // Filtro de campus: null = Todos, 1 = Campus Central, 2 = Campus Sur
  int? _idCampusSeleccionado;

  // Cambia el filtro de campus activo para actualizar las noticias y el carrusel
  void _cambiarFiltroCampus(int? nuevoCampus) {
    setState(() {
      _idCampusSeleccionado = nuevoCampus;
    });
  }

  // Muestra notificacion clara indicando la conexion con el Login del Issue #22
  void _mostrarAvisoAcceso(String destino) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Modulo "$destino": Redirigira al Login Unificado (Issue #22).',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Construye la pagina completa adaptada a diferentes resoluciones de pantalla
  @override
  Widget build(BuildContext context) {
    final List<AvisoInstitucional> avisosFiltrados = widget.repository
        .obtenerAvisos(idCampusFiltro: _idCampusSeleccionado);
    final List<EventoCalendario> calendario =
        widget.repository.obtenerCalendarioEscolar();

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;
    final bool isTablet = screenWidth >= 700 && screenWidth < 1080;
    final double horizontalPadding =
        isMobile ? 16 : (screenWidth * 0.035).clamp(24.0, 56.0);

    return Scaffold(
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!isMobile) _buildTopUtilityStrip(isDark, horizontalPadding),
              _buildBrandHeaderBar(
                context,
                screenWidth,
                isMobile,
                isDark,
                horizontalPadding,
              ),
              _buildNavyNavigationBar(isMobile, horizontalPadding),
              // Carrusel hero fotografico a todo lo ancho del banner
              NoticesCarousel(
                avisos: avisosFiltrados,
                onActionPressed: _mostrarAvisoAcceso,
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1520),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isMobile ? 20 : 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildWelcomeAndCampusFilterBar(
                          theme,
                          secondaryTextColor,
                          isDark,
                        ),
                        const SizedBox(height: 28),
                        _buildThreeColumnPortalSection(
                          theme,
                          secondaryTextColor,
                          isDark,
                          isMobile,
                          isTablet,
                          avisosFiltrados,
                          calendario,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildOfficialUaaFooter(isMobile, horizontalPadding),
            ],
          ),
        ),
      ),
    );
  }

  // Cintillo superior discreto con enlaces institucionales
  Widget _buildTopUtilityStrip(bool isDark, double horizontalPadding) {
    final List<String> enlacesSuperiores = <String>[
      'Eventos y Convocatorias',
      'Biblioteca Digital',
      'Calendarios',
      'Directorio Universitario',
      'Correo Institucional',
    ];

    return Container(
      color: isDark ? AppColors.darkSurfaceMuted : AppColors.topStripBackground,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1520),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 18,
            runSpacing: 4,
            children: enlacesSuperiores.map((String texto) {
              return InkWell(
                onTap: () => _mostrarAvisoAcceso(texto),
                child: Text(
                  texto,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.primaryNavy,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Header con el logo grande y transparente en la esquina izquierda y accesos en la esquina derecha opuesta
  Widget _buildBrandHeaderBar(
    BuildContext context,
    double screenWidth,
    bool isMobile,
    bool isDark,
    double horizontalPadding,
  ) {
    final double logoHeight =
        isMobile ? 54 : (screenWidth >= 1280 ? 80 : 68);
    final String logoAsset = isDark
        ? AppConstants.logoUaaDarkAsset
        : AppConstants.logoUaaLightAsset;

    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isMobile ? 10 : 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1520),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Esquina izquierda: Logo oficial UAA sin fondo blanco y escalado por resolucion
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (isMobile)
                      Builder(
                        builder: (BuildContext ctx) => IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: 'Abrir menu',
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                    Flexible(
                      child: Image.asset(
                        logoAsset,
                        height: logoHeight,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Esquina derecha opuesta: Botones compactos E-SIIMA, Aula Virtual e icono de tema
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: 10,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => _mostrarAvisoAcceso('E-SIIMA'),
                    child: Text(
                      'E-SIIMA',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentCrimson,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: 10,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => _mostrarAvisoAcceso('Aula Virtual'),
                    child: Text(
                      isMobile ? 'AULA' : 'AULA VIRTUAL',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: widget.isDarkMode
                        ? 'Cambiar a modo claro'
                        : 'Cambiar a modo oscuro',
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceMuted
                          : AppColors.lightSurfaceMuted,
                    ),
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                      widget.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      size: 20,
                      color: isDark
                          ? AppColors.footerAccentBlue
                          : AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Barra azul marino con las secciones principales de la universidad
  Widget _buildNavyNavigationBar(bool isMobile, double horizontalPadding) {
    final List<String> categorias = <String>[
      'UNIVERSIDAD',
      'OFERTA EDUCATIVA',
      'ASPIRANTES',
      'ALUMNOS',
      'DOCENTES',
      'SERVICIOS Y VINCULACION',
    ];

    return Container(
      color: AppColors.primaryNavy,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 10,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1520),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: isMobile ? 12 : 28,
            runSpacing: 8,
            children: categorias.map((String cat) {
              return InkWell(
                onTap: () => _mostrarAvisoAcceso(cat),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    cat,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Menu lateral para pantallas moviles
  Widget _buildMobileDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.primaryNavy,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    AppConstants.institutionName,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Todos los Campus'),
              selected: _idCampusSeleccionado == null,
              onTap: () {
                _cambiarFiltroCampus(null);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('Campus Central'),
              selected: _idCampusSeleccionado == 1,
              onTap: () {
                _cambiarFiltroCampus(1);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.domain),
              title: const Text('Campus Sur'),
              selected: _idCampusSeleccionado == 2,
              onTap: () {
                _cambiarFiltroCampus(2);
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Ingresar a E-SIIMA'),
              onTap: () {
                Navigator.of(context).pop();
                _mostrarAvisoAcceso('E-SIIMA');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Barra de bienvenida concisa con filtro rapido por campus
  Widget _buildWelcomeAndCampusFilterBar(
    ThemeData theme,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          runSpacing: 12,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'BIENVENIDO A LA UAA',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.footerAccentBlue
                          : AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consulta noticias universitarias, fechas clave del semestre y accede directamente a tus tramites de E-SIIMA y Aula Virtual.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Todos los Campus'),
                  selected: _idCampusSeleccionado == null,
                  onSelected: (_) => _cambiarFiltroCampus(null),
                ),
                ChoiceChip(
                  label: const Text('Campus Central'),
                  selected: _idCampusSeleccionado == 1,
                  onSelected: (_) => _cambiarFiltroCampus(1),
                ),
                ChoiceChip(
                  label: const Text('Campus Sur'),
                  selected: _idCampusSeleccionado == 2,
                  onSelected: (_) => _cambiarFiltroCampus(2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Seccion central de 3 columnas: Noticias (con foto) | Eventos | Servicios Frecuentes
  Widget _buildThreeColumnPortalSection(
    ThemeData theme,
    Color secondaryTextColor,
    bool isDark,
    bool isMobile,
    bool isTablet,
    List<AvisoInstitucional> avisos,
    List<EventoCalendario> calendario,
  ) {
    final Widget columnaNoticias = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionHeading('NOTICIAS Y AVISOS'),
        const SizedBox(height: 16),
        ...avisos.take(2).map((AvisoInstitucional aviso) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildNewsCard(theme, secondaryTextColor, isDark, aviso),
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
          onPressed: () => _mostrarAvisoAcceso('Todas las Noticias UAA'),
          child: const Text(
            'TODAS LAS NOTICIAS',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );

    final Widget columnaEventos = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionHeading('EVENTOS Y FECHAS'),
        const SizedBox(height: 16),
        SchoolCalendarCard(
          eventos: calendario,
          onVerCalendarioCompleto: () =>
              _mostrarAvisoAcceso('Calendario Escolar 2026-2'),
        ),
      ],
    );

    final Widget columnaAccesos = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionHeading('SERVICIOS FRECUENTES'),
        const SizedBox(height: 16),
        QuickAccessGrid(onSelectModule: _mostrarAvisoAcceso),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          columnaAccesos,
          const SizedBox(height: 28),
          columnaEventos,
          const SizedBox(height: 28),
          columnaNoticias,
        ],
      );
    }

    if (isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: columnaNoticias),
              const SizedBox(width: 20),
              Expanded(child: columnaEventos),
            ],
          ),
          const SizedBox(height: 28),
          columnaAccesos,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: columnaNoticias),
        const SizedBox(width: 24),
        Expanded(child: columnaEventos),
        const SizedBox(width: 24),
        Expanded(child: columnaAccesos),
      ],
    );
  }

  // Titulo de columna centrado con subrayado institucional guinda UAA
  Widget _buildSectionHeading(String titulo) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: <Widget>[
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? AppColors.darkTextPrimary : AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 72,
          height: 3,
          color: AppColors.accentCrimson,
        ),
      ],
    );
  }

  // Tarjeta de noticia con miniatura fotografica estilo portal oficial UAA
  Widget _buildNewsCard(
    ThemeData theme,
    Color secondaryTextColor,
    bool isDark,
    AvisoInstitucional aviso,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 132,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  aviso.imagenAsset,
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${aviso.idAviso} - ${aviso.nombreCampus}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  aviso.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  aviso.resumen,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pie de pagina oficial UAA con logotipo transparente y lema Se Lumen Proferre
  Widget _buildOfficialUaaFooter(bool isMobile, double horizontalPadding) {
    return Container(
      color: AppColors.darkNavyFooter,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: 48,
                runSpacing: 24,
                alignment: WrapAlignment.spaceBetween,
                children: <Widget>[
                  _buildFooterColumn(
                    titulo: 'Enlaces de interes',
                    enlaces: const <String>[
                      'Portal E-SIIMA Alumnos y Docentes',
                      'Aula Virtual Educacion Superior',
                      'Calendario Academico 2026-2',
                      'Biblioteca Digital y Repositorio',
                      'Codigo de Etica y Conducta UAA',
                    ],
                  ),
                  _buildFooterColumn(
                    titulo: 'Enlaces de transparencia',
                    enlaces: const <String>[
                      'Plataforma Nacional de Transparencia',
                      'Obligaciones de Transparencia (LGT)',
                      'Aviso de Privacidad Integral (LFPDPPP)',
                      'Defensoria de los Derechos Universitarios',
                      'Sistema de Gestion Integral',
                    ],
                  ),
                  _buildFooterColumn(
                    titulo: 'Servicios y contacto',
                    enlaces: const <String>[
                      'Campus Central (Ciudad Universitaria)',
                      'Campus Sur (Blvd. Jose Maria Chavez)',
                      'Directorio Telefonico Universitario',
                      'Buzon de Quejas y Sugerencias',
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 16,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Image.asset(
                        AppConstants.faviconUaaAsset,
                        height: 38,
                        width: 38,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'UNIVERSIDAD AUTONOMA DE AGUASCALIENTES',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Se Lumen Proferre',
                            style: TextStyle(
                              color: AppColors.footerAccentBlue,
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Av. Universidad #940, Ciudad Universitaria, C.P. 20100, Aguascalientes, Ags. Mexico.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tel. conmutador: 449 910 74 00 | Buzon de quejas y sugerencias',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construye una columna de enlaces para el pie de pagina azul marino
  Widget _buildFooterColumn({
    required String titulo,
    required List<String> enlaces,
  }) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            titulo,
            style: const TextStyle(
              color: AppColors.footerAccentBlue,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...enlaces.map((String enlace) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _mostrarAvisoAcceso(enlace),
                child: Text(
                  enlace,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
