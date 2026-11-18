import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';

/// Importación biométrica: archivo TXT, lotes y evidencia en bruto.
///
/// La API no interpreta: devuelve los valores observados tal como llegan.
class BiometricImportApi {
  BiometricImportApi({required ApiMethod mainApi}) : _api = mainApi;
  final ApiMethod _api;

  /// Envía marcaciones ya normalizadas por el lector de archivo.
  Future<Map<String, dynamic>> importRecords({
    required String deviceId,
    required List<Map<String, Object?>> records,
    String? sourceFileName,
    int? receivedRecords,
    int errorRecords = 0,
  }) =>
      _api.requestWithoutBodyLogging(
        Endpoints.biometricImport,
        method: 'POST',
        data: {
          'device_id': deviceId,
          'records': records,
          if (sourceFileName != null) 'source_file_name': sourceFileName,
          if (receivedRecords != null) 'received_records': receivedRecords,
          'error_records': errorRecords,
        },
        operation: 'biometric.import',
      );

  /// Historial de lotes (archivo y sincronizaciones).
  Future<Map<String, dynamic>> history({
    int page = 1,
    int pageSize = 20,
    String? origin,
  }) =>
      _api.get(
        Endpoints.biometricSyncs,
        queryParameters: {
          'limit': pageSize,
          'offset': (page - 1) * pageSize,
          if (origin != null) 'origin': origin,
        },
        operation: 'biometric.syncs',
      );

  Future<Map<String, dynamic>> synchronize({
    required String start,
    required String end,
  }) =>
      _api.post(Endpoints.biometricSync,
          data: {'start_date': start, 'end_date': end},
          operation: 'biometric.sync');

  Future<Map<String, dynamic>> batch(String id) =>
      _api.get(Endpoints.biometricSyncStatus(id), operation: 'biometric.batch');

  /// Marcaciones en bruto para inspección administrativa.
  Future<Map<String, dynamic>> rawRecords({
    String? fromDate,
    String? toDate,
    String? userId,
    String? deviceId,
    String? source,
    String? batchId,
    int limit = 50,
    int offset = 0,
  }) =>
      _api.requestWithoutBodyLogging(
        Endpoints.biometricRecords,
        method: 'GET',
        queryParameters: {
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
          if (userId != null) 'user_id': userId,
          if (deviceId != null) 'device_id': deviceId,
          if (source != null) 'source': source,
          if (batchId != null) 'batch_id': batchId,
          'limit': limit,
          'offset': offset,
        },
        operation: 'biometric.records',
      );

  /// Dispositivos conocidos, para elegir el origen de una importación.
  Future<Map<String, dynamic>> devices() => _api.get(
        Endpoints.biometricDevices,
        operation: 'biometric.devices',
      );
}
