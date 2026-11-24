// Constantes generales de configuracion de la aplicacion cliente
class AppConstants {
  // Constructor privado para evitar instanciacion
  const AppConstants._();

  static const String appName = 'UAA | Alumno';
  static const String appNameAlumno = 'UAA | Alumno';
  static const String appNameProfesor = 'UAA | Profesor';
  static const String appSubtitle =
      'Portal Institucional y Aula Virtual Universitaria';
  static const String institutionName =
      'Universidad Autonoma de Aguascalientes';
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  static const String appVersion = '1.0.0';

  // Rutas de recursos graficos institucionales con fondo transparente en alta calidad
  static const String logoUaaLightAsset = 'assets/images/logo_uaa(calidad).png';
  static const String logoUaaDarkAsset = 'assets/images/logo_uaa(calidad).png';
  static const String faviconUaaAsset = 'assets/images/logo_uaa(calidad).png';

  // Mapas oficiales de alta resolucion de la Direccion General de Infraestructura Universitaria (DGIU)
  static const String mapaOficialCentralAsset =
      'assets/images/CAMPUS-CENTRAL-2025.jpg';
  static const String mapaOficialSurAsset =
      'assets/images/CAMPUS-SUR-2023.jpg';

  // Fotografias oficiales del campus UAA para el carrusel hero principal
  static const List<String> campusHeroImages = <String>[
    'assets/images/campus/uaa_banner_1.jpg',
    'assets/images/campus/uaa_banner_2.jpg',
    'assets/images/campus/uaa_banner_3.jpg',
    'assets/images/campus/uaa_banner_4.jpg',
    'assets/images/campus/uaa_banner_5.jpg',
    'assets/images/campus/uaa_banner_6.jpg',
  ];
}
