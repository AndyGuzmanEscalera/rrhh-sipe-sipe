import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/theme/app_theme.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/widgets/attendance_analysis_view.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/widgets/attendance_configuration_dialog.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/views/employee_attendance_page.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/widgets/attendance_day_dialog.dart';

void main() {
  for (final width in [375.0, 1440.0]) {
    testWidgets('Calendario mensual y todas las marcas del día a $width px',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final records = [
        for (var i = 0; i < 8; i++)
          BiometricRecord(
              employeeIdentifier: '123',
              timestamp: DateTime(2026, 9, 1, 8 + i),
              field3: '1',
              field4: '$i',
              field5: 'X',
              field6: '0',
              rawLine: 'original-$i',
              lineNumber: i + 1),
        BiometricRecord(
            employeeIdentifier: '999',
            timestamp: DateTime(2026, 9, 1, 23),
            field3: '1',
            field4: 'S',
            field5: 'X',
            field6: '0',
            rawLine: 'otro-funcionario',
            lineNumber: 9)
      ];
      final report = await const AttendanceAnalyzer().analyze(
          records: records,
          configuration: AttendanceConfiguration(),
          employees: [
            EmployeeAdmin(
                id: 'e1',
                firstName: 'Ana',
                lastName: 'Pérez',
                documentNumber: '123',
                isActive: true,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026))
          ]);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
              body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AttendanceAnalysisView(analysis: report)))));
      await tester.pumpAndSettle();
      final listElement = tester.element(find.byType(AttendanceAnalysisView));
      await tester.tap(find.text('Ana Pérez'));
      await tester.pumpAndSettle();
      expect(find.byType(EmployeeAttendancePage), findsOneWidget);
      expect(find.byType(AttendanceAnalysisView), findsNothing);
      expect(find.text('8 marcaciones'), findsOneWidget);
      expect(find.text('Septiembre 2026'), findsOneWidget);
      if (width >= 1100) {
        expect(find.text('+6 más'), findsOneWidget);
        expect(find.text('08:00 · 09:00'), findsOneWidget);
      } else {
        expect(find.text('8 reg.'), findsOneWidget);
      }
      final cell = find.byKey(const ValueKey('calendar-2026-09-01'));
      await tester.ensureVisible(cell);
      expect(tester.getSize(cell).height, 88);
      expect(find.descendant(of: cell, matching: find.text('Observación')),
          findsNothing);
      await tester.tap(cell);
      await tester.pumpAndSettle();
      expect(find.byType(AttendanceDayDialog), findsOneWidget);
      expect(find.byType(EmployeeAttendancePage), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('8 marcaciones originales, en orden cronológico.'),
          findsOneWidget);
      final scrollable = find
          .descendant(
              of: find.byType(AttendanceDayDialog),
              matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(find.text('15:00:00'), 120,
          scrollable: scrollable);
      await Scrollable.ensureVisible(tester.element(find.text('15:00:00')),
          alignment: .5);
      await tester.pumpAndSettle();
      expect(find.text('original-7'), findsOneWidget);
      expect(find.text('23:00:00'), findsNothing);
      expect(find.text('otro-funcionario'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Cerrar detalle'));
      await tester.pumpAndSettle();
      expect(find.text('Septiembre 2026'), findsOneWidget);
      expect(find.text('Observaciones: 1'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Mes siguiente'));
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Octubre 2026'), findsOneWidget);
      expect(find.text('Normales: 0'), findsOneWidget);
      expect(find.text('Observaciones: 0'), findsOneWidget);
      expect(find.text('Anomalías: 0'), findsOneWidget);
      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Septiembre 2026'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.element(find.byType(AttendanceAnalysisView)),
          same(listElement));
    });
  }
  testWidgets(
      'Configuración no aplica el ejemplo automáticamente y valida horarios',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AttendanceConfigurationDialog(
                configuration: AttendanceConfiguration()))));
    final schedule = find.byType(TextField).first;
    expect(tester.widget<TextField>(schedule).controller!.text, isEmpty);
    await tester.enterText(schedule, '25:00 E');
    await tester.tap(find.text('Aplicar al análisis'));
    await tester.pumpAndSettle();
    expect(find.text('Hora inválida en el horario.'), findsOneWidget);
  });
}
