import 'biometric_record.dart';

/// Campo adicional del archivo de exportación.
///
/// El archivo tiene seis campos: identificador, fecha/hora y cuatro campos
/// adicionales. El operador declara qué campo contiene cada código crudo.
enum BiometricColumn { none, field3, field4, field5, field6 }

/// Correspondencia entre las columnas del archivo y los valores en bruto.
///
/// El módulo no infiere el significado de ninguna columna ni traduce los
/// códigos: sólo copia los valores que el operador indica.
class BiometricColumnMapping {
  const BiometricColumnMapping({
    this.status = BiometricColumn.field3,
    this.punch = BiometricColumn.field4,
    this.uid = BiometricColumn.none,
  });

  final BiometricColumn status;
  final BiometricColumn punch;
  final BiometricColumn uid;

  BiometricColumnMapping copyWith({
    BiometricColumn? status,
    BiometricColumn? punch,
    BiometricColumn? uid,
  }) =>
      BiometricColumnMapping(
        status: status ?? this.status,
        punch: punch ?? this.punch,
        uid: uid ?? this.uid,
      );

  /// Valor crudo del campo seleccionado, sin transformación.
  String? read(BiometricRecord record, BiometricColumn column) {
    switch (column) {
      case BiometricColumn.none:
        return null;
      case BiometricColumn.field3:
        return record.field3;
      case BiometricColumn.field4:
        return record.field4;
      case BiometricColumn.field5:
        return record.field5;
      case BiometricColumn.field6:
        return record.field6;
    }
  }

  /// Registro canónico para la API, o `null` si el campo declarado no es un
  /// entero válido. La validación es técnica; no interpreta el código.
  Map<String, Object?>? toApiRecord(BiometricRecord record) {
    final statusValue = _asInt(read(record, status));
    final punchValue = _asInt(read(record, punch));
    final uidValue = _asInt(read(record, uid));
    if (_invalid(read(record, status), statusValue) ||
        _invalid(read(record, punch), punchValue) ||
        _invalid(read(record, uid), uidValue)) {
      return null;
    }
    return {
      'user_id': record.employeeIdentifier,
      'timestamp': formatDeviceTime(record.timestamp),
      'status': statusValue,
      'punch': punchValue,
      'uid': uidValue,
      'raw_line': record.rawLine,
      'line_number': record.lineNumber,
    };
  }

  static int? _asInt(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed, radix: 10);
  }

  static bool _invalid(String? raw, int? value) =>
      raw != null &&
      raw.trim().isNotEmpty &&
      (value == null || value < -2147483648 || value > 2147483647);
}

/// Hora local del dispositivo: sin zona y con precisión de segundos.
String formatDeviceTime(DateTime value) {
  final iso = value.toIso8601String();
  final dot = iso.indexOf('.');
  return dot < 0 ? iso : iso.substring(0, dot);
}
