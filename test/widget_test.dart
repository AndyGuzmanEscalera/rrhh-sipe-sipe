import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_sipe_sipe/core/presentation/screens/error_screen.dart';

void main() {
  testWidgets('Muestra el error de ruta y permite volver al inicio',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ErrorScreen()));
    expect(find.text('Ruta no encontrada'), findsOneWidget);
    expect(find.text('Ir al inicio'), findsOneWidget);
  });
}
