import 'dart:async';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/features/attendance/cubit/attendance_cubit.dart';
import 'package:rrhh_sipe_sipe/features/attendance/cubit/attendance_report_cubit.dart';
import 'attendance_fixtures.dart';

void main() {
  test('Catálogo actualizado elimina una selección que dejó de existir',
      () async {
    final repository = FakeAttendanceRepository();
    final cubit = AttendanceCubit(repository);
    await cubit.initialize();
    cubit.selectFilter(contractId: 'contract-real');
    await cubit.generate();
    repository.catalog = AttendanceContracts.fromJson(
        {'items': [], 'pending_configuration': []});
    await cubit.loadContracts();
    expect(cubit.state.contractId, isNull);
    expect(cubit.state.generation, isNull);
    await cubit.close();
  });
  test('Carga parámetros y catálogo una sola vez, sin sincronizar ni generar',
      () async {
    final repository = FakeAttendanceRepository();
    final cubit = AttendanceCubit(repository, now: DateTime(2026, 10));
    await cubit.initialize();
    await cubit.initialize();
    expect(cubit.state.parameters!.seconds['minimum_return_interval'], 1800);
    expect(repository.parameterCalls, 1);
    expect(repository.syncCalls, 0);
    expect(repository.generateCalls, 0);
    await cubit.close();
  });
  test('Guardar es explícito y conserva segundos', () async {
    final repository = FakeAttendanceRepository();
    final cubit = AttendanceCubit(repository);
    await cubit.initialize();
    cubit.parametersDirty(true);
    expect(repository.saves, isEmpty);
    await cubit.saveParameters({'for-test': 90});
    expect(repository.saves.single['for-test'], 90);
    expect(cubit.state.dirty, isFalse);
    await cubit.close();
  });
  test('ready=false es un resultado informativo', () async {
    final repository = FakeAttendanceRepository()
      ..generationResult =
          ok(AttendanceGeneration.fromJson(generationJson(ready: false)));
    final cubit = AttendanceCubit(repository);
    cubit.selectFilter(contractId: 'contract-real');
    await cubit.generate();
    expect(cubit.state.resultError, isEmpty);
    expect(cubit.state.generation!.ready, isFalse);
    expect(cubit.state.generation!.pending, contains('employee_shift_source'));
    expect(repository.syncCalls, 0);
    await cubit.close();
  });
  test(
      'Generación evita doble solicitud y bloquea filtros mientras está activa',
      () async {
    final pending = Completer<Result<AttendanceGeneration, Failure>>();
    final repository = FakeAttendanceRepository()
      ..generateOverride = () => pending.future;
    final cubit = AttendanceCubit(repository, now: DateTime(2026, 10));
    cubit.selectFilter(contractId: 'contract-real');
    final first = cubit.generate();
    await cubit.generate();
    cubit.selectFilter(month: 11);
    expect(repository.generateCalls, 1);
    expect(cubit.state.month, 10);
    pending.complete(ok(AttendanceGeneration.fromJson(generationJson())));
    await first;
    expect(cubit.state.generation!.employees.length, 2);
    await cubit.close();
  });
  test('Búsqueda por nombre, documento y unidad es solo presentación',
      () async {
    final cubit = AttendanceCubit(FakeAttendanceRepository());
    cubit.selectFilter(contractId: 'contract-real');
    await cubit.generate();
    for (final query in ['Ana', '123456', 'Finanzas']) {
      cubit.search(query);
      expect(cubit.state.filtered.single.employee.id, 'employee-1');
    }
    cubit.search('inexistente');
    expect(cubit.state.filtered, isEmpty);
    await cubit.close();
  });
  test('Cambiar filtros descarta resultados anteriores y no descarga datos',
      () async {
    final repository = FakeAttendanceRepository();
    final cubit = AttendanceCubit(repository);
    cubit.selectFilter(contractId: 'contract-real');
    await cubit.generate();
    cubit.selectFilter(year: 2025);
    expect(cubit.state.generation, isNull);
    expect(repository.syncCalls, 0);
    await cubit.close();
  });
  test('Parámetros sin guardar impiden generación', () async {
    final repository = FakeAttendanceRepository();
    final cubit = AttendanceCubit(repository);
    cubit.selectFilter(contractId: 'contract-real');
    cubit.parametersDirty(true);
    await cubit.generate();
    expect(repository.generateCalls, 0);
    await cubit.close();
  });
  testWidgets(
      'Sincronización consulta el trabajo hasta completarlo, sin generar',
      (tester) async {
    final repository = FakeAttendanceRepository();
    final cubit =
        AttendanceCubit(repository, pollInterval: const Duration(seconds: 1));
    await cubit.synchronize(DateTime(2026, 10, 1), DateTime(2026, 10, 2));
    await cubit.synchronize(DateTime(2026, 10, 1), DateTime(2026, 10, 2));
    expect(repository.syncCalls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(cubit.state.sync!.status, 'completed');
    expect(cubit.state.needsRefresh, isTrue);
    expect(repository.generateCalls, 0);
    await cubit.close();
  });
  testWidgets('Cerrar cubit cancela seguimiento del trabajo', (tester) async {
    final repository = FakeAttendanceRepository();
    final cubit =
        AttendanceCubit(repository, pollInterval: const Duration(seconds: 1));
    await cubit.synchronize(DateTime(2026, 10, 1), DateTime(2026, 10, 2));
    await cubit.close();
    await tester.pump(const Duration(seconds: 3));
    expect(repository.statusCalls, 0);
  });
  test('Error de backend no inventa resultados', () async {
    final repository = FakeAttendanceRepository()
      ..generationResult = const Err(ServerFailure('Servicio no disponible'));
    final cubit = AttendanceCubit(repository);
    cubit.selectFilter(contractId: 'contract-real');
    await cubit.generate();
    expect(cubit.state.resultError, 'Servicio no disponible');
    expect(cubit.state.generation, isNull);
    await cubit.close();
  });
  test('Detalle consume ID y filtros originales', () async {
    final repository = FakeAttendanceRepository();
    final cubit = AttendanceReportCubit(repository);
    await cubit.load('employee-1', attendanceTestFilter);
    cubit.selectDay(DateTime(2026, 10, 1));
    expect(repository.reports.single.$1, 'employee-1');
    expect(repository.reports.single.$2, same(attendanceTestFilter));
    expect(cubit.state.selectedDay!.records.length, 6);
    await cubit.close();
  });
}
