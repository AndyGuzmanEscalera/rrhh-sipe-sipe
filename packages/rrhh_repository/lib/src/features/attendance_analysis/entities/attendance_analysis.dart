import '../../biometric_import/entities/biometric_record.dart';
import '../../organization/entities/employee_admin.dart';

enum AttendanceStatus { normal, observation, anomaly }

enum IncidentType {
  late,
  earlyExit,
  lateReturn,
  missingMark,
  extraMark,
  possibleDuplicate,
  intermediateExit,
  inconsistentSequence,
  configurationMissing,
  unknownMarkType,
}

enum MarkDirection { entry, exit }

enum SuggestionReviewStatus { pending, accepted, ignored }

enum BiometricTypeField { field3, field4, field5, field6 }

class ExpectedMark {
  const ExpectedMark({required this.minuteOfDay, required this.direction});
  final int minuteOfDay;
  final MarkDirection direction;
}

/// Configuración explícita. Sin horario confirmado no se declara jornada normal.
class AttendanceConfiguration {
  AttendanceConfiguration({
    List<ExpectedMark> expectedMarks = const [],
    Set<int> workingWeekdays = const {1, 2, 3, 4, 5},
    this.lateTolerance = const Duration(minutes: 5),
    this.duplicateWindow = const Duration(minutes: 5),
    this.matchingWindow = const Duration(minutes: 90),
    this.typeField = BiometricTypeField.field4,
    Map<String, MarkDirection> typeCodes = const {},
  })  : expectedMarks = List.unmodifiable(expectedMarks),
        workingWeekdays = Set.unmodifiable(workingWeekdays),
        typeCodes = Map.unmodifiable(typeCodes) {
    if (lateTolerance.isNegative ||
        duplicateWindow.isNegative ||
        matchingWindow <= Duration.zero ||
        workingWeekdays.any((d) => d < 1 || d > 7)) {
      throw ArgumentError('Tolerancias, ventanas o días inválidos.');
    }
    var previous = -1;
    for (final mark in expectedMarks) {
      if (mark.minuteOfDay <= previous || mark.minuteOfDay >= 1440) {
        throw ArgumentError(
            'Los horarios deben ser crecientes dentro del día.');
      }
      previous = mark.minuteOfDay;
    }
    if (typeCodes.keys.any((code) => code.trim().isEmpty)) {
      throw ArgumentError('Un código de tipo no puede estar vacío.');
    }
  }
  final List<ExpectedMark> expectedMarks;
  final Set<int> workingWeekdays;
  final Duration lateTolerance;
  final Duration duplicateWindow;
  final Duration matchingWindow;
  final BiometricTypeField typeField;
  final Map<String, MarkDirection> typeCodes;
  bool get hasSchedule => expectedMarks.isNotEmpty;
  String rawType(BiometricRecord record) => switch (typeField) {
        BiometricTypeField.field3 => record.field3,
        BiometricTypeField.field4 => record.field4,
        BiometricTypeField.field5 => record.field5,
        BiometricTypeField.field6 => record.field6,
      };
  MarkDirection? direction(BiometricRecord record) =>
      typeCodes[rawType(record).trim()];
}

class AttendanceSuggestion {
  AttendanceSuggestion({
    required this.message,
    required this.principal,
    required List<BiometricRecord> records,
    this.reviewStatus = SuggestionReviewStatus.pending,
  }) : records = List.unmodifiable(records);
  final String message;
  final BiometricRecord principal;
  final List<BiometricRecord> records;
  final SuggestionReviewStatus reviewStatus;
}

class AttendanceIncident {
  AttendanceIncident({
    required this.type,
    required this.status,
    required this.message,
    List<BiometricRecord> records = const [],
    this.duration,
    this.suggestion,
  }) : records = List.unmodifiable(records);
  final IncidentType type;
  final AttendanceStatus status;
  final String message;
  final List<BiometricRecord> records;
  final Duration? duration;
  final AttendanceSuggestion? suggestion;
}

class AttendanceDay {
  AttendanceDay({
    required this.date,
    required List<BiometricRecord> records,
    required List<AttendanceIncident> incidents,
  })  : records = List.unmodifiable(records),
        incidents = List.unmodifiable(incidents);
  final DateTime date;
  final List<BiometricRecord> records;
  final List<AttendanceIncident> incidents;
  AttendanceStatus get status =>
      incidents.any((i) => i.status == AttendanceStatus.anomaly)
          ? AttendanceStatus.anomaly
          : incidents.isNotEmpty
              ? AttendanceStatus.observation
              : AttendanceStatus.normal;
}

class AttendanceWeek {
  AttendanceWeek({required this.number, required List<AttendanceDay> days})
      : days = List.unmodifiable(days);
  final int number;
  final List<AttendanceDay> days;
  DateTime get start => days.first.date;
  DateTime get end => days.last.date;
}

class EmployeeAttendanceAnalysis {
  EmployeeAttendanceAnalysis({
    required this.identifier,
    this.employee,
    required this.identityMessage,
    required List<AttendanceDay> days,
  }) : days = List.unmodifiable(days);
  final String identifier;
  final EmployeeAdmin? employee;
  final String? identityMessage;
  final List<AttendanceDay> days;
  int count(AttendanceStatus status) =>
      days.where((day) => day.status == status).length;
  int get totalMarks =>
      days.fold(0, (total, day) => total + day.records.length);
  String get name => employee?.fullName ?? 'Identificador sin vincular';
  List<AttendanceWeek> get weeks {
    final groups = <DateTime, List<AttendanceDay>>{};
    for (final day in days) {
      final monday = DateTime(
          day.date.year, day.date.month, day.date.day - day.date.weekday + 1);
      groups.putIfAbsent(monday, () => []).add(day);
    }
    var number = 0;
    return List.unmodifiable(groups.values
        .map((days) => AttendanceWeek(number: ++number, days: days)));
  }
}

class ImportAttendanceAnalysis {
  ImportAttendanceAnalysis({
    required this.configuration,
    required this.start,
    required this.end,
    required List<EmployeeAttendanceAnalysis> employees,
    this.lookupWarning,
  }) : employees = List.unmodifiable(employees);
  final AttendanceConfiguration configuration;
  final DateTime? start;
  final DateTime? end;
  final List<EmployeeAttendanceAnalysis> employees;
  final String? lookupWarning;
}
