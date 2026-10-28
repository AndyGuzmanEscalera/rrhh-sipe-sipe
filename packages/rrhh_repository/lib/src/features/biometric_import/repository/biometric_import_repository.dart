import 'dart:convert';
import 'package:failures/failures.dart';
import '../entities/biometric_record.dart';
import '../entities/biometric_parse_result.dart';
import '../services/biometric_parser.dart';

class BiometricImportRepository {
  const BiometricImportRepository(
      {BiometricParser parser = const BiometricParser()})
      : _parser = parser;
  final BiometricParser _parser;

  Future<Result<BiometricParseResult, Failure>> readFile(
      List<int> bytes) async {
    try {
      return ok(await _parser.parse(utf8.decode(bytes)));
    } on FormatException {
      return err(const ValidationFailure(
          'No se pudo leer el texto. El archivo debe estar codificado en UTF-8.'));
    } catch (_) {
      return err(const UnexpectedFailure(
          'No se pudo procesar el archivo biométrico. Intente seleccionarlo nuevamente.'));
    }
  }

  /// No hay endpoint de persistencia en la base actual.
  bool get supportsImport => false;

  /// Punto de extensión para un futuro contrato backend; no envía solicitudes.
  Future<Result<void, Failure>> importBiometricRecords(
          List<BiometricRecord> records) async =>
      err(const GenericFailure(
          'El guardado de marcaciones todavía no está disponible.'));
}
