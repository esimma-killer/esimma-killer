import '../../core/constants/app_constants.dart';
import '../../domain/entities/aviso_institucional.dart';
import '../../domain/entities/campus_info.dart';
import '../../domain/entities/evento_calendario.dart';

// Repositorio de datos publicos del portal institucional UAA
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
}
