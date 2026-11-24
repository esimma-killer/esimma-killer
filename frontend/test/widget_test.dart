import 'package:esimma_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Suite de pruebas de widget para validar la Landing Page UAA con secciones condicionales
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
}
