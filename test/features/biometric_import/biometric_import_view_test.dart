import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/theme/app_theme.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/cubit/biometric_import_cubit.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/data/biometric_file_picker.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/views/biometric_import_page.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/widgets/biometric_preview.dart';

class _Picker extends BiometricFilePicker {
  @override
  Future<SelectedBiometricFile?> selectFile() async {
    final lines =
        List.generate(42, (i) => 'id-$i\t2026-09-01 06:53:11\t1\t0\tX\t0');
    final bytes = Uint8List.fromList(
        utf8.encode(['fila inválida', ...lines].join('\r\n')));
    return SelectedBiometricFile(
        name: 'prueba.dat',
        size: bytes.length,
        selectedAt: DateTime(2026, 10, 7, 10, 30),
        bytes: bytes);
  }
}

void main() {
  for (final width in [375.0, 1100.0]) {
    testWidgets(
        'Archivo con advertencias, tabla paginada y errores a $width px',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cubit = BiometricImportCubit(
          repository: const BiometricImportRepository(), picker: _Picker());
      addTearDown(cubit.close);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
              body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: BlocProvider.value(
                      value: cubit, child: const BiometricImportView())))));
      expect(find.text('Seleccionar archivo'), findsOneWidget);
      await tester.tap(find.text('Seleccionar archivo'));
      await tester.pumpAndSettle();
      expect(find.text('prueba.dat'), findsOneWidget);
      expect(find.text('Registros encontrados: 43'), findsOneWidget);
      expect(find.text('Archivo procesado con advertencias.'), findsOneWidget);
      Finder previewText(String text) => find.descendant(
          of: find.byType(BiometricPreview), matching: find.text(text));
      expect(previewText('id-0'), findsOneWidget);
      expect(previewText('id-20'), findsNothing);
      expect(tester.takeException(), isNull);

      final next = find.descendant(of: find.byType(BiometricPreview),
          matching: find.byTooltip('Página siguiente'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(previewText('id-20'), findsOneWidget);
      expect(previewText('id-0'), findsNothing);

      await tester.ensureVisible(find.text('Ver errores'));
      await tester.tap(find.text('Ver errores'));
      await tester.pumpAndSettle();
      expect(find.text('Registros inválidos (1)'), findsOneWidget);
      expect(find.text('fila inválida'), findsOneWidget);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      final importButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Importar marcaciones'));
      expect(importButton.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
