import 'package:esimma_frontend/core/services/geolocation_service.dart';
import 'package:esimma_frontend/data/repositories/portal_repository.dart';
import 'package:esimma_frontend/domain/entities/portal_models.dart';
import 'package:esimma_frontend/main.dart';
import 'package:esimma_frontend/presentation/widgets/interactive_campus_map_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Suite de pruebas de widget y rutas peatonales para validar el Portal UAA
void main() {
  testWidgets(
    'Renderiza TU RESUMEN DE HOY EN LA UAA sin adeudos null y oculta flechas del carrusel por defecto',
    (WidgetTester tester) async {
      await tester.pumpWidget(const EsimmaApp());

      // Verifica el titulo limpio del resumen diario sin texto extra de sin adeudos
      expect(find.text('TU RESUMEN DE HOY EN LA UAA'), findsOneWidget);
      expect(find.text('PROXIMA CLASE DE HOY'), findsOneWidget);
      expect(find.text('ENTREGA PENDIENTE EN AULA VIRTUAL'), findsOneWidget);
      expect(find.text('ADEUDO PENDIENTE EN CAJAS / FINANZAS'), findsNothing);

      // Verifica que no exista el boton Ver Ambos Campus y solo esten Campus Central y Campus Sur
      expect(find.text('Ver Ambos Campus'), findsNothing);
      expect(find.text('Campus Central'), findsOneWidget);
      expect(find.text('Campus Sur'), findsOneWidget);

      // Verifica que el selector de sesion muestre el nombre y no solo el rol
      final String nombreSesion = const PortalRepository()
          .obtenerPerfilesPrueba()
          .first
          .nombre;
      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (Widget widget) => widget is PopupMenuButton<SesionUsuarioUaa>,
          ),
          matching: find.text(nombreSesion),
        ),
        findsOneWidget,
      );

      // Verifica que las flechas del carrusel esten ocultas mientras no este seleccionado
      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      // Verifica la columna diferenciada de Recursos y Biblioteca
      expect(find.text('RECURSOS Y BIBLIOTECA'), findsOneWidget);
    },
  );

  test('Calcula rutas peatonales exactas por pasillos hacia edificios individuales como 38, 43 y 202', () {
    const PortalRepository repo = PortalRepository();

    // Verifica que los edificios 38 y 43 tengan nodos y rutas distintas y exactas
    final RutaPeatonalUaa ruta38 = repo.calcularRutaPeatonal(
      idCampus: 1,
      idNodoOrigen: 'CEN-B-ACCESO_SUR',
      idNodoDestino: 'CEN-B-38',
    );
    final RutaPeatonalUaa ruta43 = repo.calcularRutaPeatonal(
      idCampus: 1,
      idNodoOrigen: 'CEN-B-ACCESO_SUR',
      idNodoDestino: 'CEN-B-43',
    );
    expect(ruta38.destino.codigo, 'EDIF 38');
    expect(ruta43.destino.codigo, 'EDIF 43');
    expect(ruta38.destino.posX, isNot(equals(ruta43.destino.posX)));
    expect(ruta38.puntosTrayecto.last.id, 'CEN-B-38');
    expect(ruta43.puntosTrayecto.last.id, 'CEN-B-43');

    // Verifica que las rutas hacia edificios 300 y 400 crucen por el Tunel 208 y rodeen por la Unidad Deportiva
    final RutaPeatonalUaa ruta401 = repo.calcularRutaPeatonal(
      idCampus: 1,
      idNodoOrigen: 'CEN-B-ACCESO_SUR',
      idNodoDestino: 'CEN-B-401',
    );
    final List<String> ids401 = ruta401.puntosTrayecto
        .map((NodoPasilloUaa n) => n.id)
        .toList();
    expect(
      ids401,
      containsAll(<String>[
        'CEN-W-268',
        'CEN-W-269',
        'CEN-W-270',
        'CEN-W-136',
        'CEN-W-142',
      ]),
    );

    // Verifica que las rutas al oriente de Av. Aguascalientes Norte crucen por el Tunel 22 (CEN-W-273 -> CEN-W-274)
    final RutaPeatonalUaa ruta101 = repo.calcularRutaPeatonal(
      idCampus: 1,
      idNodoOrigen: 'CEN-B-ACCESO_SUR',
      idNodoDestino: 'CEN-B-101',
    );
    final List<String> ids101 = ruta101.puntosTrayecto
        .map((NodoPasilloUaa n) => n.id)
        .toList();
    expect(
      ids101,
      containsAll(<String>['CEN-W-273', 'CEN-W-274', 'CEN-W-275']),
    );

    // Ruta en Campus Sur: Acceso Sur -> Taller 17 (Ingenieria Automotriz)
    final RutaPeatonalUaa rutaSur = repo.calcularRutaPeatonal(
      idCampus: 2,
      idNodoOrigen: 'SUR-B-ACCESO_SUR',
      idNodoDestino: 'SUR-B-17',
    );
    expect(rutaSur.origen.idNodo, 'SUR-B-ACCESO_SUR');
    expect(rutaSur.destino.idNodo, 'SUR-B-17');
    expect(rutaSur.puntosTrayecto.length, greaterThanOrEqualTo(5));
    expect(rutaSur.distanciaMetros, greaterThan(100));

    // Verifica deteccion automatica de GPS dentro y fuera del campus UAA con entrada sugerida
    final ProyeccionUbicacionUaa dentroUaa =
        GeolocationServiceUaa.proyectarGpsAlMapa(
          latitud: 21.9125,
          longitud: -102.3155,
          idCampusActivo: 1,
        );
    expect(dentroUaa.estaDentroDelCampus, isTrue);

    final ProyeccionUbicacionUaa fueraUaa =
        GeolocationServiceUaa.proyectarGpsAlMapa(
          latitud: 21.8820,
          longitud: -102.2910,
          idCampusActivo: 1,
        );
    expect(fueraUaa.estaDentroDelCampus, isFalse);
    expect(fueraUaa.distanciaAlCampusMetros, greaterThan(1000));
    expect(fueraUaa.entradaMasCercana.idNodoEdificio, isNotEmpty);
  });

  test('Incluye perfiles de alumno y docente con nombre para el selector', () {
    final List<SesionUsuarioUaa> perfiles = const PortalRepository()
        .obtenerPerfilesPrueba();

    expect(
      perfiles.any(
        (SesionUsuarioUaa sesion) =>
            !sesion.esProfesor && sesion.nombre == 'Angel Azael Fajardo Espino',
      ),
      isTrue,
    );
    expect(
      perfiles.any(
        (SesionUsuarioUaa sesion) =>
            sesion.esProfesor && sesion.nombre == 'Dr. David Montoya',
      ),
      isTrue,
    );
  });

  testWidgets(
    'Renderiza la landing en ancho de telefono sin desbordar el encabezado',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const EsimmaApp());
      await tester.pump(const Duration(milliseconds: 200));

      final String nombreSesion = const PortalRepository()
          .obtenerPerfilesPrueba()
          .first
          .nombre;
      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (Widget widget) => widget is PopupMenuButton<SesionUsuarioUaa>,
          ),
          matching: find.text(nombreSesion),
        ),
        findsOneWidget,
      );

      // En celular el cambio de tema vive dentro del menu hamburguesa
      await tester.tap(find.byTooltip('Abrir menu de secciones'));
      await tester.pumpAndSettle();
      expect(find.text('Cambiar a modo oscuro'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Renderiza el mapa interactivo y la capa base vectorial sin excepciones',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveCampusMapSection(
              repository: PortalRepository(),
              initialCampusId: 1,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(InteractiveCampusMapSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
