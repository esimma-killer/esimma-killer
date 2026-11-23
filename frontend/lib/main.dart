import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_placeholder_screen.dart';

// Punto de entrada principal de la aplicacion Flutter
void main() {
  runApp(const EsimmaApp());
}

// Widget raiz de la aplicacion con soporte para cambio de tema claro y oscuro
class EsimmaApp extends StatefulWidget {
  const EsimmaApp({super.key});

  @override
  State<EsimmaApp> createState() => _EsimmaAppState();
}

class _EsimmaAppState extends State<EsimmaApp> {
  bool _isDarkMode = false;

  // Alterna entre el modo visual claro y el modo oscuro
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // Construye el MaterialApp con los temas institucionales planos configurados
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomePlaceholderScreen(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
