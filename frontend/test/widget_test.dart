import 'package:esimma_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Suite de pruebas de widget para validar la Landing Page institucional UAA completa
void main() {
  testWidgets(
    'Renderiza la Landing Page con herramientas de perfil, servicios, creditos y mapa UAA',
    (WidgetTester tester) async {
      await tester.pumpWidget(const EsimmaApp());

      // Verifica el conmutador Soy Alumno / Soy Profesor y las secciones principales
      expect(find.text('Soy Alumno'), findsOneWidget);
      expect(find.text('Soy Profesor'), findsOneWidget);
      expect(find.text('NOTICIAS Y AVISOS'), findsOneWidget);
      expect(
        find.text('SERVICIOS EN CAMPUS Y HORARIOS DE ATENCION'),
        findsOneWidget,
      );
      expect(
        find.text('ACTIVIDADES, CREDITOS HUMANISTICOS Y DEPORTES'),
        findsOneWidget,
      );
      expect(
        find.text('MAPA UNIVERSITARIO Y UBICADOR DE EDIFICIOS'),
        findsOneWidget,
      );

      // Verifica el cambio de perfil de Alumno a Profesor
      final Finder botonProfesor = find.text('Soy Profesor');
      await tester.ensureVisible(botonProfesor);
      await tester.pumpAndSettle();
      await tester.tap(botonProfesor);
      await tester.pumpAndSettle();
      expect(find.text('Publicar Tarea o Aviso'), findsOneWidget);

      // Verifica que el icono de cambio de tema funcione correctamente
      final Finder themeButton = find.byIcon(Icons.dark_mode);
      await tester.ensureVisible(themeButton);
      await tester.pumpAndSettle();
      expect(themeButton, findsOneWidget);

      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    },
  );
}
