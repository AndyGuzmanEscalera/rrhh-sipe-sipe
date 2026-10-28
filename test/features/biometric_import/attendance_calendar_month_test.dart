import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/models/attendance_calendar_month.dart';

void main() {
  AttendanceDay day(int number,
          {IncidentType? incident, bool hasMark = true}) =>
      AttendanceDay(
          date: DateTime(2026, 9, number),
          records: hasMark
              ? [
                  BiometricRecord(
                      employeeIdentifier: '123',
                      timestamp: DateTime(2026, 9, number, 8),
                      field3: '1',
                      field4: 'E',
                      field5: 'X',
                      field6: '0',
                      rawLine: 'original-$number',
                      lineNumber: number)
                ]
              : [],
          incidents: incident == null
              ? []
              : [
                  AttendanceIncident(
                      type: incident,
                      status: incident == IncidentType.late
                          ? AttendanceStatus.observation
                          : AttendanceStatus.anomaly,
                      message: 'Incidencia')
                ]);
  final employee = EmployeeAttendanceAnalysis(
      identifier: '123',
      identityMessage: null,
      days: [
        day(1, incident: IncidentType.missingMark),
        day(2),
        day(3, incident: IncidentType.late),
        day(4, incident: IncidentType.missingMark, hasMark: false),
        day(5, hasMark: false),
        day(30, incident: IncidentType.missingMark)
      ]);
  final report = ImportAttendanceAnalysis(
      configuration: AttendanceConfiguration(),
      start: DateTime(2026, 9, 2, 8),
      end: DateTime(2026, 9, 5, 18),
      employees: [employee]);
  test('Solo proyecta días dentro del rango y conserva faltantes como anomalía',
      () {
    final month = AttendanceCalendarMonth(
        month: DateTime(2026, 9), employee: employee, importAnalysis: report);
    expect(month.days.length, 30);
    expect(month.leadingEmptyCells, 1);
    expect(month.cellCount, 35);
    expect(month.days[0].status, CalendarDayStatus.noData);
    expect(month.days[29].status, CalendarDayStatus.noData);
    expect(month.days[3].status, CalendarDayStatus.anomaly);
    expect(month.days[4].status, CalendarDayStatus.noData);
    expect(month.count(CalendarDayStatus.normal), 1);
    expect(month.count(CalendarDayStatus.observation), 1);
    expect(month.count(CalendarDayStatus.anomaly), 1);
    expect(month.days[1].analysis, same(employee.days[1]));
    expect(employee.days.first.status, AttendanceStatus.anomaly);
    expect(employee.days[1].records.single.rawLine, 'original-2');
  });
  test('Mes fuera del archivo y febrero bisiesto son solo celdas sin datos',
      () {
    final month = AttendanceCalendarMonth(
        month: DateTime(2024, 2), employee: employee, importAnalysis: report);
    expect(month.days.length, 29);
    expect(month.days.every((day) => day.status == CalendarDayStatus.noData),
        isTrue);
    expect(month.count(CalendarDayStatus.anomaly), 0);
  });
}
