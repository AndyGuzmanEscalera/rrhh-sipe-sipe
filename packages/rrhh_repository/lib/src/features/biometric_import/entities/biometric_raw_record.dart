/// Marcación biométrica en bruto.
///
/// Conserva los valores observados tal como llegan. `status` y `punch` no se
/// interpretan: son códigos crudos del dispositivo o del archivo.
class BiometricRawRecord {
  BiometricRawRecord.fromJson(Map<String, dynamic> json)
      : recordId = json['record_id'] as String? ?? '',
        deviceId = json['device_id'] as String? ?? '',
        userId = json['user_id'] as String? ?? '',
        // Use UTC as a container for the clock's timezone-free fields.
        timestamp = DateTime.parse("${json['timestamp']}Z"),
        status = (json['status'] as num?)?.toInt(),
        punch = (json['punch'] as num?)?.toInt(),
        uid = (json['uid'] as num?)?.toInt(),
        source = json['source'] as String? ?? '',
        sourceFileName = json['source_file_name'] as String?,
        importBatchId = json['import_batch_id'] as String?;

  final String recordId;
  final String deviceId;
  final String userId;
  final DateTime timestamp;
  final int? status;
  final int? punch;
  final int? uid;
  final String source;
  final String? sourceFileName;
  final String? importBatchId;

  String get originLabel => source == 'SOURCE_FILE' ? 'TXT' : 'Biometric API';
}
