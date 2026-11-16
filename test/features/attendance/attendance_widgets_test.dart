import 'package:flutter/material.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:rrhh_sipe_sipe/features/attendance/cubit/attendance_cubit.dart';
import 'package:rrhh_sipe_sipe/features/attendance/cubit/attendance_report_cubit.dart';
import 'package:rrhh_sipe_sipe/features/attendance/views/attendance_view.dart';
import 'package:rrhh_sipe_sipe/features/attendance/views/attendance_report_page.dart';
import 'package:rrhh_sipe_sipe/features/attendance/widgets/attendance_calendar.dart';
import 'package:rrhh_sipe_sipe/features/attendance/widgets/attendance_common.dart';
import 'package:rrhh_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:rrhh_sipe_sipe/injection/get_it.dart';
import 'attendance_fixtures.dart';

class _Auth extends Fake implements AuthenticationRepository {}

AppSessionCubit session({bool manage = true}) =>
    AppSessionCubit(authRepository: _Auth())
      ..onSignedIn(UserSession(
          id: 'tester',
          username: 'Tester',
          isActive: true,
          permissions: ['rrhh.read', if (manage) 'rrhh.manage']));

Future<void> showMain(
    WidgetTester tester, AttendanceCubit cubit, AppSessionCubit app,
    {double width = 1440}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: app),
        BlocProvider.value(value: cubit),
        BlocProvider(create: (_) => SideMenuCubit())
      ],
      child: const MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  padding: EdgeInsets.all(16), child: AttendanceView())))));
  await tester.pumpAndSettle();
}

