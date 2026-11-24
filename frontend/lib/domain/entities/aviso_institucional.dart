// Entidad de dominio que representa un aviso o noticia institucional de la UAA
class AvisoInstitucional {
  final String idAviso;
  final String titulo;
  final String resumen;
  final int idCampus;
  final String fechaPublicacion;
  final String categoria;
  final String imagenAsset;

  const AvisoInstitucional({
    required this.idAviso,
    required this.titulo,
    required this.resumen,
    required this.idCampus,
    required this.fechaPublicacion,
    required this.categoria,
    required this.imagenAsset,
  });

  // Devuelve el nombre legible del campus al que pertenece el aviso
  String get nombreCampus =>
      idCampus == 1 ? 'Campus Central' : 'Campus Sur';
}
