import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/services/window_title_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/landing_page_screen.dart';

// Punto de entrada principal de la aplicacion Flutter
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Limita la memoria de imagenes decodificadas para evitar picos en equipos con poca RAM
  PaintingBinding.instance.imageCache.maximumSizeBytes = 64 << 20;
  runApp(const EsimmaApp());
}

// Widget raiz de la aplicacion con transicion suave de tema y titulo dinamico por rol
class EsimmaApp extends StatefulWidget {
  const EsimmaApp({super.key});

  @override
  State<EsimmaApp> createState() => _EsimmaAppState();
}

class _EsimmaAppState extends State<EsimmaApp> {
  final WindowTitleService _windowTitleService = const WindowTitleService();
  bool _isDarkMode = false;
  bool _esProfesor = false;
  String _vistaActual = 'Inicio';
  String _tabTitle = 'UAA | Alumno - Inicio';

  // Alterna entre el modo visual claro y el modo oscuro con interpolacion suave
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // Actualiza el titulo de la pestana y de la ventana de Windows con rol y vista actual
  void _actualizarTitulo({bool? esProfesor, String? vista}) {
    if (esProfesor != null) {
      _esProfesor = esProfesor;
    }
    if (vista != null && vista.isNotEmpty) {
      _vistaActual = vista;
    }
    final String rol = _esProfesor ? 'Profesor' : 'Alumno';
    final String nuevoTitulo = 'UAA | $rol - $_vistaActual';
    if (_tabTitle != nuevoTitulo) {
      setState(() {
        _tabTitle = nuevoTitulo;
      });
    }
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: nuevoTitulo,
        primaryColor: 0xFF15325E,
      ),
    );
    _windowTitleService.actualizar(nuevoTitulo);
  }

  // Construye el MaterialApp con cambio instantaneo de tema sin interpolacion por cuadros
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _tabTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: Duration.zero,
      home: Title(
        title: _tabTitle,
        color: const Color(0xFF15325E),
        child: LandingPageScreen(
          isDarkMode: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onRoleChanged: (bool esProfesor) =>
              _actualizarTitulo(esProfesor: esProfesor),
          onSectionChanged: (String vista) => _actualizarTitulo(vista: vista),
        ),
      ),
    );
  }
}
