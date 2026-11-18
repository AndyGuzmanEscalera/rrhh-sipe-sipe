import 'dart:convert';
import '../entities/biometric_record.dart';
import '../entities/biometric_parse_result.dart';

class BiometricParser {
  const BiometricParser();

  /// Se cede el control cada 500 líneas, también en Flutter Web.
  Future<BiometricParseResult> parse(String text) async {
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    final records = <BiometricRecord>[];
    final errors = <BiometricLineError>[];
    final identifiers = <String>{};
    var total = 0;
    var ignored = 0;
    DateTime? min;
    DateTime? max;
    for (final line in const LineSplitter().convert(text)) {
      total++;
      if (total % 500 == 0) await Future<void>.delayed(Duration.zero);
      if (line.trim().isEmpty) {
        ignored++;
        continue;
      }
      final fields = line.split('\t');
      String? reason;
      DateTime? timestamp;
      if (fields.length != 6) {
        reason =
            'Se esperaban 6 campos separados por tabulaciones; se encontraron ${fields.length}.';
      } else if (fields[0].trim().isEmpty) {
        reason = 'Identificador vacío.';
      } else {
        timestamp = _timestamp(fields[1].trim());
        if (timestamp == null) {
          reason =
              'Fecha inválida. Use yyyy-MM-dd HH:mm o yyyy-MM-dd HH:mm:ss.';
        }
      }
      if (reason != null) {
        errors.add(BiometricLineError(
            lineNumber: total, rawLine: line, reason: reason));
        continue;
      }
      final value = timestamp!;
      records.add(BiometricRecord(
          employeeIdentifier: fields[0],
          timestamp: value,
          field3: fields[2],
          field4: fields[3],
          field5: fields[4],
          field6: fields[5],
          rawLine: line,
          lineNumber: total));
      identifiers.add(fields[0]);
      if (min == null || value.isBefore(min)) min = value;
      if (max == null || value.isAfter(max)) max = value;
    }
    return BiometricParseResult(
        totalLines: total,
        ignoredLines: ignored,
        records: records,
        errors: errors,
        uniqueIdentifiers: identifiers.length,
        minTimestamp: min,
        maxTimestamp: max);
  }

  static final _datePattern =
      RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})(?::(\d{2}))?$');

  DateTime? _timestamp(String input) {
    final match = _datePattern.firstMatch(input);
    if (match == null) return null;
    final parts = [
      for (var i = 1; i <= 6; i++) int.parse(match.group(i) ?? '0')
    ];
    final year = parts[0], month = parts[1], day = parts[2];
    final hour = parts[3], minute = parts[4], second = parts[5];
    if (year < 1 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        hour > 23 ||
        minute > 59 ||
        second > 59) return null;
    // UTC se usa para validar el calendario, no para convertir la hora del archivo.
    final calendar = DateTime.utc(year, month, day, hour, minute, second);
    if (calendar.year != year ||
        calendar.month != month ||
        calendar.day != day) {
      return null;
    }
    return calendar;
  }
}
