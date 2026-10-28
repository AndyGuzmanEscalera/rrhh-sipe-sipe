import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_api/rrhh_api.dart';
import '../../../test/features/attendance/attendance_fixtures.dart';

class _Api extends Fake implements AttendanceApi {
  @override
  Future<Map<String, dynamic>> generate(
          {required String contractId,
          required int year,
          required int month}) async =>
      generationJson(ready: false);
  @override
  Future<Map<String, dynamic>> latestSync() async => {'sync': null};
}

void main() {
  test(
      'Repository conserva ready=false como Ok y admite última sincronización vacía',
      () async {
    final repository = AttendanceRepository(api: _Api());
    final generation = await repository.generate(attendanceTestFilter);
    expect(generation.isOk, isTrue);
    expect(generation.valueOrNull()!.ready, isFalse);
    expect((await repository.latestSync()).isOk, isTrue);
    expect((await repository.latestSync()).valueOrNull(), isNull);
  });
  test('Modelos conservan null, códigos originales, sugerencias y fecha local',
      () {
    final report = AttendanceReport.fromJson(reportJson());
    final day = report.days.first;
    expect(day.earlyMinutes, isNull);
    expect(day.absenceMinutes, isNull);
    expect(day.finalExit, isNull);
    expect(day.records.length, 6);
    expect(day.records.first.status, 89);
    expect(day.records.first.punch, 42);
    expect(day.records.first.timestamp.isUtc, isFalse);
    expect(day.records.first.timestamp.hour, 8);
    expect(day.suggestions.single.suggestedRecordId, 'record-3');
    expect(report.calendar.first.incidentCount, 2);
    expect(report.employee.itemCode, isNull);
  });
  test('Estado general no se reconstruye a partir del resumen en Flutter', () {
    final response = generationJson();
    final result = AttendanceGeneration.fromJson(response);
    expect(result.employees[1].summary!.anomalies, 0);
    expect(result.employees[1].status, 'ANOMALY');
  });
}
