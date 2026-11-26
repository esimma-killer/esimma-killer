import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/portal_repository.dart';
import '../../domain/entities/aviso_institucional.dart';
import '../../domain/entities/evento_calendario.dart';
import '../../domain/entities/portal_models.dart';
import '../widgets/campus_services_section.dart';
import '../widgets/daily_summary_and_live_campus_widgets.dart';
import '../widgets/hover_animated_card.dart';
import '../widgets/interactive_campus_map_section.dart';
import '../widgets/notices_carousel.dart';
import '../widgets/profile_quick_switcher.dart';
import '../widgets/quick_access_grid.dart';
import '../widgets/school_calendar_card.dart';
import '../widgets/transport_and_faq_widgets.dart';
import '../widgets/university_activities_section.dart';

// Portal principal UAA con navegacion multi-ventana, header fijo en PC y secciones condicionales
class LandingPageScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<bool>? onRoleChanged;
  final PortalRepository repository;

  const LandingPageScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.onRoleChanged,
    this.repository = const PortalRepository(),
  });

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  late List<SesionUsuarioUaa> _perfilesDisponibles;
  late SesionUsuarioUaa _sesionActiva;

  // Campus activo (1 = Campus Central, 2 = Campus Sur): se detecta segun el usuario
  int _idCampusSeleccionado = 1;

  // Ventana o pantalla activa dentro del portal
  SeccionPortalUaa _seccionActiva = SeccionPortalUaa.inicio;

  // Controlador de scroll para volver arriba al cambiar de ventana
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _perfilesDisponibles = widget.repository.obtenerPerfilesPrueba();
    _sesionActiva = _perfilesDisponibles.first;
    _idCampusSeleccionado = _sesionActiva.idCampusOrigen;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Cambia la sesion simulada, detecta su campus principal y actualiza el titulo de la pestana
  void _cambiarSesionDetectada(SesionUsuarioUaa nuevaSesion) {
    setState(() {
      _sesionActiva = nuevaSesion;
      _idCampusSeleccionado = nuevaSesion.idCampusOrigen;
    });
    if (widget.onRoleChanged != null) {
      widget.onRoleChanged!(nuevaSesion.esProfesor);
    }
  }

  // Permite al alumno o profesor alternar entre Campus Central y Campus Sur
  void _cambiarFiltroCampus(int nuevoCampus) {
    setState(() {
      _idCampusSeleccionado = nuevoCampus;
    });
  }

  // Navega a otra pantalla o ventana dedicada del portal y posiciona el scroll al inicio
  void _navegarASeccion(SeccionPortalUaa nuevaSeccion) {
    setState(() {
      _seccionActiva = nuevaSeccion;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
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

  // Abre el buscador rapido para localizar edificios, servicios o tramites y abrir su ventana
  void _abrirBuscadorInstitucional() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        String filtro = '';
        final List<MapEntry<String, SeccionPortalUaa>>
        catalogo = <MapEntry<String, SeccionPortalUaa>>[
          const MapEntry<String, SeccionPortalUaa>(
            'Mapa: Edificio 1-A - Cajas y Control Escolar (Campus Central)',
            SeccionPortalUaa.mapaUniversitario,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'Mapa: Edificio 56 - Biblioteca Central Dr. Desiderio Macias Silva',
            SeccionPortalUaa.mapaUniversitario,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'Mapa: Edificio 60 - Laboratorios de Computo y Sistemas',
            SeccionPortalUaa.mapaUniversitario,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'Mapa: Edificio 101 - Unidad Medico Didactica (UMD)',
            SeccionPortalUaa.mapaUniversitario,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'Mapa: Campus Sur - Edificio B Laboratorios de Ingenieria',
            SeccionPortalUaa.mapaUniversitario,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'Horarios: Ventanilla de Cajas, Bibliotecas y UMD',
            SeccionPortalUaa.serviciosHorarios,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'Transporte Universitario Gallos (Rutas Central <-> Campus Sur)',
            SeccionPortalUaa.transporteUniversitario,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'Creditos Humanisticos, Deportes Gallos y Talleres',
            SeccionPortalUaa.actividadesCreditos,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'Guia Paso a Paso de Tramites (Justificantes UMD, Sobrecupo, Kardex)',
            SeccionPortalUaa.calendarioDirectorio,
          ),
        ];

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<MapEntry<String, SeccionPortalUaa>> resultados = catalogo
                .where(
                  (MapEntry<String, SeccionPortalUaa> item) =>
                      item.key.toLowerCase().contains(filtro.toLowerCase()),
                )
                .toList();

            return AlertDialog(
              title: const Text('Buscador Rapido UAA'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un edificio, transporte, tramite o servicio...',
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
                          final MapEntry<String, SeccionPortalUaa> item =
                              resultados[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.open_in_new, size: 18),
                            title: Text(item.key),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _navegarASeccion(item.value);
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

  // Construye la estructura con Header Fijo en PC/Laptop y Menu Hamburguesa en Tablet/Celular
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isPcOrLaptop = screenWidth >= 1024;
    final bool isMobile = screenWidth < 700;
    final bool isTablet = screenWidth >= 700 && screenWidth < 1024;
    final double horizontalPadding = isMobile
        ? 16
        : (screenWidth * 0.035).clamp(24.0, 56.0);

    return Scaffold(
      drawer: !isPcOrLaptop ? _buildHamburgerDrawer(isDark) : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header superior fijo que acompana al usuario al hacer scroll
            _buildBrandHeaderBar(
              context,
              isPcOrLaptop: isPcOrLaptop,
              isMobile: isMobile,
              isDark: isDark,
            ),
            // La barra azul con las secciones solo se muestra afuera en PC o Laptop
            if (isPcOrLaptop) _buildNavyNavigationBar(),
            // En Mapa Universitario ocupa toda la pantalla sin scroll ni footer (modo Google Maps)
            Expanded(
              child: _seccionActiva == SeccionPortalUaa.mapaUniversitario
                  ? _buildDedicatedMapWindow(
                      theme: theme,
                      secondaryTextColor: secondaryTextColor,
                      horizontalPadding: horizontalPadding,
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  final Animation<Offset> slideAnimation =
                                      Tween<Offset>(
                                        begin: const Offset(0, 0.015),
                                        end: Offset.zero,
                                      ).animate(animation);
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: slideAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                            child: KeyedSubtree(
                              key: ValueKey<SeccionPortalUaa>(_seccionActiva),
                              child: _buildActiveWindowContent(
                                theme: theme,
                                secondaryTextColor: secondaryTextColor,
                                isDark: isDark,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                horizontalPadding: horizontalPadding,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildOfficialUaaFooter(isMobile, horizontalPadding),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Renderiza la pantalla principal o la ventana secundaria seleccionada por el usuario
  Widget _buildActiveWindowContent({
    required ThemeData theme,
    required Color secondaryTextColor,
    required bool isDark,
    required bool isMobile,
    required bool isTablet,
    required double horizontalPadding,
  }) {
    switch (_seccionActiva) {
      case SeccionPortalUaa.inicio:
        return _buildMainHomeWindow(
          theme: theme,
          secondaryTextColor: secondaryTextColor,
          isDark: isDark,
          isMobile: isMobile,
          isTablet: isTablet,
          horizontalPadding: horizontalPadding,
        );
      case SeccionPortalUaa.mapaUniversitario:
        return _buildDedicatedMapWindow(
          theme: theme,
          secondaryTextColor: secondaryTextColor,
          horizontalPadding: horizontalPadding,
        );
      case SeccionPortalUaa.serviciosHorarios:
        return _buildDedicatedServicesWindow(
          theme: theme,
          secondaryTextColor: secondaryTextColor,
          horizontalPadding: horizontalPadding,
        );
      case SeccionPortalUaa.transporteUniversitario:
        return _buildDedicatedTransportWindow(
          theme: theme,
          secondaryTextColor: secondaryTextColor,
          horizontalPadding: horizontalPadding,
        );
      case SeccionPortalUaa.actividadesCreditos:
        return _buildDedicatedActivitiesWindow(
          theme: theme,
          secondaryTextColor: secondaryTextColor,
          isDark: isDark,
          horizontalPadding: horizontalPadding,
        );
      case SeccionPortalUaa.calendarioDirectorio:
        return _buildDedicatedCalendarAndCentersWindow(
          theme: theme,
          secondaryTextColor: secondaryTextColor,
          isDark: isDark,
          isMobile: isMobile,
          horizontalPadding: horizontalPadding,
        );
    }
  }

  // Ventana 1 (Principal): Herramientas diarias sin repetir lo que vive en las otras pestanas
  Widget _buildMainHomeWindow({
    required ThemeData theme,
    required Color secondaryTextColor,
    required bool isDark,
    required bool isMobile,
    required bool isTablet,
    required double horizontalPadding,
  }) {
    final List<AvisoInstitucional> avisosFiltrados = widget.repository
        .obtenerAvisos(idCampusFiltro: _idCampusSeleccionado);
    final List<EventoCalendario> calendarioResumen = widget.repository
        .obtenerCalendarioEscolar()
        .take(4)
        .toList();
    final List<AccionPerfilUaa> accionesRol = widget.repository
        .obtenerAccionesPorPerfil(esProfesor: _sesionActiva.esProfesor);
    final List<EspacioDisponibleUaa> espaciosEnVivo = widget.repository
        .obtenerEspaciosDisponibles(idCampusFiltro: _idCampusSeleccionado);
    final List<MenuComedorUaa> menusComedor = widget.repository
        .obtenerMenusComedor(idCampusFiltro: _idCampusSeleccionado);
    final List<ConvocatoriaUaa> convocatorias = widget.repository
        .obtenerConvocatoriasVigentes(
          esProfesor: _sesionActiva.esProfesor,
          idCampusFiltro: _idCampusSeleccionado,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
                  // Seccion condicional: Tu Resumen de Hoy en la UAA (oculta cualquier elemento null)
                  DailySummaryBanner(
                    sesion: _sesionActiva,
                    onItemTap: _mostrarAvisoAcceso,
                  ),
                  // Herramientas exclusivas del rol detectado (Alumno o Profesor) y su campus
                  ProfileQuickSwitcher(
                    sesionActiva: _sesionActiva,
                    idCampusSeleccionado: _idCampusSeleccionado,
                    onCampusChanged: _cambiarFiltroCampus,
                    acciones: accionesRol,
                    onAccionPressed: _mostrarAvisoAcceso,
                  ),
                  const SizedBox(height: 32),
                  // Las 3 columnas principales: Noticias | Eventos | Recursos y Biblioteca Digital
                  _buildThreeColumnPortalSection(
                    theme,
                    secondaryTextColor,
                    isDark,
                    isMobile,
                    isTablet,
                    avisosFiltrados,
                    calendarioResumen,
                  ),
                  const SizedBox(height: 36),
                  // Ocupacion en Tiempo Real de Laboratorios y Comedor Universitario
                  _buildSectionHeading(
                    'OCUPACION EN VIVO DE LABORATORIOS Y COMEDOR UNIVERSITARIO',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Consulta equipos disponibles en salas de computo, cubiculos de estudio y el menu de hoy en comedores.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LiveCampusOccupancyAndDiningSection(
                    espacios: espaciosEnVivo,
                    menusComedor: menusComedor,
                    onTapAction: _mostrarAvisoAcceso,
                  ),
                  const SizedBox(height: 36),
                  // Convocatorias Vigentes del Mes con Contador de Dias
                  _buildSectionHeading(
                    'CONVOCATORIAS VIGENTES Y TRAMITES DEL MES',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Becas institucionales, cursos de idiomas CAADI, servicio social y programas de apoyo con fechas de cierre.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OpenCallsSection(
                    convocatorias: convocatorias,
                    onSelectCall: _mostrarAvisoAcceso,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Ventana 2 (Dedicada): Mapa Universitario estilo Google Maps ocupando 100% del area disponible
  Widget _buildDedicatedMapWindow({
    required ThemeData theme,
    required Color secondaryTextColor,
    required double horizontalPadding,
  }) {
    return InteractiveCampusMapSection(
      repository: widget.repository,
      initialCampusId: _idCampusSeleccionado,
      onBackToHome: () => _navegarASeccion(SeccionPortalUaa.inicio),
    );
  }

  // Ventana 3 (Dedicada exclusivamente a Servicios y Horarios de Atencion)
  Widget _buildDedicatedServicesWindow({
    required ThemeData theme,
    required Color secondaryTextColor,
    required double horizontalPadding,
  }) {
    final List<ServicioCampusUaa> servicios = widget.repository
        .obtenerServiciosCampus(idCampusFiltro: _idCampusSeleccionado);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1520),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSecondaryWindowTopBar(
                titulo:
                    'DIRECTORIO DE SERVICIOS EN CAMPUS Y HORARIOS DE ATENCION',
                subtitulo: 'Consulta horarios de ventanilla, ubicaciones exactas, extensiones telefonicas y disponibilidad de servicios universitarios.',
                theme: theme,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
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
              const SizedBox(height: 16),
              CampusServicesSection(
                servicios: servicios,
                onSelectService: _mostrarAvisoAcceso,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ventana 4 (Dedicada exclusivamente al Transporte Universitario Gallos)
  Widget _buildDedicatedTransportWindow({
    required ThemeData theme,
    required Color secondaryTextColor,
    required double horizontalPadding,
  }) {
    final List<RutaTransporteUaa> rutasTransporte = widget.repository
        .obtenerRutasTransporte();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1520),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSecondaryWindowTopBar(
                titulo: 'TRANSPORTE UNIVERSITARIO GALLOS Y RUTAS INTERCAMPUS',
                subtitulo: 'Consulta las proximas salidas de autobuses entre Campus Central y Campus Sur, circuito interno y paraderos oficiales.',
                theme: theme,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: 20),
              UniversityTransportMonitor(rutas: rutasTransporte),
            ],
          ),
        ),
      ),
    );
  }

  // Ventana 5 (Dedicada): Actividades, Creditos Humanisticos, Deportes y Talleres
  Widget _buildDedicatedActivitiesWindow({
    required ThemeData theme,
    required Color secondaryTextColor,
    required bool isDark,
    required double horizontalPadding,
  }) {
    final List<ActividadUniversitaria> actividades = widget.repository
        .obtenerActividades();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1520),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSecondaryWindowTopBar(
                titulo: 'CARTELERA DE ACTIVIDADES, CREDITOS HUMANISTICOS Y DEPORTES',
                subtitulo: 'Inscribete a eventos culturales, torneos deportivos Gallos, talleres con valor curricular y cursos de actualizacion docente.',
                theme: theme,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: 20),
              UniversityActivitiesSection(
                todasLasActividades: actividades,
                onInscribirseActividad: _mostrarAvisoAcceso,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ventana 6 (Dedicada): Calendario Escolar, Directorio de Centros y Guia Paso a Paso de Tramites (FAQ)
  Widget _buildDedicatedCalendarAndCentersWindow({
    required ThemeData theme,
    required Color secondaryTextColor,
    required bool isDark,
    required bool isMobile,
    required double horizontalPadding,
  }) {
    final List<EventoCalendario> calendario = widget.repository
        .obtenerCalendarioEscolar();
    final List<CentroAcademicoUaa> centros = widget.repository
        .obtenerCentrosAcademicos();
    final List<GuiaTramiteFaqUaa> guiasFaq = widget.repository
        .obtenerGuiasTramitesFaq();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1520),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSecondaryWindowTopBar(
                titulo:
                    'CALENDARIO ESCOLAR, CENTROS ACADEMICOS Y GUIA DE TRAMITES',
                subtitulo: 'Fechas oficiales del semestre 2026-2, directorio de Decanatos y guia paso a paso para tramites frecuentes.',
                theme: theme,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: 20),
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SchoolCalendarCard(
                      eventos: calendario,
                      onVerCalendarioCompleto: () => _mostrarAvisoAcceso(
                        'Descarga de Calendario Oficial PDF',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCentersDirectoryCard(
                      theme,
                      centros,
                      isDark,
                      secondaryTextColor,
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: SchoolCalendarCard(
                        eventos: calendario,
                        onVerCalendarioCompleto: () => _mostrarAvisoAcceso(
                          'Descarga de Calendario Oficial PDF',
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: _buildCentersDirectoryCard(
                        theme,
                        centros,
                        isDark,
                        secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              StepByStepProceduresFaq(guias: guiasFaq),
            ],
          ),
        ),
      ),
    );
  }

  // Construye el directorio de Centros Academicos de la UAA
  Widget _buildCentersDirectoryCard(
    ThemeData theme,
    List<CentroAcademicoUaa> centros,
    bool isDark,
    Color secondaryTextColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'DIRECTORIO DE CENTROS ACADEMICOS (DECANATOS)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.footerAccentBlue
                    : AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            ...centros.map((CentroAcademicoUaa centro) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HoverAnimatedCard(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceMuted
                      : AppColors.lightSurfaceMuted,
                  onTap: () => _mostrarAvisoAcceso(centro.nombre),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 58,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: centro.idCampus == 1
                              ? AppColors.primaryNavy
                              : AppColors.secondaryBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          centro.siglas,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              centro.nombre,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${centro.decanatoEdificio} | ${centro.extensionTelefonica}',
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
          ],
        ),
      ),
    );
  }

  // Barra de encabezado para las pantallas secundarias con boton de regreso al Inicio
  Widget _buildSecondaryWindowTopBar({
    required String titulo,
    required String subtitulo,
    required ThemeData theme,
    required Color secondaryTextColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    titulo,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _navegarASeccion(SeccionPortalUaa.inicio),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Volver a Inicio'),
            ),
          ],
        ),
      ),
    );
  }

  // Selector compacto de sesion detectada para probar en vivo roles y campos null
  Widget _buildSessionSelectorPill() {
    return PopupMenuButton<SesionUsuarioUaa>(
      tooltip: 'Cambiar sesion detectada (Alumno / Docente)',
      onSelected: _cambiarSesionDetectada,
      itemBuilder: (BuildContext context) {
        return _perfilesDisponibles.map((SesionUsuarioUaa sesion) {
          return PopupMenuItem<SesionUsuarioUaa>(
            value: sesion,
            child: Text('${sesion.nombre} (${sesion.identificador})'),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.slateBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              _sesionActiva.descripcionSesion,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 15),
          ],
        ),
      ),
    );
  }

  // Boton menu rapido ordenado por prioridad: Entrega de Tareas, Mapa, Transporte, Servicios y Horarios, y el resto
  Widget _buildQuickMenuButton(bool isMobile) {
    return PopupMenuButton<String>(
      tooltip: 'Menu Rapido',
      onSelected: (String value) {
        if (value == 'MAPA') {
          _navegarASeccion(SeccionPortalUaa.mapaUniversitario);
        } else if (value == 'TRANSPORTE') {
          _navegarASeccion(SeccionPortalUaa.transporteUniversitario);
        } else if (value == 'SERVICIOS') {
          _navegarASeccion(SeccionPortalUaa.serviciosHorarios);
        } else if (value == 'CREDITOS') {
          _navegarASeccion(SeccionPortalUaa.actividadesCreditos);
        } else if (value == 'CALENDARIO') {
          _navegarASeccion(SeccionPortalUaa.calendarioDirectorio);
        } else {
          _mostrarAvisoAcceso(value);
        }
      },
      itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'Entrega de Tareas (Aula Virtual)',
          child: Text('Entrega de Tareas'),
        ),
        PopupMenuItem<String>(value: 'MAPA', child: Text('Mapa Universitario')),
        PopupMenuItem<String>(value: 'TRANSPORTE', child: Text('Transporte')),
        PopupMenuItem<String>(
          value: 'SERVICIOS',
          child: Text('Servicios y Horarios'),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'Inscripcion de Materias',
          child: Text('Inscripcion de Materias (E-SIIMA)'),
        ),
        PopupMenuItem<String>(
          value: 'CREDITOS',
          child: Text('Actividades y Creditos Humanisticos'),
        ),
        PopupMenuItem<String>(
          value: 'CALENDARIO',
          child: Text('Calendario, Centros y Guia de Tramites FAQ'),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              isMobile ? 'MENU' : 'MENU RAPIDO',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  // Boton circular para alternar de forma instantanea entre modo claro y oscuro
  Widget _buildThemeToggleButton(bool isDark) {
    return IconButton(
      tooltip: widget.isDarkMode
          ? 'Cambiar a modo claro'
          : 'Cambiar a modo oscuro',
      style: IconButton.styleFrom(
        backgroundColor: isDark
            ? AppColors.darkSurfaceMuted
            : AppColors.lightSurfaceMuted,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      onPressed: widget.onToggleTheme,
      icon: Icon(
        widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        size: 18,
        color: isDark ? AppColors.footerAccentBlue : AppColors.primaryNavy,
      ),
    );
  }

  // Header compacto fijo con cambio instantaneo de color entre modo claro y oscuro
  Widget _buildBrandHeaderBar(
    BuildContext context, {
    required bool isPcOrLaptop,
    required bool isMobile,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 24,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Esquina izquierda: Menu hamburguesa animado (en Tablet y Celular) + Emblema y Nombre UAA
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!isPcOrLaptop)
                Builder(
                  builder: (BuildContext ctx) => IconButton(
                    icon: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.85, end: 1.0),
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutBack,
                      builder:
                          (BuildContext context, double scale, Widget? child) {
                            return Transform.scale(scale: scale, child: child);
                          },
                      child: const Icon(Icons.menu),
                    ),
                    tooltip: 'Abrir menu de secciones',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              InkWell(
                onTap: () => _navegarASeccion(SeccionPortalUaa.inicio),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Image.asset(
                      AppConstants.faviconUaaAsset,
                      height: isMobile ? 34 : 44,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'UNIVERSIDAD',
                          style: TextStyle(
                            fontSize: isMobile ? 9.5 : 12,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: 0.5,
                            color: isDark
                                ? Colors.white
                                : AppColors.primaryNavy,
                          ),
                        ),
                        Text(
                          'AUTONOMA DE',
                          style: TextStyle(
                            fontSize: isMobile ? 9.5 : 12,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: 0.5,
                            color: isDark
                                ? Colors.white
                                : AppColors.primaryNavy,
                          ),
                        ),
                        Text(
                          'AGUASCALIENTES',
                          style: TextStyle(
                            fontSize: isMobile ? 9.5 : 12,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: 0.5,
                            color: isDark
                                ? Colors.white
                                : AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Esquina derecha: En celular pone Alumno(Campus) arriba a la derecha y E-SIIMA abajo junto con los botones y tema
          Flexible(
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildSessionSelectorPill(),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          _buildHeaderPillButton(
                            label: 'E-SIIMA',
                            backgroundColor: AppColors.secondaryBlue,
                            onTap: () => _mostrarAvisoAcceso('E-SIIMA'),
                          ),
                          _buildHeaderPillButton(
                            label: 'AULA',
                            backgroundColor: AppColors.accentCrimson,
                            onTap: () => _mostrarAvisoAcceso('Aula Virtual'),
                          ),
                          _buildQuickMenuButton(true),
                          _buildThemeToggleButton(isDark),
                        ],
                      ),
                    ],
                  )
                : Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      _buildSessionSelectorPill(),
                      _buildHeaderPillButton(
                        label: 'E-SIIMA',
                        backgroundColor: AppColors.secondaryBlue,
                        onTap: () => _mostrarAvisoAcceso('E-SIIMA'),
                      ),
                      _buildHeaderPillButton(
                        label: 'AULA VIRTUAL',
                        backgroundColor: AppColors.accentCrimson,
                        onTap: () => _mostrarAvisoAcceso('Aula Virtual'),
                      ),
                      _buildQuickMenuButton(false),
                      if (isPcOrLaptop) _buildSearchBox(isDark),
                      _buildThemeToggleButton(isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Boton tipo pildora compacto del header
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // Caja de busqueda interactiva en el header para PC/Laptop
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

  // Barra azul marino fija exclusiva para PC y Laptop con pestanas separadas para Servicios y Transporte
  Widget _buildNavyNavigationBar() {
    final List<MapEntry<String, SeccionPortalUaa>> secciones =
        <MapEntry<String, SeccionPortalUaa>>[
          const MapEntry<String, SeccionPortalUaa>(
            'INICIO',
            SeccionPortalUaa.inicio,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'MAPA UNIVERSITARIO',
            SeccionPortalUaa.mapaUniversitario,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'SERVICIOS Y HORARIOS',
            SeccionPortalUaa.serviciosHorarios,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'TRANSPORTE UNIVERSITARIO',
            SeccionPortalUaa.transporteUniversitario,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'ACTIVIDADES Y CREDITOS',
            SeccionPortalUaa.actividadesCreditos,
          ),
          const MapEntry<String, SeccionPortalUaa>(
            'CALENDARIO, CENTROS Y FAQ',
            SeccionPortalUaa.calendarioDirectorio,
          ),
        ];

    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 8,
        children: secciones.map((MapEntry<String, SeccionPortalUaa> item) {
          final bool activa = _seccionActiva == item.value;
          return InkWell(
            onTap: () => _navegarASeccion(item.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: activa ? AppColors.secondaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.key,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: activa ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Menu hamburguesa para Tablet y Celular con animacion de entrada escalonada en sus opciones
  Widget _buildHamburgerDrawer(bool isDark) {
    final List<Map<String, Object>> opcionesMenu = <Map<String, Object>>[
      <String, Object>{
        'icono': Icons.home_outlined,
        'titulo': 'Inicio (Portal Principal)',
        'seccion': SeccionPortalUaa.inicio,
      },
      <String, Object>{
        'icono': Icons.map_outlined,
        'titulo': 'Mapa Universitario Interactivo',
        'seccion': SeccionPortalUaa.mapaUniversitario,
      },
      <String, Object>{
        'icono': Icons.access_time_outlined,
        'titulo': 'Servicios y Horarios de Atencion',
        'seccion': SeccionPortalUaa.serviciosHorarios,
      },
      <String, Object>{
        'icono': Icons.directions_bus_outlined,
        'titulo': 'Transporte Universitario Gallos',
        'seccion': SeccionPortalUaa.transporteUniversitario,
      },
      <String, Object>{
        'icono': Icons.workspace_premium_outlined,
        'titulo': 'Actividades y Creditos Humanisticos',
        'seccion': SeccionPortalUaa.actividadesCreditos,
      },
      <String, Object>{
        'icono': Icons.calendar_month_outlined,
        'titulo': 'Calendario, Centros y Tramites FAQ',
        'seccion': SeccionPortalUaa.calendarioDirectorio,
      },
    ];

    return Drawer(
      child: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double progress, Widget? child) {
            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(-18 * (1 - progress), 0),
                child: child,
              ),
            );
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                color: AppColors.primaryNavy,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _sesionActiva.esProfesor
                                ? AppConstants.appNameProfesor
                                : AppConstants.appNameAlumno,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sesion: ${_sesionActiva.descripcionSesion}',
                            style: const TextStyle(
                              color: AppColors.footerAccentBlue,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar menu',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
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
              ...opcionesMenu.map((Map<String, Object> item) {
                final SeccionPortalUaa sec =
                    item['seccion']! as SeccionPortalUaa;
                final bool activa = _seccionActiva == sec;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: activa
                          ? (isDark
                                ? AppColors.darkSurfaceMuted
                                : const Color(0xFFE3ECF8))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icono']! as IconData,
                        color: activa
                            ? (isDark
                                  ? AppColors.footerAccentBlue
                                  : AppColors.primaryNavy)
                            : null,
                      ),
                      title: Text(
                        item['titulo']! as String,
                        style: TextStyle(
                          fontWeight: activa
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      selected: activa,
                      onTap: () {
                        Navigator.of(context).pop();
                        _navegarASeccion(sec);
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Seccion central de 3 columnas: Noticias | Eventos | Recursos y Biblioteca Digital
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
          onPressed: () =>
              _navegarASeccion(SeccionPortalUaa.actividadesCreditos),
          child: const Text(
            'VER CARTELERA DE ACTIVIDADES',
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
              _navegarASeccion(SeccionPortalUaa.calendarioDirectorio),
        ),
      ],
    );

    final Widget columnaAccesos = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionHeading('RECURSOS Y BIBLIOTECA'),
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
        Container(width: 72, height: 3, color: AppColors.accentCrimson),
      ],
    );
  }

  // Tarjeta de noticia con miniatura fotografica y animacion hover/tactil
  Widget _buildNewsCard(
    ThemeData theme,
    Color secondaryTextColor,
    bool isDark,
    AvisoInstitucional aviso,
  ) {
    return HoverAnimatedCard(
      padding: EdgeInsets.zero,
      onTap: () => _mostrarAvisoAcceso(aviso.titulo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 132,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(aviso.imagenAsset, fit: BoxFit.cover),
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
                    titulo: 'Secciones del portal UAA',
                    enlaces: <MapEntry<String, VoidCallback>>[
                      MapEntry<String, VoidCallback>(
                        'Inicio - Portal Principal',
                        () => _navegarASeccion(SeccionPortalUaa.inicio),
                      ),
                      MapEntry<String, VoidCallback>(
                        'Mapa Universitario Interactivo',
                        () => _navegarASeccion(
                          SeccionPortalUaa.mapaUniversitario,
                        ),
                      ),
                      MapEntry<String, VoidCallback>(
                        'Directorio de Servicios y Horarios',
                        () => _navegarASeccion(
                          SeccionPortalUaa.serviciosHorarios,
                        ),
                      ),
                      MapEntry<String, VoidCallback>(
                        'Transporte Universitario Gallos',
                        () => _navegarASeccion(
                          SeccionPortalUaa.transporteUniversitario,
                        ),
                      ),
                      MapEntry<String, VoidCallback>(
                        'Actividades y Creditos Humanisticos',
                        () => _navegarASeccion(
                          SeccionPortalUaa.actividadesCreditos,
                        ),
                      ),
                      MapEntry<String, VoidCallback>(
                        'Calendario, Centros y Tramites FAQ',
                        () => _navegarASeccion(
                          SeccionPortalUaa.calendarioDirectorio,
                        ),
                      ),
                    ],
                  ),
                  _buildFooterColumn(
                    titulo: 'Enlaces de transparencia',
                    enlaces: <MapEntry<String, VoidCallback>>[
                      MapEntry<String, VoidCallback>(
                        'Plataforma Nacional de Transparencia',
                        () => _mostrarAvisoAcceso(
                          'Plataforma Nacional de Transparencia',
                        ),
                      ),
                      MapEntry<String, VoidCallback>(
                        'Obligaciones de Transparencia (LGT)',
                        () => _mostrarAvisoAcceso(
                          'Obligaciones de Transparencia',
                        ),
                      ),
                      MapEntry<String, VoidCallback>(
                        'Aviso de Privacidad Integral (LFPDPPP)',
                        () => _mostrarAvisoAcceso('Aviso de Privacidad UAA'),
                      ),
                      MapEntry<String, VoidCallback>(
                        'Defensoria de los Derechos Universitarios',
                        () => _mostrarAvisoAcceso('Defensoria UAA'),
                      ),
                    ],
                  ),
                  _buildFooterColumn(
                    titulo: 'Ubicacion y contacto',
                    enlaces: <MapEntry<String, VoidCallback>>[
                      MapEntry<String, VoidCallback>(
                        'Campus Central (Av. Universidad #940)',
                        () {
                          _cambiarFiltroCampus(1);
                          _navegarASeccion(SeccionPortalUaa.mapaUniversitario);
                        },
                      ),
                      MapEntry<String, VoidCallback>(
                        'Campus Sur (Blvd. Jose Maria Chavez)',
                        () {
                          _cambiarFiltroCampus(2);
                          _navegarASeccion(SeccionPortalUaa.mapaUniversitario);
                        },
                      ),
                      MapEntry<String, VoidCallback>(
                        'Unidad Medico Didactica (UMD)',
                        () => _navegarASeccion(
                          SeccionPortalUaa.serviciosHorarios,
                        ),
                      ),
                      MapEntry<String, VoidCallback>(
                        'Buzon de Quejas y Sugerencias',
                        () => _mostrarAvisoAcceso('Buzon Universitario UAA'),
                      ),
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
                        filterQuality: FilterQuality.medium,
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
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tel. conmutador: 449 910 74 00 | Buzon de quejas y sugerencias',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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

  // Construye una columna de enlaces interactivos para el pie de pagina azul marino
  Widget _buildFooterColumn({
    required String titulo,
    required List<MapEntry<String, VoidCallback>> enlaces,
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
          ...enlaces.map((MapEntry<String, VoidCallback> item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: item.value,
                child: Text(
                  item.key,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
