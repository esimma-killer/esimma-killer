// Entidad de dominio que representa una fecha oficial del calendario escolar
class EventoCalendario {
  final String mesAbreviado;
  final String diaNumero;
  final String evento;
  final String ubicacion;
  final String fechaCompleta;

  const EventoCalendario({
    required this.mesAbreviado,
    required this.diaNumero,
    required this.evento,
    required this.ubicacion,
    required this.fechaCompleta,
  });
}
