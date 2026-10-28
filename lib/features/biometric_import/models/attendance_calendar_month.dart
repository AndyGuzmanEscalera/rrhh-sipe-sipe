import 'package:rrhh_repository/rrhh_repository.dart';

enum CalendarDayStatus { normal, observation, anomaly, noData }

class AttendanceCalendarDay {
  AttendanceCalendarDay({required this.date, required this.analysis});
  final DateTime date;
  final AttendanceDay? analysis;
  CalendarDayStatus get status {
    final day = analysis;
    if (day == null || (day.records.isEmpty && day.incidents.isEmpty)) {
      return CalendarDayStatus.noData;
    }
    return switch (day.status) {
      AttendanceStatus.normal => CalendarDayStatus.normal,
      AttendanceStatus.observation => CalendarDayStatus.observation,
      AttendanceStatus.anomaly => CalendarDayStatus.anomaly,
    };
  }
}

/// Solo proyecta análisis existentes dentro del rango; no ejecuta reglas.
class AttendanceCalendarMonth {
  AttendanceCalendarMonth(
      {required DateTime month,
      required EmployeeAttendanceAnalysis employee,
      required ImportAttendanceAnalysis importAnalysis})
      : month = DateTime(month.year, month.month) {
    final indexed = {
      for (final day in employee.days)
        DateTime(day.date.year, day.date.month, day.date.day): day
    };
    final start = importAnalysis.start;
    final end = importAnalysis.end;
    final first =
        start == null ? null : DateTime(start.year, start.month, start.day);
    final last = end == null ? null : DateTime(end.year, end.month, end.day);
    days = List.unmodifiable(
        List.generate(DateTime(month.year, month.month + 1, 0).day, (index) {
      final date = DateTime(month.year, month.month, index + 1);
      final inRange = first != null &&
          last != null &&
          !date.isBefore(first) &&
          !date.isAfter(last);
      return AttendanceCalendarDay(
          date: date, analysis: inRange ? indexed[date] : null);
    }));
  }
  final DateTime month;
  late final List<AttendanceCalendarDay> days;
  int get leadingEmptyCells => month.weekday - 1;
  int get cellCount => ((leadingEmptyCells + days.length) / 7).ceil() * 7;
  int count(CalendarDayStatus status) =>
      days.where((day) => day.status == status).length;
}
