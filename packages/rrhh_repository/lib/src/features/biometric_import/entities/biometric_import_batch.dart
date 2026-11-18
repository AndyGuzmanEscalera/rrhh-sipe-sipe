/// Lote de importación biométrica.
///
/// Un lote proviene de un archivo (TXT/DAT) o de un rango descargado del
/// dispositivo. No contiene ninguna evaluación de asistencia.
class BiometricImportBatch {
  BiometricImportBatch.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String? ?? '',
        deviceId = json['device_id'] as String? ?? '',
        origin = json['origin'] as String? ?? 'SOURCE_API',
        sourceFileName = json['source_file_name'] as String?,
        status = json['status'] as String? ?? '',
        receivedRecords = _count(json, 'downloaded_records'),
        newRecords = _count(json, 'new_records'),
        duplicateRecords = _count(
            json,
            json.containsKey('duplicate_records')
                ? 'duplicate_records'
                : 'duplicates_ignored'),
        errorRecords = _count(json, 'error_records'),
        createdAt = _date(json['created_at']),
        requestedStartDate = _date(json['requested_start_date']),
        requestedEndDate = _date(json['requested_end_date']),
        executedBy = json['executed_by'] as String?,
        errorMessage = json['error_message'] as String?;

  final String id;
  final String deviceId;
  final String origin;
  final String? sourceFileName;
  final String status;
  final int receivedRecords;
  final int newRecords;
  final int duplicateRecords;
  final int errorRecords;
  final DateTime? createdAt;
  final DateTime? requestedStartDate;
  final DateTime? requestedEndDate;
  final String? errorMessage;
  final String? executedBy;

  /// Origen legible. La API sólo distingue API y archivo.
  String get originLabel => origin == 'SOURCE_FILE' ? 'TXT' : 'Biometric API';

  bool get isFromFile => origin == 'SOURCE_FILE';

  /// Todo lo recibido ya existía: no es un error.
  bool get onlyDuplicates =>
      errorRecords == 0 && newRecords == 0 && duplicateRecords > 0;

  String get statusLabel => switch (status) {
        'queued' => 'Pendiente',
        'running' => 'En proceso',
        'completed' => 'Completada',
        'failed' => 'Fallida',
        _ => status,
      };

  bool get isActive => status == 'queued' || status == 'running';
}

typedef BiometricBatchPage = ({List<BiometricImportBatch> items, int total});

int _count(Map<String, dynamic> json, String key) =>
    (json[key] as num?)?.toInt() ?? 0;

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);
