import '../../biometric_import/entities/biometric_record.dart';
import '../../organization/entities/employee_admin.dart';
import '../entities/attendance_analysis.dart';

/// Lee referencias a originales; ordena copias, jamás corrige ni descarta marcas.
class AttendanceAnalyzer {
  const AttendanceAnalyzer();

  Future<ImportAttendanceAnalysis> analyze({
    required List<BiometricRecord> records,
    required AttendanceConfiguration configuration,
    List<EmployeeAdmin> employees = const [],
    String? lookupWarning,
  }) async {
    if (records.isEmpty) {
      return ImportAttendanceAnalysis(
          configuration: configuration,
          start: null,
          end: null,
          employees: const [],
          lookupWarning: lookupWarning);
    }
    final sorted = List<BiometricRecord>.of(records)..sort(_compare);
    final start = _date(sorted.first.timestamp);
    final end = _date(sorted.last.timestamp);
    final grouped = <String, Map<DateTime, List<BiometricRecord>>>{};
    for (final record in sorted) {
      grouped
          .putIfAbsent(record.employeeIdentifier, () => {})
          .putIfAbsent(_date(record.timestamp), () => [])
          .add(record);
    }
    final identities = <String, List<EmployeeAdmin>>{};
    for (final employee in employees) {
      final ci = employee.documentNumber?.trim();
      if (ci != null && ci.isNotEmpty) {
        identities.putIfAbsent(ci, () => []).add(employee);
      }
    }
    final result = <EmployeeAttendanceAnalysis>[];
    var processedDays = 0;
    for (final entry in grouped.entries) {
      final matches = identities[entry.key] ?? [];
      final days = <AttendanceDay>[];
      for (var day = start;
          !day.isAfter(end);
          day = DateTime(day.year, day.month, day.day + 1)) {
        days.add(analyzeDay(day, entry.value[day] ?? [], configuration));
        if (++processedDays % 100 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
      result.add(EmployeeAttendanceAnalysis(
          identifier: entry.key,
          employee: matches.length == 1 ? matches.single : null,
          identityMessage: matches.length == 1
              ? null
              : matches.length > 1
                  ? 'Más de un funcionario tiene este CI. Requiere revisión.'
                  : 'No se encontró un funcionario con este CI en el catálogo compartido.',
          days: days));
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return ImportAttendanceAnalysis(
        configuration: configuration,
        start: start,
        end: end,
        employees: result,
        lookupWarning: lookupWarning);
  }

  AttendanceDay analyzeDay(DateTime date, List<BiometricRecord> originals,
      AttendanceConfiguration config) {
    final records = List<BiometricRecord>.of(originals)..sort(_compare);
    final incidents = <AttendanceIncident>[];
    void add(IncidentType type, AttendanceStatus status, String message,
        {List<BiometricRecord> marks = const [], Duration? duration}) {
      incidents.add(AttendanceIncident(
          type: type,
          status: status,
          message: message,
          records: marks,
          duration: duration));
    }

    if (!config.hasSchedule) {
      add(IncidentType.configurationMissing, AttendanceStatus.observation,
          'Configure el horario para evaluar atrasos y marcaciones faltantes.');
    }
    final types = <String, List<BiometricRecord>>{};
    for (final record in records) {
      types.putIfAbsent(config.rawType(record).trim(), () => []).add(record);
    }
    for (final sameType in types.values) {
      var index = 0;
      while (index < sameType.length) {
        final cluster = <BiometricRecord>[sameType[index++]];
        while (index < sameType.length &&
            sameType[index].timestamp.difference(cluster.first.timestamp) <=
                config.duplicateWindow) {
          cluster.add(sameType[index++]);
        }
        if (cluster.length > 1) {
          final message =
              'Se detectaron ${cluster.length} marcaciones similares entre '
              '${_time(cluster.first.timestamp)} y ${_time(cluster.last.timestamp)}.';
          incidents.add(AttendanceIncident(
              type: IncidentType.possibleDuplicate,
              status: AttendanceStatus.observation,
              message: message,
              records: cluster,
              suggestion: AttendanceSuggestion(
                  message: 'Considerar ${_time(cluster.first.timestamp)} '
                      'como marcación principal. Requiere revisión; se conservan todas las marcas.',
                  principal: cluster.first,
                  records: cluster)));
        }
      }
    }
    final expected =
        config.hasSchedule && config.workingWeekdays.contains(date.weekday)
            ? config.expectedMarks
            : <ExpectedMark>[];
    final used = <int>{};
    final slotByRecord = <int, int>{};
    var lastIndex = -1;
    for (var slot = 0; slot < expected.length; slot++) {
      final mark = expected[slot];
      final target = DateTime(date.year, date.month, date.day)
          .add(Duration(minutes: mark.minuteOfDay));
      int? best;
      for (var i = lastIndex + 1; i < records.length; i++) {
        final direction = config.direction(records[i]);
        if (config.typeCodes.isNotEmpty && direction != mark.direction) {
          continue;
        }
        final delta = records[i].timestamp.difference(target).abs();
        // La cercanía solo sirve para asociar originales a un horario; nunca
        // determina una incidencia. El lado permitido de cada evento no está
        // limitado por la ventana (entrada anticipada / salida posterior).
        if (delta > config.matchingWindow &&
            !_allowedSide(records[i].timestamp, target, mark.direction,
                expected, slot, date)) {
          continue;
        }
        if (best == null ||
            delta < records[best].timestamp.difference(target).abs()) best = i;
      }
      if (best == null) {
        add(
            IncidentType.missingMark,
            AttendanceStatus.anomaly,
            'No se encontró una ${mark.direction == MarkDirection.entry ? 'entrada' : 'salida'} '
            'compatible con ${_time(target)} dentro de la ventana configurada.');
        continue;
      }
      used.add(best);
      slotByRecord[best] = slot;
      lastIndex = best;
      if (mark.direction == MarkDirection.entry) {
        final late = records[best]
            .timestamp
            .difference(target.add(config.lateTolerance));
        if (late > Duration.zero) {
          final isReturn = expected
              .take(slot)
              .any((previous) => previous.direction == MarkDirection.exit);
          add(
              isReturn ? IncidentType.lateReturn : IncidentType.late,
              AttendanceStatus.observation,
              '${isReturn ? 'Retorno tardío' : 'Atraso computable'}: ${_minutes(late)} min '
              'después de la tolerancia.',
              marks: [records[best]],
              duration: late);
        }
      } else {
        final early = target.difference(records[best].timestamp);
        if (early > Duration.zero) {
          add(IncidentType.earlyExit, AttendanceStatus.observation,
              'Salida anticipada: ${_minutes(early)} min antes del horario esperado.',
              marks: [records[best]], duration: early);
        }
      }
    }
    if (config.hasSchedule) {
      final extras = [
        for (var i = 0; i < records.length; i++)
          if (!used.contains(i)) records[i]
      ];
      if (extras.isNotEmpty) {
        add(IncidentType.extraMark, AttendanceStatus.observation,
            '${extras.length} marcaciones adicionales. No son automáticamente errores.',
            marks: extras);
      }
    }
    if (records.isNotEmpty && config.typeCodes.isEmpty) {
      add(IncidentType.configurationMissing, AttendanceStatus.observation,
          'Sin códigos de entrada/salida confirmados: no se evalúan salidas intermedias ni secuencias.');
    } else if (records.any((record) => config.direction(record) == null)) {
      add(IncidentType.unknownMarkType, AttendanceStatus.observation,
          'Existen tipos de marcación sin equivalencia configurada.',
          marks: records
              .where((record) => config.direction(record) == null)
              .toList());
    }
    for (var i = 1; i < records.length; i++) {
      final previous = config.direction(records[i - 1]);
      final current = config.direction(records[i]);
      if (previous == null || current == null) continue;
      final duration =
          records[i].timestamp.difference(records[i - 1].timestamp);
      if (previous == current && duration > config.duplicateWindow) {
        add(IncidentType.inconsistentSequence, AttendanceStatus.anomaly,
            'Marcaciones consecutivas del mismo sentido sin una intermedia.',
            marks: [records[i - 1], records[i]]);
      }
      if (previous == MarkDirection.exit && current == MarkDirection.entry) {
        final previousSlot = slotByRecord[i - 1];
        final currentSlot = slotByRecord[i];
        final scheduledBreak =
            previousSlot != null && currentSlot == previousSlot + 1;
        if (!scheduledBreak) {
          add(
              IncidentType.intermediateExit,
              AttendanceStatus.observation,
              'Salida y retorno intermedio: ${duration.inHours} h ${duration.inMinutes % 60} min. '
              'Revisar sin determinar la causa.',
              marks: [records[i - 1], records[i]],
              duration: duration);
        }
      }
    }
    return AttendanceDay(date: date, records: records, incidents: incidents);
  }

  static DateTime _date(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  // Evita atribuir una entrada de mañana a la tarde, o una salida final al
  // mediodía, al ampliar únicamente el lado permitido de la asociación.
  static bool _allowedSide(
      DateTime actual,
      DateTime target,
      MarkDirection direction,
      List<ExpectedMark> expected,
      int slot,
      DateTime date) {
    final midnight = _date(date);
    if (direction == MarkDirection.entry) {
      if (actual.isAfter(target)) return false;
      for (var i = slot - 1; i >= 0; i--) {
        if (expected[i].direction == direction) {
          final boundary = midnight.add(Duration(
              minutes:
                  (expected[i].minuteOfDay + expected[slot].minuteOfDay) ~/ 2));
          return !actual.isBefore(boundary);
        }
      }
      return !actual.isBefore(midnight);
    }
    if (actual.isBefore(target)) return false;
    for (var i = slot + 1; i < expected.length; i++) {
      if (expected[i].direction == direction) {
        final boundary = midnight.add(Duration(
            minutes:
                (expected[i].minuteOfDay + expected[slot].minuteOfDay) ~/ 2));
        return actual.isBefore(boundary);
      }
    }
    return actual.isBefore(DateTime(date.year, date.month, date.day + 1));
  }

  static String _minutes(Duration duration) =>
      duration.inSeconds / 60 == duration.inMinutes
          ? '${duration.inMinutes}'
          : (duration.inSeconds / 60).toStringAsFixed(2);
  static int _compare(BiometricRecord a, BiometricRecord b) {
    final time = a.timestamp.compareTo(b.timestamp);
    return time != 0 ? time : a.lineNumber.compareTo(b.lineNumber);
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
