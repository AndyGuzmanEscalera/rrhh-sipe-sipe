/// Una marcación sin interpretación de los campos propios del dispositivo.
class BiometricRecord {
  const BiometricRecord(
      {required this.employeeIdentifier,
      required this.timestamp,
      required this.field3,
      required this.field4,
      required this.field5,
      required this.field6,
      required this.rawLine,
      required this.lineNumber});

  final String employeeIdentifier;
  final DateTime timestamp;
  final String field3;
  final String field4;
  final String field5;
  final String field6;

  /// Línea original, sin el separador de líneas; no se recorta ni reconstruye.
  final String rawLine;
  final int lineNumber;
}
