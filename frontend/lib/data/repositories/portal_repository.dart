import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/aviso_institucional.dart';
import '../../domain/entities/campus_info.dart';
import '../../domain/entities/evento_calendario.dart';
import '../../domain/entities/portal_models.dart';

// Repositorio de datos publicos y herramientas para alumnos y docentes del portal UAA
class PortalRepository {
  // Constructor constante del repositorio
  const PortalRepository();

  // Devuelve los campus configurados en la universidad
  List<CampusInfo> obtenerCampusActivos() {
    return const <CampusInfo>[
      CampusInfo(
        idCampus: 1,
        nombre: 'Campus Central (Ciudad Universitaria)',
        ubicacion: 'Av. Universidad #940, C.P. 20100, Aguascalientes, Ags.',
        nodoBaseDatos: 'Campus Central',
        activo: true,
      ),
      CampusInfo(
        idCampus: 2,
        nombre: 'Campus Sur',
        ubicacion: 'Blvd. Jose Maria Chavez, Zona Sur, Aguascalientes, Ags.',
        nodoBaseDatos: 'Campus Sur',
        activo: true,
      ),
    ];
  }

  // Devuelve las noticias y diapositivas del carrusel hero con imagenes de la UAA
  List<AvisoInstitucional> obtenerAvisos({int? idCampusFiltro}) {
    final List<AvisoInstitucional> avisos = <AvisoInstitucional>[
      AvisoInstitucional(
        idAviso: 'BOLETIN-546',
        titulo: 'Comunidad Universitaria UAA: Excelencia Academica 2026-2',
        resumen:
            'Consulta convocatorias, servicios estudiantiles y actividades academicas en Ciudad Universitaria y Campus Sur.',
        idCampus: 1,
        fechaPublicacion: '14 Nov 2026',
        categoria: 'Vida Universitaria',
        imagenAsset: AppConstants.campusHeroImages[0],
      ),
      AvisoInstitucional(
        idAviso: 'AVISO-547',
        titulo: 'Periodo Abierto de Inscripciones y Reinscripciones E-SIIMA',
        resumen:
            'Realiza tu seleccion de materias y consulta de horarios de manera agil desde el portal institucional.',
        idCampus: 1,
        fechaPublicacion: '16 Nov 2026',
        categoria: 'Control Escolar',
        imagenAsset: AppConstants.campusHeroImages[1],
      ),
      AvisoInstitucional(
        idAviso: 'BOLETIN-548',
        titulo: 'Infraestructura y Espacios Universitarios para tu Formacion',
        resumen:
            'Bibliotecas, laboratorios y aulas equipadas al servicio de los estudiantes de pregrado y posgrado.',
        idCampus: 2,
        fechaPublicacion: '18 Nov 2026',
        categoria: 'Campus UAA',
        imagenAsset: AppConstants.campusHeroImages[2],
      ),
      AvisoInstitucional(
        idAviso: 'AVISO-549',
        titulo: 'Orgullo e Identidad Gallos UAA - Se Lumen Proferre',
        resumen:
            'Participa en los encuentros culturales, deportivos y muestras departamentales de cierre de semestre.',
        idCampus: 1,
        fechaPublicacion: '20 Nov 2026',
        categoria: 'Identidad UAA',
        imagenAsset: AppConstants.campusHeroImages[3],
      ),
      AvisoInstitucional(
        idAviso: 'AVISO-550',
        titulo: 'Aula Virtual: Entrega de Proyectos y Evaluacion Continua',
        resumen:
            'Envia tus tareas y proyectos integradores y consulta la retroalimentacion directa de tus profesores.',
        idCampus: 2,
        fechaPublicacion: '22 Nov 2026',
        categoria: 'Aula Virtual',
        imagenAsset: AppConstants.campusHeroImages[4],
      ),
      AvisoInstitucional(
        idAviso: 'BOLETIN-551',
        titulo: 'Consulta de Calificaciones y Ventanilla Digital de Pagos',
        resumen:
            'Revisa tu kardex actualizado y genera tus recibos de pago de colegiatura en linea las 24 horas.',
        idCampus: 2,
        fechaPublicacion: '23 Nov 2026',
        categoria: 'Servicios Digitales',
        imagenAsset: AppConstants.campusHeroImages[5],
      ),
    ];

    if (idCampusFiltro == null) {
      return avisos;
    }
    return avisos
        .where((AvisoInstitucional a) => a.idCampus == idCampusFiltro)
        .toList();
  }

