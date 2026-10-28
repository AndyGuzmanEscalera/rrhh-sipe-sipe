import '../entities/attendance_analysis.dart';

/// Traduce el formulario de configuración sin acoplar reglas a los widgets.
class AttendanceConfigurationParser {
  const AttendanceConfigurationParser();
  AttendanceConfiguration parse({
    required String schedule,
    required Set<int> weekdays,
    required String toleranceMinutes,
    required String duplicateMinutes,
    required String matchingMinutes,
    required BiometricTypeField typeField,
    required String entryCodes,
    required String exitCodes,
  }) {
    int minutes(String text, String label, {bool positive = false}) {
      final value = int.tryParse(text.trim());
      if (value == null || value < (positive ? 1 : 0) || value > 1440) {
        throw FormatException('$label: ingrese minutos válidos (máximo 1440).');
      }
      return value;
    }

    final marks = <ExpectedMark>[];
    for (final line
        in schedule.split('\n').where((line) => line.trim().isNotEmpty)) {
      final match = RegExp(r'^(\d{2}):(\d{2})\s+([ES])$', caseSensitive: false)
          .firstMatch(line.trim());
      if (match == null) {
        throw const FormatException(
            'Horario: use una línea por marca, por ejemplo 08:00 E o 18:00 S.');
      }
      final hour = int.parse(match[1]!);
      final minute = int.parse(match[2]!);
      if (hour > 23 || minute > 59) {
        throw const FormatException('Hora inválida en el horario.');
      }
      marks.add(ExpectedMark(
          minuteOfDay: hour * 60 + minute,
          direction: match[3]!.toUpperCase() == 'E'
              ? MarkDirection.entry
              : MarkDirection.exit));
    }
    if (marks.isNotEmpty && weekdays.isEmpty) {
      throw const FormatException('Seleccione los días del horario.');
    }
    final codes = <String, MarkDirection>{};
    void addCodes(String text, MarkDirection direction) {
      for (final code
          in text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
        if (codes.containsKey(code)) {
          throw const FormatException(
              'Los códigos de entrada y salida deben ser distintos, sin repetir.');
        }
        codes[code] = direction;
      }
    }

    addCodes(entryCodes, MarkDirection.entry);
    addCodes(exitCodes, MarkDirection.exit);
    if (codes.isNotEmpty &&
        (!codes.values.contains(MarkDirection.entry) ||
            !codes.values.contains(MarkDirection.exit))) {
      throw const FormatException(
          'Configure códigos tanto de entrada como de salida, o deje ambos vacíos.');
    }
    try {
      return AttendanceConfiguration(
          expectedMarks: marks,
          workingWeekdays: weekdays,
          lateTolerance:
              Duration(minutes: minutes(toleranceMinutes, 'Tolerancia')),
          duplicateWindow: Duration(
              minutes: minutes(duplicateMinutes, 'Ventana de duplicados')),
          matchingWindow: Duration(
              minutes: minutes(matchingMinutes, 'Ventana de asociación',
                  positive: true)),
          typeField: typeField,
          typeCodes: codes);
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }
}
