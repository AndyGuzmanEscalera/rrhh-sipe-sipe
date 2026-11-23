import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:failures/failures.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/features/attendance/views/employee_attendance_report.dart';
import 'package:rrhh_sipe_sipe/injection/get_it.dart';

import 'attendance_fixtures.dart';

class _FakeReportRepository extends Fake implements AttendanceRepository {
  @override
  Future<Result<AttendanceReport, Failure>> reportRange(
      String id, String from, String to,
      {Map<String, Object?> evaluation = const {}}) async =>
      ok(AttendanceReport.fromJson(reportJson()));
}

void main() {
  setUp(() => sl.registerSingleton<AttendanceRepository>(_FakeReportRepository()));
  tearDown(() => sl.reset());

  Future<void> show(WidgetTester tester) async {
    // La app muestra el reporte dentro de un scroll vertical; se replica aquí.
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: EmployeeAttendanceReport(employeeId: 'empleado-1')))));
    await tester.pumpAndSettle();
  }

  /// El control puede quedar fuera de la vista: se trae antes de tocarlo.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Los días sin marcación se ocultan por defecto y se pueden mostrar',
      (tester) async {
    await show(tester);

    // El fixture tiene un día con marcaciones (01/10) y uno sin (02/10).
    expect(find.text('01/10/2026'), findsOneWidget);
    expect(find.text('02/10/2026'), findsNothing);
    expect(find.text('Mostrar días sin marcación'), findsOneWidget);
    final toggle = find.byType(Checkbox);
    expect(toggle, findsOneWidget);

    // Al activar el control aparecen también los días sin marcación.
    await tapVisible(tester, toggle);
    expect(find.text('02/10/2026'), findsOneWidget);

    // Al desactivarlo se ocultan de nuevo. Solo cambia la vista.
    await tapVisible(tester, find.byType(Checkbox));
    expect(find.text('02/10/2026'), findsNothing);
    expect(find.text('01/10/2026'), findsOneWidget);
  });

  testWidgets('La tabla del reporte no muestra la columna Turno',
      (tester) async {
    await show(tester);

    expect(
        find.descendant(
            of: find.byType(DataTable), matching: find.text('Turno')),
        findsNothing);
  });

  testWidgets('Las marcaciones se muestran numeradas y sin datos técnicos',
      (tester) async {
    await show(tester);

    await tapVisible(tester, find.text('Ver marcaciones (6)'));

    expect(find.text('Marcación 1: 08:10:00'), findsOneWidget);
    expect(find.text('Marcación 2: 12:05:00'), findsOneWidget);
    expect(find.text('Marcación 3: 13:55:00'), findsOneWidget);
    expect(find.text('Marcación 4: 18:10:00'), findsOneWidget);
    expect(find.text('Marcación 5: 18:12:00'), findsOneWidget);
    expect(find.text('Marcación 6: 18:15:00'), findsOneWidget);
    expect(find.textContaining('status_raw', findRichText: true), findsNothing);
    expect(find.textContaining('punch_raw', findRichText: true), findsNothing);
    expect(find.textContaining('uid_raw', findRichText: true), findsNothing);
    expect(find.textContaining('source:', findRichText: true), findsNothing);
    expect(find.textContaining('Lote:', findRichText: true), findsNothing);
    expect(find.textContaining('Archivo:', findRichText: true), findsNothing);
  });
}