  // Devuelve los eventos y fechas clave del calendario academico 2026-2
  List<EventoCalendario> obtenerCalendarioEscolar() {
    return const <EventoCalendario>[
      EventoCalendario(
        mesAbreviado: 'NOV',
        diaNumero: '14',
        evento: 'Apertura de Inscripciones y Reinscripciones 2026-2',
        ubicacion: 'Portal E-SIIMA (Campus Central y Campus Sur)',
        fechaCompleta: '14 Nov 2026',
      ),
      EventoCalendario(
        mesAbreviado: 'NOV',
        diaNumero: '23',
        evento: 'Muestra Departamental y Evaluacion Continua en Aula Virtual',
        ubicacion: 'Aulas Virtuales de Educacion Superior',
        fechaCompleta: '23 Nov 2026',
      ),
      EventoCalendario(
        mesAbreviado: 'DIC',
        diaNumero: '04',
        evento: 'Cierre Oficial de Entregas de Proyectos Integradores',
        ubicacion: 'Plataforma Academica E-SIIMA UAA',
        fechaCompleta: '04 Dic 2026',
      ),
      EventoCalendario(
        mesAbreviado: 'DIC',
        diaNumero: '11',
        evento: 'Fin de Cursos y Publicacion de Actas de Calificaciones',
        ubicacion: 'Departamento de Control Escolar UAA',
        fechaCompleta: '11 Dic 2026',
      ),
    ];
  }

  // Devuelve las herramientas rapidas segun el perfil seleccionado (Alumno o Profesor)
  List<AccionPerfilUaa> obtenerAccionesPorPerfil({required bool esProfesor}) {
    if (esProfesor) {
      return const <AccionPerfilUaa>[
        AccionPerfilUaa(
          titulo: 'Publicar Tarea o Aviso',
          descripcion: 'Asigna actividades con fecha limite y ponderacion a tus grupos.',
          etiquetaModulo: 'Aula Virtual Docente',
          icono: Icons.post_add_outlined,
        ),
        AccionPerfilUaa(
          titulo: 'Revisar Entregas Recibidas',
          descripcion: 'Evalua trabajos enviados por alumnos y redacta retroalimentacion.',
          etiquetaModulo: 'Evaluacion',
          icono: Icons.fact_check_outlined,
        ),
        AccionPerfilUaa(
          titulo: 'Capturar Calificaciones de Acta',
          descripcion: 'Registra evaluaciones parciales y finales en el sistema E-SIIMA.',
          etiquetaModulo: 'E-SIIMA Docente',
          icono: Icons.grading_outlined,
        ),
        AccionPerfilUaa(
          titulo: 'Listas de Grupo y Asistencia',
          descripcion: 'Consulta los alumnos inscritos en tus asignaturas por campus.',
          etiquetaModulo: 'Control Escolar',
          icono: Icons.groups_outlined,
        ),
        AccionPerfilUaa(
          titulo: 'Reservar Laboratorio o Auditorio',
          descripcion: 'Verifica disponibilidad de salas de computo y espacios academicos.',
          etiquetaModulo: 'Servicios Docentes',
          icono: Icons.meeting_room_outlined,
        ),
      ];
    }

    return const <AccionPerfilUaa>[
      AccionPerfilUaa(
        titulo: 'Subir Tarea en Aula Virtual',
        descripcion: 'Consulta tus entregas pendientes y envia tus archivos a tiempo.',
        etiquetaModulo: 'Aula Virtual',
        icono: Icons.upload_file_outlined,
      ),
      AccionPerfilUaa(
        titulo: 'Mi Horario y Materias',
        descripcion: 'Revisa tus clases inscritas, aulas asignadas y profesores.',
        etiquetaModulo: 'E-SIIMA Alumno',
        icono: Icons.schedule_outlined,
      ),
      AccionPerfilUaa(
        titulo: 'Kardex y Calificaciones',
        descripcion: 'Consulta tus notas parciales, promedio general y comentarios.',
        etiquetaModulo: 'Evaluacion',
        icono: Icons.school_outlined,
      ),
      AccionPerfilUaa(
        titulo: 'Inscripcion y Carga Academica',
        descripcion: 'Selecciona grupos disponibles en tu campus en tiempo real.',
        etiquetaModulo: 'Inscripciones',
        icono: Icons.how_to_reg_outlined,
      ),
      AccionPerfilUaa(
        titulo: 'Pagar Colegiatura en Linea',
        descripcion: 'Genera tu linea de captura o realiza tu pago por referencia.',
        etiquetaModulo: 'Finanzas',
        icono: Icons.account_balance_wallet_outlined,
      ),
    ];
  }

