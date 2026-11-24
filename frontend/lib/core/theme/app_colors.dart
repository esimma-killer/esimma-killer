import 'package:flutter/material.dart';

// Paleta de colores institucional UAA sobria, moderna y sin tonos dorados
class AppColors {
  // Constructor privado para evitar instanciacion
  const AppColors._();

  // Azules institucionales y acento guinda sobrio UAA
  static const Color primaryNavy = Color(0xFF15325E);
  static const Color secondaryBlue = Color(0xFF28559A);
  static const Color accentCrimson = Color(0xFFA8244E);
  static const Color slateBlue = Color(0xFF3E5C8A);
  static const Color darkNavyFooter = Color(0xFF0F2444);
  static const Color footerAccentBlue = Color(0xFF8AB0E6);
  static const Color topStripBackground = Color(0xFFE6ECF5);

  // Colores para el modo claro
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFEDF1F7);
  static const Color lightTextPrimary = Color(0xFF16202E);
  static const Color lightTextSecondary = Color(0xFF4A5668);
  static const Color lightBorder = Color(0xFFD5DCE6);

  // Colores para el modo oscuro
  static const Color darkBackground = Color(0xFF0E131A);
  static const Color darkSurface = Color(0xFF171F2A);
  static const Color darkSurfaceMuted = Color(0xFF202A38);
  static const Color darkTextPrimary = Color(0xFFEBF0F7);
  static const Color darkTextSecondary = Color(0xFFA3B1C6);
  static const Color darkBorder = Color(0xFF2B3748);

  // Colores de estado discretos
  static const Color statusActive = Color(0xFF246A4B);
  static const Color statusWarning = Color(0xFF3E5C8A);
  static const Color statusError = Color(0xFF923434);
}
