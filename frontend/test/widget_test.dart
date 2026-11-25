import 'package:esimma_frontend/data/repositories/portal_repository.dart';
import 'package:esimma_frontend/domain/entities/portal_models.dart';
import 'package:esimma_frontend/main.dart';
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

      // Verifica que las flechas del carrusel esten ocultas mientras no este seleccionado
      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      // Verifica la columna diferenciada de Recursos y Biblioteca
      expect(find.text('RECURSOS Y BIBLIOTECA'), findsOneWidget);
    },
  );

  test(
    'Calcula rutas peatonales exactas por pasillos hacia edificios individuales como 38, 43 y 202',
    () {
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
    },
  );
}
