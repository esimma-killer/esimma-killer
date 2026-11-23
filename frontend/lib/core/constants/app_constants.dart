// Constantes generales de configuracion de la aplicacion cliente
class AppConstants {
  // Constructor privado para evitar instanciacion
  const AppConstants._();

  static const String appName = 'E-SIIMA UAA';
  static const String appSubtitle =
      'Sistema Institucional de Gestion Academica Distribuida';
  static const String institutionName =
      'Universidad Autonoma de Aguascalientes';
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  static const String appVersion = '1.0.0';

  // Rutas de recursos graficos institucionales
  static const String logoUaaAsset = 'assets/images/logo_uaa.png';
  static const String faviconUaaAsset = 'assets/images/favicon_uaa.png';
}
