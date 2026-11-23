import 'package:flutter/material.dart';

// Paleta de colores institucional UAA con estetica sobria y plana
class AppColors {
  // Constructor privado para evitar instanciacion
  const AppColors._();

  // Colores principales institucionales (tonos sobrios sin saturacion excesiva)
  static const Color primaryNavy = Color(0xFF1B365D);
  static const Color secondaryGold = Color(0xFF9E7B32);
  static const Color slateBlue = Color(0xFF3B5378);

  // Colores para el modo claro
  static const Color lightBackground = Color(0xFFF4F6F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E242B);
  static const Color lightTextSecondary = Color(0xFF525D6A);
  static const Color lightBorder = Color(0xFFDCE1E7);

  // Colores para el modo oscuro
  static const Color darkBackground = Color(0xFF12161C);
  static const Color darkSurface = Color(0xFF1C222B);
  static const Color darkTextPrimary = Color(0xFFE6E9EF);
  static const Color darkTextSecondary = Color(0xFFA2ABB8);
  static const Color darkBorder = Color(0xFF2E3744);

  // Colores de estado discretos
  static const Color statusActive = Color(0xFF2E6B4E);
  static const Color statusWarning = Color(0xFF8C6223);
  static const Color statusError = Color(0xFF923434);
}
