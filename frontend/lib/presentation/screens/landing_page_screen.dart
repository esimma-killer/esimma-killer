import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/portal_repository.dart';
import '../../domain/entities/aviso_institucional.dart';
import '../../domain/entities/evento_calendario.dart';
import '../../domain/entities/portal_models.dart';
import '../widgets/campus_services_section.dart';
import '../widgets/interactive_campus_map_section.dart';
import '../widgets/notices_carousel.dart';
import '../widgets/profile_quick_switcher.dart';
import '../widgets/quick_access_grid.dart';
import '../widgets/school_calendar_card.dart';
import '../widgets/university_activities_section.dart';

// Pantalla principal publica (Landing Page) disenada como herramienta para alumnos y profesores UAA
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

  // Perfil activo en el conmutador rapido: false = Alumno, true = Profesor
  bool _esPerfilProfesor = false;

  // Llaves globales para navegacion fluida con scroll automatico entre secciones
  final GlobalKey _keyInicio = GlobalKey();
  final GlobalKey _keyPerfil = GlobalKey();
  final GlobalKey _keyNoticiasEventos = GlobalKey();
  final GlobalKey _keyServicios = GlobalKey();
  final GlobalKey _keyActividades = GlobalKey();
  final GlobalKey _keyMapa = GlobalKey();

  // Cambia el filtro de campus activo para actualizar las secciones de la pagina
  void _cambiarFiltroCampus(int? nuevoCampus) {
    setState(() {
      _idCampusSeleccionado = nuevoCampus;
    });
  }

  // Cambia el perfil entre Soy Alumno y Soy Profesor
  void _cambiarPerfil(bool esProfesor) {
    setState(() {
      _esPerfilProfesor = esProfesor;
    });
  }

  // Desplaza suavemente la vista hacia la seccion seleccionada en el menu azul
  void _desplazarASeccion(GlobalKey sectionKey) {
    final BuildContext? targetContext = sectionKey.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
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

  // Abre un buscador rapido para encontrar edificios, servicios o tramites de la UAA
  void _abrirBuscadorInstitucional() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        String filtro = '';
        final List<String> catalogoBusqueda = <String>[
          'Edificio 1-A - Cajas y Control Escolar (Campus Central)',
          'Edificio 56 - Biblioteca Central Dr. Desiderio Macias Silva',
          'Edificio 60 - Laboratorios de Computo y Ciencias Basicas',
          'Edificio 101 - Unidad Medico Didactica (UMD)',
          'Edificio 211 - CAADI e Idiomas / Poliforum',
          'Campus Sur - Edificio B Laboratorios de Ingenieria',
          'Tramite: Inscripcion y Reinscripcion de Materias E-SIIMA',
          'Tramite: Entrega de Tareas en Aula Virtual',
          'Tramite: Pago de Colegiatura en Linea',
          'Actividad: Conferencia Creditos Humanisticos (Auditorio Pedro de Alba)',
        ];

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<String> resultados = catalogoBusqueda
                .where(
                  (String item) =>
                      item.toLowerCase().contains(filtro.toLowerCase()),
                )
                .toList();

            return AlertDialog(
              title: const Text('Buscador Rapido para Comunidad UAA'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText:
                            'Escribe un edificio, laboratorio, servicio o tramite...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String valor) {
                        setModalState(() {
                          filtro = valor;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: resultados.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final String item = resultados[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.arrow_right),
                            title: Text(item),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              if (item.startsWith('Edificio') ||
                                  item.startsWith('Campus Sur')) {
                                _desplazarASeccion(_keyMapa);
                              } else {
                                _mostrarAvisoAcceso(item);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Construye la pagina completa adaptada a diferentes resoluciones de pantalla
  @override
  Widget build(BuildContext context) {
    final List<AvisoInstitucional> avisosFiltrados = widget.repository
        .obtenerAvisos(idCampusFiltro: _idCampusSeleccionado);
    final List<EventoCalendario> calendario =
        widget.repository.obtenerCalendarioEscolar();
    final List<AccionPerfilUaa> accionesPerfil = widget.repository
        .obtenerAccionesPorPerfil(esProfesor: _esPerfilProfesor);
    final List<ServicioCampusUaa> serviciosCampus = widget.repository
        .obtenerServiciosCampus(idCampusFiltro: _idCampusSeleccionado);
    final List<ActividadUniversitaria> actividades =
        widget.repository.obtenerActividades();

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 760;
    final bool isTablet = screenWidth >= 760 && screenWidth < 1100;
    final double horizontalPadding =
        isMobile ? 16 : (screenWidth * 0.035).clamp(24.0, 56.0);

    return Scaffold(
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!isMobile) _buildTopUtilityStrip(isDark),
              _buildBrandHeaderBar(
                context,
                isMobile,
                isTablet,
                isDark,
              ),
              _buildNavyNavigationBar(isMobile),
              // Carrusel hero fotografico a todo lo ancho del banner
              Container(
                key: _keyInicio,
                child: NoticesCarousel(
                  avisos: avisosFiltrados,
                  onActionPressed: _mostrarAvisoAcceso,
                ),
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
                        // Propuesta 4: Conmutador rapido Soy Alumno / Soy Profesor
                        Container(
                          key: _keyPerfil,
                          child: ProfileQuickSwitcher(
                            esProfesor: _esPerfilProfesor,
                            onProfileChanged: _cambiarPerfil,
                            idCampusSeleccionado: _idCampusSeleccionado,
                            onCampusChanged: _cambiarFiltroCampus,
                            acciones: accionesPerfil,
                            onAccionPressed: _mostrarAvisoAcceso,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Seccion de 3 columnas: Noticias | Eventos | Servicios Digitales
                        Container(
                          key: _keyNoticiasEventos,
                          child: _buildThreeColumnPortalSection(
                            theme,
                            secondaryTextColor,
                            isDark,
                            isMobile,
                            isTablet,
                            avisosFiltrados,
                            calendario,
                          ),
                        ),
                        const SizedBox(height: 44),
                        // Propuesta 2: Directorio de Servicios en Campus con Horarios
                        Container(
                          key: _keyServicios,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _buildSectionHeading(
                                'SERVICIOS EN CAMPUS Y HORARIOS DE ATENCION',
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ubicacion de edificios, horarios de ventanilla y disponibilidad en tiempo real para estudiantes y docentes.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              CampusServicesSection(
                                servicios: serviciosCampus,
                                onSelectService: _mostrarAvisoAcceso,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 44),
                        // Propuesta 3: Cartelera de Actividades, Creditos Humanisticos y Deportes
                        Container(
                          key: _keyActividades,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _buildSectionHeading(
                                'ACTIVIDADES, CREDITOS HUMANISTICOS Y DEPORTES',
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Eventos culturales, torneos Gallos, talleres con valor curricular y cursos de formacion docente.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              UniversityActivitiesSection(
                                todasLasActividades: actividades,
                                onInscribirseActividad: _mostrarAvisoAcceso,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 44),
                        // Propuesta 1: Mapa y Ubicador Rapido de Edificios
                        Container(
                          key: _keyMapa,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _buildSectionHeading(
                                'MAPA UNIVERSITARIO Y UBICADOR DE EDIFICIOS',
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Localiza rapidamente aulas, laboratorios de computo, bibliotecas, cajas y auditorios en Campus Central y Sur.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              InteractiveCampusMapSection(
                                repository: widget.repository,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildOfficialUaaFooter(isMobile, horizontalPadding),
            ],
          ),
        ),
      ),
    );
  }

  // Cintillo superior gris azulado pegado a la derecha con enlaces rapidos de utilidad diaria
  Widget _buildTopUtilityStrip(bool isDark) {
    final List<MapEntry<String, VoidCallback>> enlacesSuperiores =
        <MapEntry<String, VoidCallback>>[
      MapEntry<String, VoidCallback>(
        'Eventos y Creditos Humanisticos',
        () => _desplazarASeccion(_keyActividades),
      ),
      MapEntry<String, VoidCallback>(
        'Bibliotecas y Horarios',
        () => _desplazarASeccion(_keyServicios),
      ),
      MapEntry<String, VoidCallback>(
        'Calendario Escolar',
        () => _desplazarASeccion(_keyNoticiasEventos),
      ),
      MapEntry<String, VoidCallback>(
        'Mapa de Edificios',
        () => _desplazarASeccion(_keyMapa),
      ),
      MapEntry<String, VoidCallback>(
        'Correo Institucional',
        () => _mostrarAvisoAcceso('Correo Institucional UAA'),
      ),
    ];

    final Color textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.primaryNavy;
    final Color dividerColor =
        isDark ? AppColors.darkBorder : const Color(0xFFB8C4D8);

    return Container(
      width: double.infinity,
      color: isDark ? AppColors.darkSurfaceMuted : AppColors.topStripBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        children: enlacesSuperiores.asMap().entries.map(
          (MapEntry<int, MapEntry<String, VoidCallback>> entry) {
            final bool isLast = entry.key == enlacesSuperiores.length - 1;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InkWell(
                  onTap: entry.value.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      entry.value.key,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 12,
                    color: dividerColor,
                  ),
              ],
            );
          },
        ).toList(),
      ),
    );
  }

  // Header compacto estilo oficial UAA: logo horizontal a la izquierda y controles a la derecha
  Widget _buildBrandHeaderBar(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Esquina izquierda: Emblema UAA + texto en 3 lineas horizontales
          Row(
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
              Image.asset(
                AppConstants.faviconUaaAsset,
                height: isMobile ? 36 : 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'UNIVERSIDAD',
                    style: TextStyle(
                      fontSize: isMobile ? 10.5 : 12,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: 0.6,
                      color: isDark ? Colors.white : AppColors.primaryNavy,
                    ),
                  ),
                  Text(
                    'AUTONOMA DE',
                    style: TextStyle(
                      fontSize: isMobile ? 10.5 : 12,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: 0.6,
                      color: isDark ? Colors.white : AppColors.primaryNavy,
                    ),
                  ),
                  Text(
                    'AGUASCALIENTES',
                    style: TextStyle(
                      fontSize: isMobile ? 10.5 : 12,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: 0.6,
                      color: isDark ? Colors.white : AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Esquina derecha: Botones tipo pildora, buscador y boton de tema en el extremo derecho
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _buildHeaderPillButton(
                  label: 'E-SIIMA',
                  backgroundColor: AppColors.secondaryBlue,
                  onTap: () => _mostrarAvisoAcceso('E-SIIMA'),
                ),
                _buildHeaderPillButton(
                  label: isMobile ? 'AULA' : 'AULA VIRTUAL',
                  backgroundColor: AppColors.accentCrimson,
                  onTap: () => _mostrarAvisoAcceso('Aula Virtual'),
                ),
                if (!isMobile)
                  PopupMenuButton<String>(
                    tooltip: 'Menu Rapido',
                    onSelected: (String value) {
                      if (value == 'MAPA') {
                        _desplazarASeccion(_keyMapa);
                      } else if (value == 'SERVICIOS') {
                        _desplazarASeccion(_keyServicios);
                      } else if (value == 'CREDITOS') {
                        _desplazarASeccion(_keyActividades);
                      } else {
                        _mostrarAvisoAcceso(value);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'Inscripcion de Materias',
                        child: Text('Inscripcion de Materias (E-SIIMA)'),
                      ),
                      PopupMenuItem<String>(
                        value: 'Entrega de Tareas (Aula Virtual)',
                        child: Text('Entrega de Tareas (Aula Virtual)'),
                      ),
                      PopupMenuItem<String>(
                        value: 'MAPA',
                        child: Text('Ubicar Edificio o Laboratorio'),
                      ),
                      PopupMenuItem<String>(
                        value: 'SERVICIOS',
                        child: Text('Horarios de Cajas, Biblioteca y UMD'),
                      ),
                      PopupMenuItem<String>(
                        value: 'CREDITOS',
                        child: Text('Eventos de Creditos Humanisticos'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'MENU RAPIDO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!isMobile && !isTablet) _buildSearchBox(isDark),
                IconButton(
                  tooltip: widget.isDarkMode
                      ? 'Cambiar a modo claro'
                      : 'Cambiar a modo oscuro',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceMuted
                        : AppColors.lightSurfaceMuted,
                    side: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  onPressed: widget.onToggleTheme,
                  icon: Icon(
                    widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    size: 18,
                    color: isDark
                        ? AppColors.footerAccentBlue
                        : AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construye un boton tipo pildora compacto como los del header oficial de la UAA
  Widget _buildHeaderPillButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // Caja de busqueda interactiva en el header para localizar edificios y servicios
  Widget _buildSearchBox(bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _abrirBuscadorInstitucional,
      child: Container(
        width: 195,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceMuted : const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'BUSCAR EDIFICIO / TRAMITE',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            Icon(
              Icons.search,
              size: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // Propuesta 5: Barra azul marino reorganizada con scroll directo a las secciones utiles
  Widget _buildNavyNavigationBar(bool isMobile) {
    final List<MapEntry<String, GlobalKey>> secciones =
        <MapEntry<String, GlobalKey>>[
      MapEntry<String, GlobalKey>('INICIO', _keyInicio),
      MapEntry<String, GlobalKey>('ALUMNOS Y DOCENTES', _keyPerfil),
      MapEntry<String, GlobalKey>('NOTICIAS Y CALENDARIO', _keyNoticiasEventos),
      MapEntry<String, GlobalKey>('SERVICIOS Y HORARIOS', _keyServicios),
      MapEntry<String, GlobalKey>('ACTIVIDADES Y CREDITOS', _keyActividades),
      MapEntry<String, GlobalKey>('MAPA UNIVERSITARIO', _keyMapa),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 9,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: isMobile ? 12 : 28,
        runSpacing: 8,
        children: secciones.map((MapEntry<String, GlobalKey> item) {
          return InkWell(
            onTap: () => _desplazarASeccion(item.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              child: Text(
                item.key,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Menu lateral para pantallas moviles con navegacion directa a cada herramienta
  Widget _buildMobileDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
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
              leading: const Icon(Icons.search),
              title: const Text('Buscar Edificio o Tramite'),
              onTap: () {
                Navigator.of(context).pop();
                _abrirBuscadorInstitucional();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Herramientas Alumno / Profesor'),
              onTap: () {
                Navigator.of(context).pop();
                _desplazarASeccion(_keyPerfil);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Noticias y Calendario Escolar'),
              onTap: () {
                Navigator.of(context).pop();
                _desplazarASeccion(_keyNoticiasEventos);
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time_outlined),
              title: const Text('Servicios y Horarios en Campus'),
              onTap: () {
                Navigator.of(context).pop();
                _desplazarASeccion(_keyServicios);
              },
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Actividades y Creditos Humanisticos'),
              onTap: () {
                Navigator.of(context).pop();
                _desplazarASeccion(_keyActividades);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Mapa y Ubicador de Edificios'),
              onTap: () {
                Navigator.of(context).pop();
                _desplazarASeccion(_keyMapa);
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

  // Titulo de seccion centrado con subrayado institucional guinda UAA
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
                    titulo: 'Herramientas para comunidad UAA',
                    enlaces: const <String>[
                      'Portal E-SIIMA Alumnos y Docentes',
                      'Aula Virtual Educacion Superior',
                      'Calendario Academico 2026-2',
                      'Biblioteca Digital y Repositorio',
                      'Horarios de Cajas y Control Escolar',
                    ],
                  ),
                  _buildFooterColumn(
                    titulo: 'Enlaces de transparencia',
                    enlaces: const <String>[
                      'Plataforma Nacional de Transparencia',
                      'Obligaciones de Transparencia (LGT)',
                      'Aviso de Privacidad Integral (LFPDPPP)',
                      'Defensoria de los Derechos Universitarios',
                      'Codigo de Etica y Conducta UAA',
                    ],
                  ),
                  _buildFooterColumn(
                    titulo: 'Ubicacion y contacto',
                    enlaces: const <String>[
                      'Campus Central (Av. Universidad #940)',
                      'Campus Sur (Blvd. Jose Maria Chavez)',
                      'Unidad Medico Didactica (UMD)',
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
