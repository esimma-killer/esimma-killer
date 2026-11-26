import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/aviso_institucional.dart';
import '../../domain/entities/campus_info.dart';
import '../../domain/entities/evento_calendario.dart';
import '../../domain/entities/portal_models.dart';
import 'campus_map_data.dart';

// Repositorio de datos publicos y herramientas para alumnos y docentes del portal UAA
class PortalRepository {
  // Constructor constante del repositorio
  const PortalRepository();

  // Perfiles de sesion para probar deteccion de rol, campus y ocultamiento de campos null
  List<SesionUsuarioUaa> obtenerPerfilesPrueba() {
    return const <SesionUsuarioUaa>[
      // Perfil 1: Alumno sin adeudos (adeudoPendiente es null, por lo que no se muestra tarjeta de adeudo)
      SesionUsuarioUaa(
        nombre: 'Angel Azael Fajardo Espino',
        identificador: 'ID 284510',
        esProfesor: false,
        idCampusOrigen: 1,
        resumenDiario: ResumenDiarioUaa(
          proximaClaseGrupo: '16:00 hrs - Bases de Datos Distribuidas',
          detalleProximaClase: 'Edificio 60, Aula 204 (Campus Central)',
          tareaEntregaPendiente: 'Entrega 3 Proyecto Integrador E-SIIMA',
          detalleTareaPendiente: 'Vence manana 23:59 hrs en Aula Virtual',
          adeudoPendiente: null,
          detalleAdeudo: null,
        ),
      ),
      // Perfil 2: Alumno de Campus Sur con adeudo pendiente y tarea activa
      SesionUsuarioUaa(
        nombre: 'Alumno Campus Sur',
        identificador: 'ID 291044',
        esProfesor: false,
        idCampusOrigen: 2,
        resumenDiario: ResumenDiarioUaa(
          proximaClaseGrupo: '15:00 hrs - Arquitectura de Software',
          detalleProximaClase: 'Edificio B, Laboratorio 3 (Campus Sur)',
          tareaEntregaPendiente: 'Reporte de Pruebas Unitarias Pytest',
          detalleTareaPendiente: 'Vence hoy a las 22:00 hrs en Aula Virtual',
          adeudoPendiente: 'Colegiatura Mensual Noviembre 2026',
          detalleAdeudo:
              'Pagar en linea o en Cajas Edificio 1-A antes del 30 Nov',
        ),
      ),
      // Perfil 3: Docente UAA (sin adeudos, con grupo y revisiones pendientes)
      SesionUsuarioUaa(
        nombre: 'Dr. David Montoya',
        identificador: 'EMP 10482',
        esProfesor: true,
        idCampusOrigen: 1,
        resumenDiario: ResumenDiarioUaa(
          proximaClaseGrupo: '16:00 hrs - Grupo 7A Ingenieria en Computacion',
          detalleProximaClase: 'Edificio 60, Laboratorio de Redes (32 alumnos)',
          tareaEntregaPendiente: '14 Entregas nuevas recibidas por calificar',
          detalleTareaPendiente:
              'Materia: Sistemas Distribuidos (Aula Virtual)',
          adeudoPendiente: null,
          detalleAdeudo: null,
        ),
      ),
      // Perfil 4: Alumno libre de pendientes (todo null -> la seccion completa de resumen no se muestra)
      SesionUsuarioUaa(
        nombre: 'Alumno sin Pendientes',
        identificador: 'ID 279301',
        esProfesor: false,
        idCampusOrigen: 1,
        resumenDiario: null,
      ),
    ];
  }

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