  // Devuelve el directorio de servicios universitarios con horarios y ubicacion
  List<ServicioCampusUaa> obtenerServiciosCampus({int? idCampusFiltro}) {
    const List<ServicioCampusUaa> servicios = <ServicioCampusUaa>[
      ServicioCampusUaa(
        nombre: 'Bibliotecas y Centro de Informacion',
        ubicacion: 'Edificio 56 (Central) / Biblioteca Campus Sur',
        horario: 'Lunes a Viernes: 07:00 - 21:00 hrs | Sabados: 08:00 - 14:00 hrs',
        estadoActual: 'Abierto - Salas disponibles',
        descripcion:
            'Prestamo de acervo bibliografico, cubiculos de estudio grupal y acceso a bases de datos cientificas.',
        idCampus: 1,
        icono: Icons.local_library_outlined,
      ),
      ServicioCampusUaa(
        nombre: 'Cajas y Departamento de Finanzas',
        ubicacion: 'Edificio Academico Administrativo (Planta Baja, Edificio 1-A)',
        horario: 'Ventanilla: 08:00 - 15:30 hrs | Portal en linea: 24/7',
        estadoActual: 'Abierto - Pago digital 24/7',
        descripcion:
            'Recepcion de pagos de matricula, colegiatura mensual, constancias y derechos de examen.',
        idCampus: 1,
        icono: Icons.payments_outlined,
      ),
      ServicioCampusUaa(
        nombre: 'Control Escolar y Credencializacion',
        ubicacion: 'Edificio 1-A (Ciudad Universitaria) / Modulo Administrativo Sur',
        horario: 'Lunes a Viernes: 08:00 - 15:30 hrs',
        estadoActual: 'Abierto',
        descripcion:
            'Emision de constancias de estudios, reposicion de credencial inteligente, altas y bajas.',
        idCampus: 1,
        icono: Icons.badge_outlined,
      ),
      ServicioCampusUaa(
        nombre: 'Unidad Medico Didactica (UMD)',
        ubicacion: 'Edificio 101, Zona Norte de Ciudad Universitaria',
        horario: 'Lunes a Viernes: 07:30 - 20:00 hrs',
        estadoActual: 'Atencion activa',
        descripcion:
            'Consultas medicas generales, optometria, estomatologia, nutricion y apoyo psicologico estudiantil.',
        idCampus: 1,
        icono: Icons.medical_services_outlined,
      ),
      ServicioCampusUaa(
        nombre: 'CAADI y Laboratorios de Computo',
        ubicacion: 'Edificio 211 (CAADI Central) / Laboratorios Edificio B Sur',
        horario: 'Lunes a Viernes: 07:00 - 20:00 hrs',
        estadoActual: 'Equipos disponibles',
        descripcion:
            'Centro de Aprendizaje Autodirigido de Idiomas, asesorias de ingles y salas de computo de alto rendimiento.',
        idCampus: 2,
        icono: Icons.computer_outlined,
      ),
      ServicioCampusUaa(
        nombre: 'Transporte Interno, Becas y Movilidad',
        ubicacion: 'Edificio 1-A Piso 3 / Paraderos Campus Central y Campus Sur',
        horario: 'Rutas: 06:45 - 21:15 hrs | Oficinas: 08:00 - 15:30 hrs',
        estadoActual: 'En operacion',
        descripcion:
            'Conexion de transporte universitario entre campus, tramites de beca institucional y apoyo alimenticio.',
        idCampus: 2,
        icono: Icons.directions_bus_outlined,
      ),
    ];

    if (idCampusFiltro == null) {
      return servicios;
    }
    return servicios
        .where((ServicioCampusUaa s) => s.idCampus == idCampusFiltro)
        .toList();
  }

