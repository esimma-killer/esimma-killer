import 'package:esimma_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Suite de pruebas de widget para validar la Landing Page institucional UAA
void main() {
  testWidgets(
    'Renderiza la Landing Page con carrusel fotografico, 3 columnas y pie de pagina',
    (WidgetTester tester) async {
      await tester.pumpWidget(const EsimmaApp());

      // Verifica botones en esquina superior derecha y secciones de 3 columnas
      expect(find.text('E-SIIMA'), findsOneWidget);
      expect(find.text('NOTICIAS Y AVISOS'), findsOneWidget);
      expect(find.text('EVENTOS Y FECHAS'), findsOneWidget);
      expect(find.text('SERVICIOS FRECUENTES'), findsOneWidget);

      // Verifica el lema institucional en el pie de pagina
      expect(find.text('Se Lumen Proferre'), findsOneWidget);

      // Verifica que el icono de cambio de tema funcione correctamente
      final Finder themeButton = find.byIcon(Icons.dark_mode);
      expect(themeButton, findsOneWidget);

      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    },
  );
}
