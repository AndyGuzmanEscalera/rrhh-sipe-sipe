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
import 'package:rrhh_sipe_sipe/features/biometric_import/widgets/biometric_raw_records.dart';

import 'biometric_import_cubit_test.dart' show FakeBiometricImportRepository;

class _Picker extends BiometricFilePicker {
  @override
  Future<SelectedBiometricFile?> selectFile() async {
    final lines =
        List.generate(42, (i) => 'id-$i\t2026-11-18 07:54:11\t15\t255\t1\t0');
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
        'Importación biométrica: archivo, previsualización y lotes a $width px',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = FakeBiometricImportRepository()
        ..batches = [
          BiometricImportBatch.fromJson({
            'id': 'batch-1',
            'device_id': 'test-clock',
            'origin': 'SOURCE_FILE',
            'source_file_name': 'prueba.dat',
            'status': 'completed',
            'downloaded_records': 43,
            'new_records': 40,
            'duplicate_records': 3,
            'error_records': 0,
            'created_at': '2026-11-18T09:00:00Z',
          })
        ];
      final cubit =
          BiometricImportCubit(repository: repository, picker: _Picker());
      addTearDown(cubit.close);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
              body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: BlocProvider.value(
                      value: cubit,
                      child: const BiometricImportView(canManage: true))))));
      expect(find.text('Importar archivo TXT'), findsOneWidget);
      expect(find.text('Sincronizar dispositivo'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Última importación'), findsOneWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Importar archivo TXT'));
      await tester.pumpAndSettle();
      expect(find.text('prueba.dat'), findsOneWidget);
      expect(find.text('Previsualización'), findsOneWidget);
      Finder previewText(String text) => find.descendant(
          of: find.byType(BiometricPreview), matching: find.text(text));
      expect(previewText('id-0'), findsOneWidget);
      expect(previewText('id-20'), findsNothing);
      expect(tester.takeException(), isNull);

      final next = find.descendant(
          of: find.byType(BiometricPreview),
          matching: find.byTooltip('Página siguiente'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(previewText('id-20'), findsOneWidget);
      expect(previewText('id-0'), findsNothing);
      expect(tester.takeException(), isNull);

      // El lote se puede abrir y muestra la evidencia en bruto.
      await tester.ensureVisible(find.byKey(const ValueKey('batch-batch-1')));
      await tester.tap(find.byKey(const ValueKey('batch-batch-1')));
      await tester.pumpAndSettle();
      expect(find.byType(BiometricRawRecords), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