  // Devuelve la cartelera de actividades de creditos humanisticos, deportes y talleres
  List<ActividadUniversitaria> obtenerActividades({String? categoriaFiltro}) {
    const List<ActividadUniversitaria> actividades = <ActividadUniversitaria>[
      ActividadUniversitaria(
        titulo: 'Conferencia: Etica e Inteligencia Artificial en la Educacion Superior',
        categoria: 'Formacion Humanistica',
        beneficio: 'Otorga 1 Credito Humanistico',
        fechaHora: '26 Nov 2026 - 12:00 hrs',
        lugar: 'Auditorio Dr. Pedro de Alba (Campus Central)',
        modalidadCupo: 'Presencial - Registro con credencial UAA',
      ),
      ActividadUniversitaria(
        titulo: 'Torneo Interno Intercentros Gallos UAA (Futbol, Basquetbol y Voleibol)',
        categoria: 'Deportes y Cultura',
        beneficio: 'Acredita Actividad Deportiva',
        fechaHora: '28 Nov 2026 - 09:00 hrs',
        lugar: 'Unidad Deportiva Universitaria y Poliforum',
        modalidadCupo: 'Presencial - Convocatoria abierta',
      ),
      ActividadUniversitaria(
        titulo: 'Taller Practico: Sistemas Distribuidos, Docker y Bases de Datos',
        categoria: 'Talleres y Congresos',
        beneficio: 'Constancia con Valor Curricular',
        fechaHora: '30 Nov 2026 - 16:00 hrs',
        lugar: 'Sala Audiovisual Campus Sur / Transmision simultanea',
        modalidadCupo: 'Hibrido - Cupo para 80 participantes',
      ),
      ActividadUniversitaria(
        titulo: 'Concierto de Fin de Semestre: Polifonia Universitaria y Ensamble UAA',
        categoria: 'Formacion Humanistica',
        beneficio: 'Otorga 1 Credito Humanistico',
        fechaHora: '02 Dic 2026 - 18:00 hrs',
        lugar: 'Auditorio Ignacio T. Chavez',
        modalidadCupo: 'Presencial - Entrada libre con matricula',
      ),
      ActividadUniversitaria(
        titulo: 'Curso Docente: Evaluacion por Rubricas y Gestion de Aula Virtual',
        categoria: 'Apoyo Docente',
        beneficio: 'Acreditacion PRODEP / Formacion Docente',
        fechaHora: '03 Dic 2026 - 10:00 hrs',
        lugar: 'Aula Digital Edificio Academico Administrativo',
        modalidadCupo: 'Para profesores de todos los Centros',
      ),
      ActividadUniversitaria(
        titulo: 'Muestra Emprendedora y Proyectos Integradores de Ingenieria',
        categoria: 'Talleres y Congresos',
        beneficio: 'Constancia de Participacion',
        fechaHora: '04 Dic 2026 - 10:00 a 14:00 hrs',
        lugar: 'Explanada Principal y Aulas de Campus Sur',
        modalidadCupo: 'Presencial - Evaluacion final de proyectos',
      ),
    ];

    if (categoriaFiltro == null || categoriaFiltro == 'Todas') {
      return actividades;
    }
    return actividades
        .where((ActividadUniversitaria a) => a.categoria == categoriaFiltro)
        .toList();
  }

