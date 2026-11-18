import 'dart:convert';
import 'package:failures/failures.dart';
import 'package:rrhh_api/rrhh_api.dart';
import '../entities/biometric_column_mapping.dart';
import '../entities/biometric_import_batch.dart';
import '../entities/biometric_import_result.dart';
import '../entities/biometric_parse_result.dart';
import '../entities/biometric_raw_record.dart';
import '../entities/biometric_record.dart';
import '../services/biometric_parser.dart';

/// Importación biométrica: archivo TXT y evidencia en bruto.
///
/// El repositorio no interpreta marcaciones. Sólo lee el archivo, envía los
/// valores observados y devuelve el resumen del lote.
class BiometricImportRepository {
  const BiometricImportRepository({
    BiometricParser parser = const BiometricParser(),
    BiometricImportApi? api,
  })  : _parser = parser,
        _api = api;
  final BiometricParser _parser;
  final BiometricImportApi? _api;

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

  /// El guardado en el servidor está disponible.
  bool get supportsImport => _api != null;

  /// Envía las marcaciones del archivo. Los valores viajan como fueron leídos.
  Future<Result<BiometricImportResult, Failure>> importRecords({
    required String deviceId,
    required List<BiometricRecord> records,
    required BiometricColumnMapping mapping,
    String? sourceFileName,
    int? receivedRecords,
    int errorRecords = 0,
  }) =>
      _read('importRecords', () async {
        final api = _requireApi();
        final payload = <Map<String, Object?>>[];
        var invalid = 0;
        for (final record in records) {
          final canonical = mapping.toApiRecord(record);
          if (canonical == null) {
            invalid++;
            continue;
          }
          payload.add(canonical);
        }
        if (payload.length > 10000) {
          throw const ValidationFailure(
              'El archivo contiene más de 10.000 marcaciones. Divídalo en dos o más archivos.');
        }
        final json = await api.importRecords(
          deviceId: deviceId,
          records: payload,
          sourceFileName: sourceFileName,
          receivedRecords: receivedRecords,
          errorRecords: errorRecords + invalid,
        );
        return BiometricImportResult.fromJson(json);
      });

  /// Historial de lotes de importación y de sincronizaciones.
  Future<Result<BiometricBatchPage, Failure>> history({
    int page = 1,
    int pageSize = 20,
    String? origin,
  }) =>
      _read('history', () async {
        final api = _requireApi();
        final json =
            await api.history(page: page, pageSize: pageSize, origin: origin);
        final items = (json['items'] as List? ?? const [])
            .map((e) => BiometricImportBatch.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(growable: false);
        return (items: items, total: (json['total'] as int?) ?? items.length);
      });

  /// Marcaciones en bruto, sin evaluación de asistencia.
  Future<Result<List<BiometricRawRecord>, Failure>> rawRecords({
    String? fromDate,
    String? toDate,
    String? userId,
    String? deviceId,
    String? source,
    String? batchId,
    int limit = 50,
    int offset = 0,
  }) =>
      _read('rawRecords', () async {
        final api = _requireApi();
        final json = await api.rawRecords(
          fromDate: fromDate,
          toDate: toDate,
          userId: userId,
          deviceId: deviceId,
          source: source,
          batchId: batchId,
          limit: limit,
          offset: offset,
        );
        final items = (json['records'] as List? ?? const [])
            .map((e) => BiometricRawRecord.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(growable: false);
        return items;
      });

  /// Dispositivos conocidos.
  Future<Result<List<String>, Failure>> devices() => _read('devices', () async {
        final api = _requireApi();
        final json = await api.devices();
        return (json['items'] as List)
            .whereType<Map>()
            .map((e) => e['device_id'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toList(growable: false);
      });

  /// Solicita una sincronización desde el dispositivo biométrico.
  Future<Result<BiometricImportBatch, Failure>> synchronize({
    required String start,
    required String end,
  }) =>
      _read('synchronize', () async {
        final api = _requireApi();
        return BiometricImportBatch.fromJson(
            await api.synchronize(start: start, end: end));
      });

  /// Estado de una sincronización.
  Future<Result<BiometricImportBatch, Failure>> syncStatus(String id) =>
      _read('syncStatus', () async {
        return BiometricImportBatch.fromJson(await _requireApi().batch(id));
      });

  BiometricImportApi _requireApi() {
    final api = _api;
    if (api == null) {
      throw const GenericFailure(
          'El servicio de importación biométrica no está disponible.');
    }
    return api;
  }

  Future<Result<T, Failure>> _read<T>(
      String operation, Future<T> Function() action) async {
    return handleExceptions(action,
        feature: 'biometricImport', operation: operation);
  }
}
