import 'package:esimma_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Suite de pruebas de widget para validar la estructura inicial del frontend
void main() {
  testWidgets(
    'Renderiza la pantalla base institucional y alterna el tema visual',
    (WidgetTester tester) async {
      await tester.pumpWidget(const EsimmaApp());

      // Verifica que los textos institucionales y los dos campus esten visibles
      expect(find.text('E-SIIMA UAA'), findsOneWidget);
      expect(find.text('Campus Central'), findsOneWidget);
      expect(find.text('Campus Sur'), findsOneWidget);

      // Verifica que el boton de cambio de tema funcione correctamente
      final Finder themeButton = find.byIcon(Icons.dark_mode_outlined);
      expect(themeButton, findsOneWidget);

      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    },
  );
}