  // Devuelve las noticias y diapositivas del carrusel hero ordenadas o filtradas por campus
  List<AvisoInstitucional> obtenerAvisos({int? idCampusFiltro}) {
    final List<AvisoInstitucional> avisos = <AvisoInstitucional>[
      AvisoInstitucional(
        idAviso: 'BOLETIN-546',
        titulo: 'Comunidad Universitaria UAA: Excelencia Academica 2026-2',
        resumen: 'Consulta convocatorias, servicios estudiantiles y actividades academicas en Ciudad Universitaria y Campus Sur.',
        idCampus: 1,
        fechaPublicacion: '14 Nov 2026',
        categoria: 'Vida Universitaria',
        imagenAsset: AppConstants.campusHeroImages[0],
      ),
      AvisoInstitucional(
        idAviso: 'AVISO-547',
        titulo: 'Periodo Abierto de Inscripciones y Reinscripciones E-SIIMA',
        resumen: 'Realiza tu seleccion de materias y consulta de horarios de manera agil desde el portal institucional.',
        idCampus: 1,
        fechaPublicacion: '16 Nov 2026',
        categoria: 'Control Escolar',
        imagenAsset: AppConstants.campusHeroImages[1],
      ),
      AvisoInstitucional(
        idAviso: 'BOLETIN-548',
        titulo:
            'Infraestructura y Laboratorios en Campus Sur para tu Formacion',
        resumen: 'Bibliotecas, laboratorios de ingenieria y aulas equipadas al servicio de los estudiantes de Campus Sur.',
        idCampus: 2,
        fechaPublicacion: '18 Nov 2026',
        categoria: 'Campus Sur',
        imagenAsset: AppConstants.campusHeroImages[2],
      ),
      AvisoInstitucional(
        idAviso: 'AVISO-549',
        titulo: 'Orgullo e Identidad Gallos UAA - Se Lumen Proferre',
        resumen: 'Participa en los encuentros culturales, deportivos y muestras departamentales de cierre de semestre.',
        idCampus: 1,
        fechaPublicacion: '20 Nov 2026',
        categoria: 'Identidad UAA',
        imagenAsset: AppConstants.campusHeroImages[3],
      ),
      AvisoInstitucional(
        idAviso: 'AVISO-550',
        titulo: 'Aula Virtual: Entrega de Proyectos y Evaluacion Continua',
        resumen: 'Envia tus tareas y proyectos integradores y consulta la retroalimentacion directa de tus profesores.',
        idCampus: 2,
        fechaPublicacion: '22 Nov 2026',
        categoria: 'Aula Virtual',
        imagenAsset: AppConstants.campusHeroImages[4],
      ),
      AvisoInstitucional(
        idAviso: 'BOLETIN-551',
        titulo: 'Consulta de Calificaciones y Ventanilla Digital de Pagos',
        resumen: 'Revisa tu kardex actualizado y genera tus recibos de pago de colegiatura en linea las 24 horas.',
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

  // Devuelve las convocatorias vigentes del mes para la Pagina Principal
  List<ConvocatoriaUaa> obtenerConvocatoriasVigentes({
    required bool esProfesor,
    int? idCampusFiltro,
  }) {
    const List<ConvocatoriaUaa> todas = <ConvocatoriaUaa>[
      ConvocatoriaUaa(
        folio: 'CONV-BECA-2026',
        titulo: 'Beca Institucional de Excelencia y Apoyo Economico',
        descripcion: 'Recepcion de solicitudes y estudio socioeconomico para descuento de colegiatura del semestre 2026-2.',
        diasRestantesTexto: 'Cierra en 5 dias',
        dirigidoA: 'Alumnos',
        idCampus: 1,
        urgente: true,
      ),
      ConvocatoriaUaa(
        folio: 'CONV-CAADI-09',
        titulo: 'Inscripcion a Cursos de Idiomas y Examen de Colocacion',
        descripcion: 'Registro abierto para ingles, frances, aleman y japones con acreditacion del requisito de titulacion.',
        diasRestantesTexto: 'Cierra en 8 dias',
        dirigidoA: 'Alumnos',
        idCampus: 2,
      ),
      ConvocatoriaUaa(
        folio: 'CONV-SS-2026',
        titulo: 'Registro de Proyectos de Servicio Social y Practicas Profesionales',
        descripcion: 'Selecciona unidades receptoras internas o en empresas conveniadas para liberar horas reglamentarias.',
        diasRestantesTexto: 'Cierra el 30 Nov',
        dirigidoA: 'Alumnos',
        idCampus: 1,
      ),
      ConvocatoriaUaa(
        folio: 'CONV-DOC-14',
        titulo:
            'Fondo de Apoyo a la Investigacion y Estancias Academicas Docentes',
        descripcion: 'Registro de protocolos de investigacion interdisciplinaria y renovacion de perfil PRODEP.',
        diasRestantesTexto: 'Abierta hasta 10 Dic',
        dirigidoA: 'Docentes',
        idCampus: 1,
      ),
    ];

    return todas.where((ConvocatoriaUaa c) {
      if (esProfesor && c.dirigidoA == 'Alumnos' && c.folio == 'CONV-SS-2026') {
        return false;
      }
      if (idCampusFiltro != null && c.idCampus != idCampusFiltro) {
        return true; // Las convocatorias aplican institucionalmente aunque destaquen sede
      }
      return true;
    }).toList();
  }

  // Devuelve la ocupacion en tiempo real de laboratorios y salas de estudio para la Pagina Principal
  List<EspacioDisponibleUaa> obtenerEspaciosDisponibles({int? idCampusFiltro}) {
    const List<EspacioDisponibleUaa> espacios = <EspacioDisponibleUaa>[
      EspacioDisponibleUaa(
        nombreEspacio: 'Salas de Computo Edificio 60 (Sistemas)',
        ubicacion: 'Campus Central - Planta Alta',
        lugaresLibres: 28,
        capacidadTotal: 60,
        idCampus: 1,
      ),
      EspacioDisponibleUaa(
        nombreEspacio: 'Cubiculos de Estudio Grupal Biblioteca Central',
        ubicacion: 'Campus Central - Edificio 56 Piso 2',
        lugaresLibres: 6,
        capacidadTotal: 16,
        idCampus: 1,
      ),
      EspacioDisponibleUaa(
        nombreEspacio: 'Laboratorio de Desarrollo y Redes Edificio B',
        ubicacion: 'Campus Sur - Sala B-104',
        lugaresLibres: 19,
        capacidadTotal: 40,
        idCampus: 2,
      ),
      EspacioDisponibleUaa(
        nombreEspacio: 'Sala de Autoacceso CAADI Idiomas',
        ubicacion: 'Edificio 211 Central / Biblioteca Sur',
        lugaresLibres: 22,
        capacidadTotal: 45,
        idCampus: 2,
      ),
    ];

    if (idCampusFiltro == null) {
      return espacios;
    }
    return espacios
        .where((EspacioDisponibleUaa e) => e.idCampus == idCampusFiltro)
        .toList();
  }

  // Devuelve el menu del dia de los comedores universitarios para la Pagina Principal
  List<MenuComedorUaa> obtenerMenusComedor({int? idCampusFiltro}) {
    const List<MenuComedorUaa> menus = <MenuComedorUaa>[
      MenuComedorUaa(
        nombreComedor: 'Comedor Universitario Poliforum (Campus Central)',
        platilloPrincipal:
            'Pechuga asada a las finas hierbas o Enchiladas verdes',
        guarnicionBebida:
            'Sopa del dia, arroz, ensalada fresca, agua de jamaica y postre',
        horario: '12:00 a 16:30 hrs',
        cuotaEstudiante: 'Subsidio con credencial UAA',
        idCampus: 1,
      ),
      MenuComedorUaa(
        nombreComedor: 'Cafeteria y Comedor Universitario Campus Sur',
        platilloPrincipal: 'Fajitas de res con pimientos o Milanesa de pollo',
        guarnicionBebida:
            'Crema de verduras, frijoles de la olla, agua de limon y fruta',
        horario: '11:30 a 16:30 hrs',
        cuotaEstudiante: 'Subsidio con credencial UAA',
        idCampus: 2,
      ),
    ];

    if (idCampusFiltro == null) {
      return menus;
    }
    return menus
        .where((MenuComedorUaa m) => m.idCampus == idCampusFiltro)
        .toList();
  }

  // Devuelve el monitor de rutas de transporte universitario entre campus (Pestana Servicios)
  List<RutaTransporteUaa> obtenerRutasTransporte() {
    return const <RutaTransporteUaa>[
      RutaTransporteUaa(
        nombreRuta: 'Ruta Expres Intercampus: Central -> Campus Sur',
        paraderoOrigen: 'Paradero Poliforum / Av. Universidad #940',
        paraderoDestino:
            'Acceso Principal Campus Sur (Blvd. Jose Maria Chavez)',
        proximaSalida: 'Sale en 12 min (15:30 hrs)',
        frecuencia: 'Salidas cada 30 minutos',
        estadoRuta: 'En tiempo',
      ),
      RutaTransporteUaa(
        nombreRuta: 'Ruta Expres Intercampus: Campus Sur -> Central',
        paraderoOrigen: 'Explanada Edificio A (Campus Sur)',
        paraderoDestino: 'Glorieta y Edificio 1-A Ciudad Universitaria',
        proximaSalida: 'Sale en 18 min (15:35 hrs)',
        frecuencia: 'Salidas cada 30 minutos',
        estadoRuta: 'En tiempo',
      ),
      RutaTransporteUaa(
        nombreRuta: 'Circuito Interno Ciudad Universitaria (Norte - Sur)',
        paraderoOrigen: 'Acceso Av. Guadalupe Gonzalez (Zona Norte UMD)',
        paraderoDestino: 'Torre Academico Administrativa Edificio 1-A',
        proximaSalida: 'Circulacion continua',
        frecuencia: 'Paso cada 15 minutos',
        estadoRuta: 'Activa',
      ),
    ];
  }

  // Devuelve la guia paso a paso de tramites frecuentes (Pestana Calendario y Tramites)
  List<GuiaTramiteFaqUaa> obtenerGuiasTramitesFaq() {
    return const <GuiaTramiteFaqUaa>[
      GuiaTramiteFaqUaa(
        pregunta:
            'Como justifico inasistencias por consulta medica o enfermedad?',
        edificioResponsable:
            'Unidad Medico Didactica (Edificio 101) y Decanato',
        pasos: <String>[
          '1. Acude a valoracion o valida tu receta en la Unidad Medico Didactica (Edif. 101) dentro de las 48 horas posteriores.',
          '2. Solicita el formato sellado de incapacidad medica estudiantil con tu matricula.',
          '3. Entregalo en la secretaria de tu Decanato para que se notifique oficialmente a tus profesores en lista.',
        ],
      ),
      GuiaTramiteFaqUaa(
        pregunta: 'Que hago si se agota el cupo de una materia durante mi inscripcion en E-SIIMA?',
        edificioResponsable:
            'Jefatura de Departamento Academico / Portal E-SIIMA',
        pasos: <String>[
          '1. Verifica en E-SIIMA si existe otro grupo u horario disponible en tu campus.',
          '2. Si todos los grupos estan llenos, registra tu solicitud de sobrecupo en el modulo de Ajustes de Carga.',
          '3. La Jefatura de Departamento evaluara la apertura de lugares y veras reflejada la materia en tu horario.',
        ],
      ),
      GuiaTramiteFaqUaa(
        pregunta:
            'Como tramito una Constancia de Estudios o Kardex Oficial sellado?',
        edificioResponsable:
            'Departamento de Control Escolar (Edificio 1-A Planta Baja)',
        pasos: <String>[
          '1. Ingresa a la Ventanilla de Pagos en E-SIIMA y cubre el derecho de Constancia o Kardex.',
          '2. Descarga el documento con firma electronica QR o acude a las ventanillas del Edificio 1-A con tu credencial UAA.',
        ],
      ),
      GuiaTramiteFaqUaa(
        pregunta: 'Como acredito mis Creditos Humanisticos obligatorios antes de egresar?',
        edificioResponsable: 'Direccion General de Difusion y Vinculacion',
        pasos: <String>[
          '1. Consulta la pestana de Actividades y Creditos en este portal y elige eventos con la insignia "Otorga 1 Credito Humanistico".',
          '2. Presenta tu credencial inteligente UAA al ingresar y al salir del auditorio para registrar tu asistencia.',
          '3. Verifica el acumulado de tus creditos en tu Kardex de E-SIIMA al cierre del semestre.',
        ],
      ),
    ];
  }

  // Devuelve los eventos y fechas clave del calendario academico 2026-2
  List<EventoCalendario> obtenerCalendarioEscolar() {
    return const <EventoCalendario>[
      EventoCalendario(
        mesAbreviado: 'AGO',
        diaNumero: '10',
        evento: 'Inicio Oficial de Clases Semestre 2026-2',
        ubicacion: 'Todos los Centros Academicos (Campus Central y Sur)',
        fechaCompleta: '10 Ago 2026',
      ),
      EventoCalendario(
        mesAbreviado: 'OCT',
        diaNumero: '16',
        evento: 'Evaluaciones Parciales y Captura de Primer Periodo',
        ubicacion: 'Sistema E-SIIMA Docente y Aula Virtual',
        fechaCompleta: '16 Oct 2026',
      ),
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

  // Devuelve las herramientas rapidas exclusivamente para el rol de la sesion activa
  List<AccionPerfilUaa> obtenerAccionesPorPerfil({required bool esProfesor}) {
    if (esProfesor) {
      return const <AccionPerfilUaa>[
        AccionPerfilUaa(
          titulo: 'Publicar Tarea o Aviso',
          descripcion:
              'Asigna actividades con fecha limite y ponderacion a tus grupos.',
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
          descripcion:
              'Consulta los alumnos inscritos en tus asignaturas por campus.',
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
        descripcion:
            'Consulta tus entregas pendientes y envia tus archivos a tiempo.',
        etiquetaModulo: 'Aula Virtual',
        icono: Icons.upload_file_outlined,
      ),
      AccionPerfilUaa(
        titulo: 'Mi Horario y Materias',
        descripcion:
            'Revisa tus clases inscritas, aulas asignadas y profesores.',
        etiquetaModulo: 'E-SIIMA Alumno',
        icono: Icons.schedule_outlined,
      ),
      AccionPerfilUaa(
        titulo: 'Kardex y Calificaciones',
        descripcion:
            'Consulta tus notas parciales, promedio general y comentarios.',
        etiquetaModulo: 'Evaluacion',
        icono: Icons.school_outlined,
      ),
      AccionPerfilUaa(
        titulo: 'Inscripcion y Carga Academica',
        descripcion:
            'Selecciona grupos disponibles en tu campus en tiempo real.',
        etiquetaModulo: 'Inscripciones',
        icono: Icons.how_to_reg_outlined,
      ),
      AccionPerfilUaa(
        titulo: 'Pagar Colegiatura en Linea',
        descripcion:
            'Genera tu linea de captura o realiza tu pago por referencia.',
        etiquetaModulo: 'Finanzas',
        icono: Icons.account_balance_wallet_outlined,
      ),
    ];
  }

  // Devuelve el directorio de servicios universitarios con horarios y ubicacion
  List<ServicioCampusUaa> obtenerServiciosCampus({int? idCampusFiltro}) {
    const List<ServicioCampusUaa> servicios = <ServicioCampusUaa>[
      ServicioCampusUaa(
        nombre: 'Biblioteca Central Dr. Desiderio Macias Silva',
        ubicacion: 'Edificio 56, Zona Central de Ciudad Universitaria',
        horario:
            'Lunes a Viernes: 07:00 - 21:00 hrs | Sabados: 08:00 - 14:00 hrs',
        estadoActual: 'Abierto - Salas disponibles',
        descripcion: 'Prestamo de acervo bibliografico, cubiculos de estudio grupal y acceso a bases de datos cientificas.',
        telefonoExtension: 'Tel. 449 910 74 00 Ext. 5610',
        idCampus: 1,
        icono: Icons.local_library_outlined,
      ),
      ServicioCampusUaa(
        nombre: 'Cajas y Departamento de Finanzas',
        ubicacion:
            'Edificio Academico Administrativo (Planta Baja, Edificio 1-A)',
        horario: 'Ventanilla: 08:00 - 15:30 hrs | Portal en linea: 24/7',
        estadoActual: 'Abierto - Pago digital 24/7',
        descripcion: 'Recepcion de pagos de matricula, colegiatura mensual, constancias y derechos de examen.',
        telefonoExtension: 'Tel. 449 910 74 00 Ext. 2114',
        idCampus: 1,
        icono: Icons.payments_outlined,
      ),
      ServicioCampusUaa(
        nombre: 'Control Escolar y Credencializacion',
        ubicacion: 'Edificio 1-A Planta Baja, Ciudad Universitaria',
        horario: 'Lunes a Viernes: 08:00 - 15:30 hrs',
        estadoActual: 'Abierto',
        descripcion: 'Emision de constancias de estudios, reposicion de credencial inteligente, altas y bajas.',
        telefonoExtension: 'Tel. 449 910 74 00 Ext. 2205',
        idCampus: 1,
        icono: Icons.badge_outlined,
      ),
      ServicioCampusUaa(
        nombre: 'Unidad Medico Didactica (UMD)',
        ubicacion: 'Edificio 101, Zona Norte de Ciudad Universitaria',
        horario: 'Lunes a Viernes: 07:30 - 20:00 hrs',
        estadoActual: 'Atencion activa',
        descripcion: 'Consultas medicas generales, optometria, estomatologia, nutricion y apoyo psicologico estudiantil.',
        telefonoExtension: 'Tel. 449 910 74 00 Ext. 5300',
        idCampus: 1,
        icono: Icons.medical_services_outlined,
      ),
      ServicioCampusUaa(
        nombre: 'Biblioteca, CAADI y Laboratorios Campus Sur',
        ubicacion: 'Edificio B y Modulo Bibliotecario, Campus Sur',
        horario: 'Lunes a Viernes: 07:00 - 20:30 hrs',
        estadoActual: 'Equipos disponibles',
        descripcion: 'Centro de Aprendizaje Autodirigido de Idiomas, salas de computo de ingenieria y acervo especializado en Campus Sur.',
        telefonoExtension: 'Tel. 449 910 74 00 Ext. 7120',
        idCampus: 2,
        icono: Icons.computer_outlined,
      ),
      ServicioCampusUaa(
        nombre: 'Ventanilla Administrativa y Transporte Campus Sur',
        ubicacion: 'Edificio A Planta Baja / Paradero Blvd. Jose Maria Chavez',
        horario: 'Rutas: 06:45 - 21:15 hrs | Ventanilla: 08:00 - 15:30 hrs',
        estadoActual: 'En operacion',
        descripcion: 'Conexion de transporte universitario entre Campus Central y Sur, tramites escolares y becas.',
        telefonoExtension: 'Tel. 449 910 74 00 Ext. 7105',
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
  List<ActividadUniversitaria> obtenerActividades({
    String? categoriaFiltro,
    int? idCampusFiltro,
  }) {
    const List<ActividadUniversitaria> actividades = <ActividadUniversitaria>[
      ActividadUniversitaria(
        titulo: 'Conferencia: Etica e Inteligencia Artificial en la Educacion Superior',
        categoria: 'Formacion Humanistica',
        beneficio: 'Otorga 1 Credito Humanistico',
        fechaHora: '26 Nov 2026 - 12:00 hrs',
        lugar: 'Auditorio Dr. Pedro de Alba (Campus Central)',
        modalidadCupo: 'Presencial - Registro con credencial UAA',
        idCampus: 1,
      ),
      ActividadUniversitaria(
        titulo: 'Torneo Interno Intercentros Gallos UAA (Futbol, Basquetbol y Voleibol)',
        categoria: 'Deportes y Cultura',
        beneficio: 'Acredita Actividad Deportiva',
        fechaHora: '28 Nov 2026 - 09:00 hrs',
        lugar: 'Unidad Deportiva Universitaria y Poliforum',
        modalidadCupo: 'Presencial - Convocatoria abierta',
        idCampus: 1,
      ),
      ActividadUniversitaria(
        titulo:
            'Taller Practico: Sistemas Distribuidos, Docker y Bases de Datos',
        categoria: 'Talleres y Congresos',
        beneficio: 'Constancia con Valor Curricular',
        fechaHora: '30 Nov 2026 - 16:00 hrs',
        lugar: 'Sala Audiovisual Edificio B (Campus Sur)',
        modalidadCupo: 'Hibrido - Cupo para 80 participantes',
        idCampus: 2,
      ),
      ActividadUniversitaria(
        titulo: 'Concierto de Fin de Semestre: Polifonia Universitaria y Ensamble UAA',
        categoria: 'Formacion Humanistica',
        beneficio: 'Otorga 1 Credito Humanistico',
        fechaHora: '02 Dic 2026 - 18:00 hrs',
        lugar: 'Auditorio Ignacio T. Chavez (Campus Central)',
        modalidadCupo: 'Presencial - Entrada libre con matricula',
        idCampus: 1,
      ),
      ActividadUniversitaria(
        titulo:
            'Curso Docente: Evaluacion por Rubricas y Gestion de Aula Virtual',
        categoria: 'Apoyo Docente',
        beneficio: 'Acreditacion PRODEP / Formacion Docente',
        fechaHora: '03 Dic 2026 - 10:00 hrs',
        lugar: 'Aula Digital Edificio Academico Administrativo',
        modalidadCupo: 'Para profesores de todos los Centros',
        idCampus: 1,
      ),
      ActividadUniversitaria(
        titulo: 'Muestra Emprendedora y Proyectos Integradores de Ingenieria',
        categoria: 'Talleres y Congresos',
        beneficio: 'Constancia de Participacion',
        fechaHora: '04 Dic 2026 - 10:00 a 14:00 hrs',
        lugar: 'Explanada Principal y Aulas de Campus Sur',
        modalidadCupo: 'Presencial - Evaluacion final de proyectos',
        idCampus: 2,
      ),
    ];

    return actividades.where((ActividadUniversitaria a) {
      final bool coincideCategoria =
          categoriaFiltro == null ||
          categoriaFiltro == 'Todas' ||
          a.categoria == categoriaFiltro;
      final bool coincideCampus =
          idCampusFiltro == null || a.idCampus == idCampusFiltro;
      return coincideCategoria && coincideCampus;
    }).toList();
  }

  // Devuelve el catalogo oficial completo de edificios individuales (153 en Central y 19 en Sur)
  List<EdificioMapaUaa> obtenerEdificiosMapa({required int idCampus}) {
    if (idCampus == 2) {
      return CampusMapData.obtenerEdificiosSur();
    }
    return CampusMapData.obtenerEdificiosCentral();
  }

  // Devuelve la red completa de nodos y pasillos peatonales conectando cada edificio individual
  List<NodoPasilloUaa> obtenerGrafoPasillos({required int idCampus}) {
    if (idCampus == 2) {
      return CampusMapData.obtenerNodosSur();
    }
    return CampusMapData.obtenerNodosCentral();
  }

  // Calcula la ruta peatonal mas corta entre dos puntos del campus usando el algoritmo de Dijkstra
  RutaPeatonalUaa calcularRutaPeatonal({
    required int idCampus,
    required String idNodoOrigen,
    required String idNodoDestino,
  }) {
    final List<EdificioMapaUaa> edificios = obtenerEdificiosMapa(
      idCampus: idCampus,
    );
    final List<NodoPasilloUaa> nodos = obtenerGrafoPasillos(idCampus: idCampus);

    final EdificioMapaUaa origen = edificios.firstWhere(
      (EdificioMapaUaa e) => e.idNodo == idNodoOrigen,
      orElse: () => edificios.first,
    );
    final EdificioMapaUaa destino = edificios.firstWhere(
      (EdificioMapaUaa e) => e.idNodo == idNodoDestino,
      orElse: () => edificios.last,
    );

    final Map<String, NodoPasilloUaa> mapaNodos = <String, NodoPasilloUaa>{
      for (final NodoPasilloUaa n in nodos) n.id: n,
    };

    // Si el origen y el destino son el mismo edificio, devuelve ruta inmediata de 0 metros
    if (origen.idNodo == destino.idNodo) {
      final NodoPasilloUaa? nodoUnico = mapaNodos[origen.idNodo];
      return RutaPeatonalUaa(
        origen: origen,
        destino: destino,
        puntosTrayecto: nodoUnico != null
            ? <NodoPasilloUaa>[nodoUnico]
            : <NodoPasilloUaa>[],
        distanciaMetros: 0,
        tiempoMinutos: 1,
        indicacionesPasoAPaso: <String>[
          'Ya te encuentras en ${origen.codigo} (${origen.nombre}).',
          if (origen.salonesReferencia.isNotEmpty)
            'Espacios y salones en este punto: ${origen.salonesReferencia}.',
        ],
      );
    }

    // Construye lista de adyacencia bidireccional para garantizar caminos simetricos
    final Map<String, Set<String>> adyacencia = <String, Set<String>>{};
    for (final NodoPasilloUaa n in nodos) {
      adyacencia.putIfAbsent(n.id, () => <String>{});
      for (final String vecinoId in n.conectadosCon) {
        if (mapaNodos.containsKey(vecinoId)) {
          adyacencia[n.id]!.add(vecinoId);
          adyacencia.putIfAbsent(vecinoId, () => <String>{}).add(n.id);
        }
      }
    }

    // Inicializacion de estructuras del algoritmo de Dijkstra
    final Map<String, double> distancias = <String, double>{
      for (final NodoPasilloUaa n in nodos) n.id: double.infinity,
    };
    final Map<String, String?> previos = <String, String?>{};
    final Set<String> noVisitados = <String>{
      for (final NodoPasilloUaa n in nodos) n.id,
    };

    distancias[origen.idNodo] = 0.0;

    while (noVisitados.isNotEmpty) {
      String? actualId;
      double menorDistancia = double.infinity;
      for (final String candidato in noVisitados) {
        final double d = distancias[candidato] ?? double.infinity;
        if (d < menorDistancia) {
          menorDistancia = d;
          actualId = candidato;
        }
      }

      if (actualId == null ||
          actualId == destino.idNodo ||
          menorDistancia == double.infinity) {
        break;
      }

      noVisitados.remove(actualId);
      final NodoPasilloUaa nodoActual = mapaNodos[actualId]!;

      for (final String vecinoId in adyacencia[actualId] ?? const <String>{}) {
        if (!noVisitados.contains(vecinoId)) {
          continue;
        }
        final NodoPasilloUaa nodoVecino = mapaNodos[vecinoId]!;
        final double dx = nodoVecino.posX - nodoActual.posX;
        final double dy = nodoVecino.posY - nodoActual.posY;
        final double pesoArista = math.sqrt(dx * dx + dy * dy);
        final double nuevaDistancia = menorDistancia + pesoArista;

        if (nuevaDistancia < (distancias[vecinoId] ?? double.infinity)) {
          distancias[vecinoId] = nuevaDistancia;
          previos[vecinoId] = actualId;
        }
      }
    }

    // Reconstruye la secuencia de nodos desde el origen hasta el destino
    final List<NodoPasilloUaa> trayecto = <NodoPasilloUaa>[];
    String? cursor = destino.idNodo;
    while (cursor != null && mapaNodos.containsKey(cursor)) {
      trayecto.insert(0, mapaNodos[cursor]!);
      cursor = previos[cursor];
    }

    if (trayecto.isEmpty || trayecto.first.id != origen.idNodo) {
      trayecto
        ..clear()
        ..add(mapaNodos[origen.idNodo]!)
        ..add(mapaNodos[destino.idNodo]!);
    }

    // Calcula la distancia real aproximada en metros y el tiempo estimado a pie
    final double distanciaNormalizada = distancias[destino.idNodo] ?? 0.18;
    final double factorEscalaMetros = idCampus == 1 ? 760.0 : 680.0;
    final int metros = (distanciaNormalizada * factorEscalaMetros)
        .round()
        .clamp(35, 1400);
    final int minutos = (metros / 75.0).ceil().clamp(1, 19);

    // Genera las indicaciones paso a paso sin repetir el mismo pasillo consecutivo
    final List<String> pasos = <String>[
      '1. Punto de partida: ${origen.codigo} - ${origen.nombre}.',
    ];

    int numeroPaso = 2;
    String ultimaEtiqueta = '';
    for (int i = 1; i < trayecto.length - 1; i++) {
      final String etiquetaActual = trayecto[i].etiqueta;
      if (etiquetaActual.isNotEmpty && etiquetaActual != ultimaEtiqueta) {
        pasos.add('$numeroPaso. Avanza por: $etiquetaActual.');
        ultimaEtiqueta = etiquetaActual;
        numeroPaso++;
      }
    }

    pasos.add(
      '$numeroPaso. Llegada a tu destino: ${destino.codigo} - ${destino.nombre}.',
    );

    return RutaPeatonalUaa(
      origen: origen,
      destino: destino,
      puntosTrayecto: trayecto,
      distanciaMetros: metros,
      tiempoMinutos: minutos,
      indicacionesPasoAPaso: pasos,
    );
  }

  // Devuelve el directorio de Centros Academicos de la UAA
  List<CentroAcademicoUaa> obtenerCentrosAcademicos() {
    return const <CentroAcademicoUaa>[
      CentroAcademicoUaa(
        siglas: 'CCB',
        nombre: 'Centro de Ciencias Basicas',
        decanatoEdificio:
            'Edificio 54 / Laboratorios Edificio 60 (Campus Central)',
        extensionTelefonica: 'Ext. 8400',
        idCampus: 1,
      ),
      CentroAcademicoUaa(
        siglas: 'CCING',
        nombre: 'Centro de Ciencias de la Ingenieria',
        decanatoEdificio: 'Edificio A y Laboratorios B/C (Campus Sur)',
        extensionTelefonica: 'Ext. 7100',
        idCampus: 2,
      ),
      CentroAcademicoUaa(
        siglas: 'CCE',
        nombre: 'Centro de Ciencias Empresariales',
        decanatoEdificio: 'Edificio A Piso 2 (Campus Sur)',
        extensionTelefonica: 'Ext. 7200',
        idCampus: 2,
      ),
      CentroAcademicoUaa(
        siglas: 'CCEA',
        nombre: 'Centro de Ciencias Economico Administrativas',
        decanatoEdificio: 'Edificio 32 (Campus Central)',
        extensionTelefonica: 'Ext. 3400',
        idCampus: 1,
      ),
      CentroAcademicoUaa(
        siglas: 'CCS',
        nombre: 'Centro de Ciencias de la Salud',
        decanatoEdificio:
            'Edificio 101 / Unidad Medico Didactica (Campus Central)',
        extensionTelefonica: 'Ext. 5300',
        idCampus: 1,
      ),
      CentroAcademicoUaa(
        siglas: 'CCDC',
        nombre: 'Centro de Ciencias del Diseño y de la Construcción',
        decanatoEdificio: 'Edificio 108 (Campus Central)',
        extensionTelefonica: 'Ext. 4200',
        idCampus: 1,
      ),
    ];
  }
}