  // Devuelve los edificios y puntos clave para el croquis interactivo del campus
  List<EdificioMapaUaa> obtenerEdificiosMapa({required int idCampus}) {
    const List<EdificioMapaUaa> edificios = <EdificioMapaUaa>[
      // Campus Central (idCampus = 1)
      EdificioMapaUaa(
        codigo: 'EDIF 1-A',
        nombre: 'Torre Academico Administrativa (Rectoria y Cajas)',
        zona: 'Zona Administrativa Sur-Central',
        tramitesServicios:
            'Cajas, Control Escolar, Becas, Credenciales y Direccion General de Pregrado.',
        horarioAtencion: '08:00 - 15:30 hrs',
        idCampus: 1,
        posX: 0.25,
        posY: 0.72,
      ),
      EdificioMapaUaa(
        codigo: 'EDIF 56',
        nombre: 'Biblioteca Central Dr. Desiderio Macias Silva',
        zona: 'Zona Central Academica',
        tramitesServicios:
            'Acervo general, hemeroteca, cubiculos de estudio y prestamo de equipos.',
        horarioAtencion: '07:00 - 21:00 hrs',
        idCampus: 1,
        posX: 0.48,
        posY: 0.46,
      ),
      EdificioMapaUaa(
        codigo: 'EDIF 14',
        nombre: 'Auditorio Dr. Pedro de Alba y Aulas Magnas',
        zona: 'Zona Central Cultural',
        tramitesServicios:
            'Eventos de creditos humanisticos, congresos, ceremonias y conferencias.',
        horarioAtencion: '08:00 - 20:00 hrs',
        idCampus: 1,
        posX: 0.36,
        posY: 0.54,
      ),
      EdificioMapaUaa(
        codigo: 'EDIF 60',
        nombre: 'Centro de Ciencias Basicas y Laboratorios de Computo',
        zona: 'Zona Norte Ingenierias',
        tramitesServicios:
            'Laboratorios de sistemas, redes, electronica, aulas de ingenieria y cubiculos docentes.',
        horarioAtencion: '07:00 - 21:00 hrs',
        idCampus: 1,
        posX: 0.65,
        posY: 0.28,
      ),
      EdificioMapaUaa(
        codigo: 'EDIF 101',
        nombre: 'Unidad Medico Didactica (UMD)',
        zona: 'Zona Norte Salud',
        tramitesServicios:
            'Consultorio medico estudiantil, primeros auxilios, estomatologia y optometria.',
        horarioAtencion: '07:30 - 20:00 hrs',
        idCampus: 1,
        posX: 0.78,
        posY: 0.22,
      ),
      EdificioMapaUaa(
        codigo: 'EDIF 211',
        nombre: 'CAADI e Idiomas / Poliforum Universitario',
        zona: 'Zona Oriente Servicios',
        tramitesServicios:
            'Laboratorio de idiomas, autoacceso, comedor universitario y libreria UAA.',
        horarioAtencion: '07:00 - 20:00 hrs',
        idCampus: 1,
        posX: 0.72,
        posY: 0.66,
      ),
      // Campus Sur (idCampus = 2)
      EdificioMapaUaa(
        codigo: 'SUR-A',
        nombre: 'Edificio A - Aulas y Coordinacion Campus Sur',
        zona: 'Acceso Principal Blvd. Jose Maria Chavez',
        tramitesServicios:
            'Ventanilla de Control Escolar Sur, coordinacion academica y aulas multimedia.',
        horarioAtencion: '07:00 - 21:00 hrs',
        idCampus: 2,
        posX: 0.28,
        posY: 0.58,
      ),
      EdificioMapaUaa(
        codigo: 'SUR-B',
        nombre: 'Edificio B - Laboratorios de Computo e Ingenieria',
        zona: 'Zona Central Campus Sur',
        tramitesServicios:
            'Salas de desarrollo de software, servidores, redes, robotica y tutorias.',
        horarioAtencion: '07:00 - 21:00 hrs',
        idCampus: 2,
        posX: 0.52,
        posY: 0.42,
      ),
      EdificioMapaUaa(
        codigo: 'SUR-BIB',
        nombre: 'Biblioteca y CAADI Campus Sur',
        zona: 'Zona Oriente Campus Sur',
        tramitesServicios:
            'Salas de lectura, prestamo de libros, computadoras de consulta e idiomas.',
        horarioAtencion: '07:30 - 20:30 hrs',
        idCampus: 2,
        posX: 0.74,
        posY: 0.35,
      ),
      EdificioMapaUaa(
        codigo: 'SUR-AUD',
        nombre: 'Auditorio Polivalente y Cafeteria Campus Sur',
        zona: 'Zona Norte Campus Sur',
        tramitesServicios:
            'Exposicion de proyectos integradores, conferencias, comedor y paradero de camion UAA.',
        horarioAtencion: '07:30 - 20:00 hrs',
        idCampus: 2,
        posX: 0.64,
        posY: 0.72,
      ),
    ];

    return edificios
        .where((EdificioMapaUaa e) => e.idCampus == idCampus)
        .toList();
  }
}
