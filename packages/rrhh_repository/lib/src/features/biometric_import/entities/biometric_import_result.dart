/// Resultado de un lote de importación.
///
/// Todos los duplicados no es un error: el módulo omite duplicados técnicos
/// exactos y contabiliza el resto.
class BiometricImportResult {
  BiometricImportResult.fromJson(Map<String, dynamic> json)
      : batchId = json['batch_id'] as String? ?? '',
        deviceId = json['device_id'] as String? ?? '',
        origin = json['origin'] as String? ?? 'SOURCE_FILE',
        sourceFileName = json['source_file_name'] as String?,
        status = json['status'] as String? ?? '',
        errorMessage = json['error_message'] as String?,
        receivedRecords = (json['received_records'] as num?)?.toInt() ?? 0,
        newRecords = (json['new_records'] as num?)?.toInt() ?? 0,
        duplicateRecords = (json['duplicate_records'] as num?)?.toInt() ?? 0,
        errorRecords = (json['error_records'] as num?)?.toInt() ?? 0;

  final String batchId;
  final String deviceId;
  final String origin;
  final String? sourceFileName;
  final String status;
  final String? errorMessage;
  final int receivedRecords;
  final int newRecords;
  final int duplicateRecords;
  final int errorRecords;

  bool get onlyDuplicates =>
      errorRecords == 0 && newRecords == 0 && duplicateRecords > 0;
}
