import 'package:flutter/material.dart';

// Secciones o pantallas publicas navegables dentro del portal UAA
enum SeccionPortalUaa {
  inicio,
  mapaUniversitario,
  serviciosHorarios,
  transporteUniversitario,
  actividadesCreditos,
  calendarioDirectorio,
}

// Resumen diario del usuario con campos opcionales (si un campo es null no se muestra en la UI)
class ResumenDiarioUaa {
  final String? proximaClaseGrupo;
  final String? detalleProximaClase;
  final String? tareaEntregaPendiente;
  final String? detalleTareaPendiente;
  final String? adeudoPendiente;
  final String? detalleAdeudo;

  const ResumenDiarioUaa({
    this.proximaClaseGrupo,
    this.detalleProximaClase,
    this.tareaEntregaPendiente,
    this.detalleTareaPendiente,
    this.adeudoPendiente,
    this.detalleAdeudo,
  });

  // Indica si existe al menos un elemento activo para mostrar la seccion de resumen
  bool get tieneElementosActivos =>
      proximaClaseGrupo != null ||
      tareaEntregaPendiente != null ||
      adeudoPendiente != null;
}

// Modelo que representa la sesion detectada del usuario (Alumno o Profesor y su Campus)
class SesionUsuarioUaa {
  final String nombre;
  final String identificador;
  final bool esProfesor;
  final int idCampusOrigen;
  final ResumenDiarioUaa? resumenDiario;

  const SesionUsuarioUaa({
    required this.nombre,
    required this.identificador,
    required this.esProfesor,
    required this.idCampusOrigen,
    this.resumenDiario,
  });

  // Etiqueta descriptiva del rol y campus principal detectado
  String get descripcionSesion {
    final String rol = esProfesor ? 'Docente' : 'Alumno';
    final String campus =
        idCampusOrigen == 1 ? 'Campus Central' : 'Campus Sur';
    return '$rol ($campus)';
  }
}

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

// Modelo para convocatorias vigentes del mes con contador de dias restantes
class ConvocatoriaUaa {
  final String folio;
  final String titulo;
  final String descripcion;
  final String diasRestantesTexto;
  final String dirigidoA;
  final int idCampus;
  final bool urgente;

  const ConvocatoriaUaa({
    required this.folio,
    required this.titulo,
    required this.descripcion,
    required this.diasRestantesTexto,
    required this.dirigidoA,
    required this.idCampus,
    this.urgente = false,
  });
}

// Modelo para disponibilidad en tiempo real de laboratorios, cubiculos y comedor
class EspacioDisponibleUaa {
  final String nombreEspacio;
  final String ubicacion;
  final int lugaresLibres;
  final int capacidadTotal;
  final int idCampus;

  const EspacioDisponibleUaa({
    required this.nombreEspacio,
    required this.ubicacion,
    required this.lugaresLibres,
    required this.capacidadTotal,
    required this.idCampus,
  });
}

// Modelo para el menu del dia en comedores universitarios
class MenuComedorUaa {
  final String nombreComedor;
  final String platilloPrincipal;
  final String guarnicionBebida;
  final String horario;
  final String cuotaEstudiante;
  final int idCampus;

  const MenuComedorUaa({
    required this.nombreComedor,
    required this.platilloPrincipal,
    required this.guarnicionBebida,
    required this.horario,
    required this.cuotaEstudiante,
    required this.idCampus,
  });
}

// Modelo para rutas de transporte interno universitario entre campus
class RutaTransporteUaa {
  final String nombreRuta;
  final String paraderoOrigen;
  final String paraderoDestino;
  final String proximaSalida;
  final String frecuencia;
  final String estadoRuta;

  const RutaTransporteUaa({
    required this.nombreRuta,
    required this.paraderoOrigen,
    required this.paraderoDestino,
    required this.proximaSalida,
    required this.frecuencia,
    required this.estadoRuta,
  });
}

// Modelo para la guia rapida paso a paso de tramites frecuentes (FAQ)
class GuiaTramiteFaqUaa {
  final String pregunta;
  final String edificioResponsable;
  final List<String> pasos;

  const GuiaTramiteFaqUaa({
    required this.pregunta,
    required this.edificioResponsable,
    required this.pasos,
  });
}

// Modelo que representa un servicio fisico o digital disponible en el campus
class ServicioCampusUaa {
  final String nombre;
  final String ubicacion;
  final String horario;
  final String estadoActual;
  final String descripcion;
  final String telefonoExtension;
  final int idCampus;
  final IconData icono;

  const ServicioCampusUaa({
    required this.nombre,
    required this.ubicacion,
    required this.horario,
    required this.estadoActual,
    required this.descripcion,
    required this.telefonoExtension,
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
  final int idCampus;

  const ActividadUniversitaria({
    required this.titulo,
    required this.categoria,
    required this.beneficio,
    required this.fechaHora,
    required this.lugar,
    required this.modalidadCupo,
    required this.idCampus,
  });
}

// Coordenada normalizada (0.0 a 1.0) de un vertice poligonal dentro del plano oficial UAA
class PuntoMapaUaa {
  final double x;
  final double y;

  const PuntoMapaUaa(this.x, this.y);
}

// Modelo que representa un edificio o acceso individual dentro del mapa oficial de la UAA
class EdificioMapaUaa {
  final String idNodo;
  final String codigo;
  final String nombre;
  final String zona;
  final String tramitesServicios;
  final String salonesReferencia;
  final String horarioAtencion;
  final int idCampus;
  final double posX;
  final double posY;
  final bool esPuntoPartidaFrecuente;
  final List<PuntoMapaUaa> poligono;

  const EdificioMapaUaa({
    this.idNodo = '',
    required this.codigo,
    required this.nombre,
    required this.zona,
    required this.tramitesServicios,
    this.salonesReferencia = '',
    required this.horarioAtencion,
    required this.idCampus,
    required this.posX,
    required this.posY,
    this.esPuntoPartidaFrecuente = false,
    this.poligono = const <PuntoMapaUaa>[],
  });
}

// Nodo del grafo peatonal del campus (puede ser un edificio o una interseccion de andador)
class NodoPasilloUaa {
  final String id;
  final String etiqueta;
  final double posX;
  final double posY;
  final List<String> conectadosCon;

  const NodoPasilloUaa({
    required this.id,
    required this.etiqueta,
    required this.posX,
    required this.posY,
    required this.conectadosCon,
  });
}

// Resultado del calculo de ruta peatonal mas corta entre origen y destino
class RutaPeatonalUaa {
  final EdificioMapaUaa origen;
  final EdificioMapaUaa destino;
  final List<NodoPasilloUaa> puntosTrayecto;
  final int distanciaMetros;
  final int tiempoMinutos;
  final List<String> indicacionesPasoAPaso;

  const RutaPeatonalUaa({
    required this.origen,
    required this.destino,
    required this.puntosTrayecto,
    required this.distanciaMetros,
    required this.tiempoMinutos,
    required this.indicacionesPasoAPaso,
  });
}

// Modelo que representa un Centro Academico en el directorio institucional
class CentroAcademicoUaa {
  final String siglas;
  final String nombre;
  final String decanatoEdificio;
  final String extensionTelefonica;
  final int idCampus;

  const CentroAcademicoUaa({
    required this.siglas,
    required this.nombre,
    required this.decanatoEdificio,
    required this.extensionTelefonica,
    required this.idCampus,
  });
}
