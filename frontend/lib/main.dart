import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/landing_page_screen.dart';

// Punto de entrada principal de la aplicacion Flutter
void main() {
  runApp(const EsimmaApp());
}

// Widget raiz de la aplicacion con transicion suave de tema y titulo dinamico por rol
class EsimmaApp extends StatefulWidget {
  const EsimmaApp({super.key});

  @override
  State<EsimmaApp> createState() => _EsimmaAppState();
}

class _EsimmaAppState extends State<EsimmaApp> {
  bool _isDarkMode = false;
  String _tabTitle = AppConstants.appNameAlumno;

  // Alterna entre el modo visual claro y el modo oscuro con interpolacion suave
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // Actualiza el nombre de la pestana del navegador a UAA | Alumno o UAA | Profesor
  void _updateBrowserTabTitle(bool esProfesor) {
    final String nuevoTitulo = esProfesor
        ? AppConstants.appNameProfesor
        : AppConstants.appNameAlumno;
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
          onRoleChanged: _updateBrowserTabTitle,
        ),
      ),
    );
  }
}
