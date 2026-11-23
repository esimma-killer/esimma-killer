// Modelo de dominio que representa la informacion base de un campus universitario
class CampusInfo {
  final int idCampus;
  final String nombre;
  final String ubicacion;
  final String nodoBaseDatos;
  final bool activo;

  const CampusInfo({
    required this.idCampus,
    required this.nombre,
    required this.ubicacion,
    required this.nodoBaseDatos,
    required this.activo,
  });
}
