import 'biometric_record.dart';

class BiometricLineError {
  const BiometricLineError(
      {required this.lineNumber, required this.rawLine, required this.reason});
  final int lineNumber;
  final String rawLine;
  final String reason;
}

class BiometricParseResult {
  BiometricParseResult(
      {required this.totalLines,
      required this.ignoredLines,
      required List<BiometricRecord> records,
      required List<BiometricLineError> errors,
      required this.uniqueIdentifiers,
      this.minTimestamp,
      this.maxTimestamp})
      : records = List.unmodifiable(records),
        errors = List.unmodifiable(errors);

  final int totalLines;
  final int ignoredLines;
  final List<BiometricRecord> records;
  final List<BiometricLineError> errors;
  final int uniqueIdentifiers;
  final DateTime? minTimestamp;
  final DateTime? maxTimestamp;
  int get foundRecords => records.length + errors.length;
}
