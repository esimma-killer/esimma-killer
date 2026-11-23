import '../../domain/entities/campus_info.dart';

// Repositorio de datos para obtener los nodos de campus configurados en el sistema
class CampusRepository {
  // Constructor constante del repositorio
  const CampusRepository();

  // Devuelve la lista de campus disponibles para preparar la capa de datos
  List<CampusInfo> obtenerCampusDisponibles() {
    return const <CampusInfo>[
      CampusInfo(
        idCampus: 1,
        nombre: 'Campus Central',
        ubicacion: 'Av. Universidad 940, Ciudad Universitaria',
        nodoBaseDatos: 'Shard 1 - PostgreSQL Central',
        activo: true,
      ),
      CampusInfo(
        idCampus: 2,
        nombre: 'Campus Sur',
        ubicacion: 'Blvd. Jose Maria Chavez, Zona Sur',
        nodoBaseDatos: 'Shard 2 - PostgreSQL Sur',
        activo: true,
      ),
    ];
  }
}