Future<void> showReport(WidgetTester tester, AttendanceReportCubit cubit,
    {double width = 1440}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  await tester.pumpWidget(BlocProvider.value(
      value: cubit,
      child: const MaterialApp(home: Scaffold(body: AttendanceReportView()))));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Solo lectura deshabilita guardado y sincronización',
      (tester) async {
    final repository = FakeAttendanceRepository();
    final cubit = AttendanceCubit(repository);
    final app = session(manage: false);
    await showMain(tester, cubit, app);
    final field = tester.widget<TextFormField>(
        find.byKey(const ValueKey('parameter-morning_entry_tolerance')));
    expect(field.enabled, isFalse);
    final save = find.ancestor(
        of: find.text('Guardar parámetros'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton));
    expect(tester.widget<OutlinedButton>(save).onPressed, isNull);
    expect(repository.saves, isEmpty);
    expect(repository.syncCalls, 0);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await app.close();
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'Mostrar minutos no pierde un segundo original al guardar sin cambios',
      (tester) async {
    final repository = FakeAttendanceRepository()
      ..parametersResult =
          ok(AttendanceParameters.fromJson(parameterJson(entry: 1)));
    final cubit = AttendanceCubit(repository);
    final app = session();
    await showMain(tester, cubit, app);
    await tester.ensureVisible(find.text('Guardar parámetros'));
    await tester.tap(find.text('Guardar parámetros'));
    await tester.pumpAndSettle();
    expect(repository.saves.single['morning_entry_tolerance'], 1);
    expect(repository.saves.single['valid_from'], '2026-10-01');
    expect(repository.saves.single['valid_to'], '2026-10-31');
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await app.close();
    await tester.binding.setSurfaceSize(null);
  });
  for (final width in [390.0, 900.0]) {
    testWidgets('Pantalla principal compacta sin overflow a $width',
        (tester) async {
      final cubit = AttendanceCubit(FakeAttendanceRepository());
      final app = session();
      await showMain(tester, cubit, app, width: width);
      cubit.selectFilter(contractId: 'contract-real');
      await cubit.generate();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
      await app.close();
      await tester.binding.setSurfaceSize(null);
    });
  }
  tearDown(() async {
    await sl.reset();
  });
  testWidgets('Parámetros se presentan en minutos y solo se guardan con botón',
      (tester) async {
    final repository = FakeAttendanceRepository();
    final cubit = AttendanceCubit(repository);
    final app = session();
    await showMain(tester, cubit, app);
    final field =
        find.byKey(const ValueKey('parameter-morning_entry_tolerance'));
    expect(tester.widget<TextFormField>(field).controller!.text, '5.0');
    await tester.enterText(field, '7.5');
    await tester.pump();
    expect(repository.saves, isEmpty);
    await tester.ensureVisible(find.text('Guardar parámetros'));
    await tester.tap(find.text('Guardar parámetros'));
    await tester.pumpAndSettle();
    expect(repository.saves.single['morning_entry_tolerance'], 450);
    expect(find.text('Parámetros guardados.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await app.close();
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('ready=false es informativo y no muestra tabla ficticia',
      (tester) async {
    final repository = FakeAttendanceRepository()
      ..generationResult =
          ok(AttendanceGeneration.fromJson(generationJson(ready: false)));
    final cubit = AttendanceCubit(repository);
    final app = session();
    await showMain(tester, cubit, app);
    cubit.selectFilter(contractId: 'contract-real');
    await cubit.generate();
    await tester.pumpAndSettle();
    expect(find.text('El reporte aún no puede evaluarse completamente.'),
        findsOneWidget);
    expect(find.textContaining('Política de corte contractual pendiente'),
        findsOneWidget);
    expect(find.text('Ana Pérez'), findsNothing);
    expect(repository.syncCalls, 0);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await app.close();
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Catálogo vacío no inventa contratos y deshabilita generación',
      (tester) async {
    final repository = FakeAttendanceRepository()
      ..catalog = AttendanceContracts.fromJson({
        'items': [],
        'pending_configuration': ['employee_contract_assignment']
      });
    final cubit = AttendanceCubit(repository);
    final app = session();
    await showMain(tester, cubit, app);
    expect(find.text('No hay tipos de contrato confirmados configurados.'),
        findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('attendance-generate')))
            .onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await app.close();
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
      'Listado compacto permite buscar y navegar con los filtros generados',
      (tester) async {
    final repository = FakeAttendanceRepository();
    final cubit = AttendanceCubit(repository, now: DateTime(2026, 10));
    final app = session();
    sl.registerFactory<AttendanceReportCubit>(
        () => AttendanceReportCubit(repository));
    await showMain(tester, cubit, app);
    cubit.selectFilter(contractId: 'contract-real');
    await cubit.generate();
    await tester.pumpAndSettle();
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Luis Rojas'), findsOneWidget);
    final search = find.byKey(const ValueKey('attendance-search'));
    await tester.ensureVisible(search);
    await tester.enterText(search, 'Finanzas');
    await tester.pumpAndSettle();
    expect(find.text('Luis Rojas'), findsNothing);
    await tester.ensureVisible(find.text('Ana Pérez'));
    await tester.tap(find.text('Ana Pérez'));
    await tester.pumpAndSettle();
    expect(find.byType(AttendanceReportPage), findsOneWidget);
    expect(repository.reports.single.$2.month, 10);
    expect(repository.reports.single.$2.contractId, 'contract-real');
    expect(repository.syncCalls, 0);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await app.close();
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Lista vacía y error backend tienen estados explícitos',
      (tester) async {
    final repository = FakeAttendanceRepository()
      ..generationResult =
          ok(AttendanceGeneration.fromJson(generationJson(empty: true)));
    final cubit = AttendanceCubit(repository);
    final app = session();
    await showMain(tester, cubit, app);
    cubit.selectFilter(contractId: 'contract-real');
    await cubit.generate();
    await tester.pumpAndSettle();
    expect(find.text('No hay funcionarios que coincidan con la búsqueda.'),
        findsOneWidget);
    repository.generationResult =
        const Err(ServerFailure('Backend no disponible'));
    await cubit.generate();
    await tester.pumpAndSettle();
    expect(find.text('Backend no disponible'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await app.close();
    await tester.binding.setSurfaceSize(null);
  });
  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('Calendario y detalle compartido sin overflow a $width',
        (tester) async {
      final cubit = AttendanceReportCubit(FakeAttendanceRepository());
      await cubit.load('employee-1', attendanceTestFilter);
      await showReport(tester, cubit, width: width);
      expect(find.byType(AttendanceCalendar), findsOneWidget);
      final cell = find.byKey(const ValueKey('calendar-2026-10-01'));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await tester.pumpAndSettle();
      expect(
          find.textContaining('Detalle del día · 01/10/2026'), findsOneWidget);
      expect(find.text('18:12:00'), findsOneWidget);
      expect(find.text('Atraso'), findsOneWidget);
      expect(find.text('Sugerencias del sistema'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
      await tester.binding.setSurfaceSize(null);
    });
  }
  testWidgets(
      'Reporte tabular abre el mismo detalle y no convierte null en cero',
      (tester) async {
    final cubit = AttendanceReportCubit(FakeAttendanceRepository());
    await cubit.load('employee-1', attendanceTestFilter);
    await showReport(tester, cubit);
    await tester.tap(find.text('Reporte'));
    await tester.pumpAndSettle();
    expect(find.text('HOJA INDIVIDUAL DE ASISTENCIA'), findsOneWidget);
    expect(find.text('01/10/2026'), findsOneWidget);
    await tester.ensureVisible(find.text('01/10/2026'));
    await tester.tap(find.text('01/10/2026'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Detalle del día · 01/10/2026'), findsOneWidget);
    expect(find.text('Salida anticipada: — min'), findsOneWidget);
    expect(find.text('Ausencia: — min'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Día NO_DATA y reporte sin días no presumen ausencia',
      (tester) async {
    final repository = FakeAttendanceRepository();
    final cubit = AttendanceReportCubit(repository);
    await cubit.load('employee-1', attendanceTestFilter);
    await showReport(tester, cubit);
    await tester.tap(find.byKey(const ValueKey('calendar-2026-10-02')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Esto no equivale a ausencia.'), findsOneWidget);
    repository.reportResult =
        ok(AttendanceReport.fromJson(reportJson(empty: true, ready: false)));
    await cubit.load('employee-1', attendanceTestFilter);
    await tester.pumpAndSettle();
    expect(find.text('No hay días disponibles para el período recibido.'),
        findsOneWidget);
    expect(find.text('El reporte aún no puede evaluarse completamente.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('Estados calendario corresponden a lo enviado por backend',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final cubit = AttendanceReportCubit(FakeAttendanceRepository());
    await cubit.load('employee-1', attendanceTestFilter);
    await showReport(tester, cubit);
    expect(find.bySemanticsLabel('01/10/2026 Observación'), findsOneWidget);
    expect(find.bySemanticsLabel('02/10/2026 Sin datos'), findsOneWidget);
    expect(find.byType(AttendanceStatusBadge),
        findsNothing); // No día seleccionado, sin estado recalculado.
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await tester.binding.setSurfaceSize(null);
    semantics.dispose();
  });
}
