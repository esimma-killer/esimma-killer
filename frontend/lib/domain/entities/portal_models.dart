import 'package:flutter/material.dart';

// Modelo que representa una accion rapida personalizada para Alumno o Profesor
class AccionPerfilUaa {
  final String titulo;
  final String descripcion;
  final String etiquetaModulo;
  final IconData icono;

  const AccionPerfilUaa({
    required this.titulo,
    required this.descripcion,
    required this.etiquetaModulo,
    required this.icono,
  });
}

// Modelo que representa un servicio fisico o digital disponible en el campus
class ServicioCampusUaa {
  final String nombre;
  final String ubicacion;
  final String horario;
  final String estadoActual;
  final String descripcion;
  final int idCampus;
  final IconData icono;

  const ServicioCampusUaa({
    required this.nombre,
    required this.ubicacion,
    required this.horario,
    required this.estadoActual,
    required this.descripcion,
    required this.idCampus,
    required this.icono,
  });
}

// Modelo que representa una actividad cultural, deportiva, humanistica o docente
class ActividadUniversitaria {
  final String titulo;
  final String categoria;
  final String beneficio;
  final String fechaHora;
  final String lugar;
  final String modalidadCupo;

  const ActividadUniversitaria({
    required this.titulo,
    required this.categoria,
    required this.beneficio,
    required this.fechaHora,
    required this.lugar,
    required this.modalidadCupo,
  });
}

// Modelo que representa un edificio o punto de interes dentro del croquis del campus
class EdificioMapaUaa {
  final String codigo;
  final String nombre;
  final String zona;
  final String tramitesServicios;
  final String horarioAtencion;
  final int idCampus;
  // Coordenadas relativas (0.0 a 1.0) para ubicar el marcador en el croquis plano
  final double posX;
  final double posY;

  const EdificioMapaUaa({
    required this.codigo,
    required this.nombre,
    required this.zona,
    required this.tramitesServicios,
    required this.horarioAtencion,
    required this.idCampus,
    required this.posX,
    required this.posY,
  });
}
