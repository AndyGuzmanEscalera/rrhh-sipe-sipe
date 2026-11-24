/// Immutable presentation data mapped from the actual RRHH API contracts.
/// No attendance classification, matching, time penalties or raw-code inference.
typedef AttendanceJson = Map<String, dynamic>;
List<AttendanceJson> _rows(dynamic value) => (value as List? ?? const [])
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList(growable: false);
List<String> _strings(dynamic value) =>
    (value as List? ?? const []).cast<String>();
DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);
double? _number(dynamic value) => (value as num?)?.toDouble();
int _count(AttendanceJson json, String key) =>
    (json[key] as num?)?.toInt() ?? 0;

class AttendanceFilter {
  const AttendanceFilter(
      {required this.contractId, required this.year, required this.month});
  final String contractId;
  final int year, month;
}

class AttendanceContract {
  const AttendanceContract({required this.id, required this.name});
  final String id, name;
  factory AttendanceContract.fromJson(AttendanceJson j) =>
      AttendanceContract(id: j['id'] as String, name: j['name'] as String);
}

class AttendanceContracts {
  AttendanceContracts.fromJson(AttendanceJson j)
      : items = List.unmodifiable(
            _rows(j['items']).map(AttendanceContract.fromJson)),
        pending = List.unmodifiable(_strings(j['pending_configuration']));
  final List<AttendanceContract> items;
  final List<String> pending;
}

class AttendanceParameters {
  AttendanceParameters.fromJson(AttendanceJson j)
      : seconds = Map.unmodifiable(
            {for (final key in keys) key: (j[key] as num?)?.toInt()}),
        configured = j['configured'] == true,
        updatedAt = _date(j['updated_at']),
        validFrom = _date(j['valid_from']),
        validTo = _date(j['valid_to']);
  static const keys = [
    'morning_entry_tolerance',
    'morning_exit_tolerance',
    'afternoon_entry_tolerance',
    'afternoon_exit_tolerance',
    'minimum_return_interval',
    'duplicate_window'
  ];
  final Map<String, int?> seconds;
  final bool configured;
  final DateTime? updatedAt;
  final DateTime? validFrom, validTo;
}

class BiometricDeviceStatus {
  BiometricDeviceStatus.fromJson(AttendanceJson j)
      : connected = j['connected'] == true,
        apiAvailable = j['api_available'] as bool?,
        deviceConnected = j['device_connected'] as bool?,
        deviceId = j['device_id'] as String,
        model = j['model'] as String?,
        transport = j['transport'] as String?;
  final bool connected;
  final bool? apiAvailable, deviceConnected;
  final String deviceId;
  final String? model, transport;
}

class BiometricSync {
  BiometricSync.fromJson(AttendanceJson j)
      : id = j['id'] as String,
        deviceId = j['device_id'] as String,
        status = j['status'] as String,
        createdAt = _date(j['created_at']),
        startedAt = _date(j['started_at']),
        finishedAt = _date(j['finished_at']),
        downloaded = _count(j, 'downloaded_records'),
        newRecords = _count(j, 'new_records'),
        errorMessage = j['error_message'] as String?;
  final String id, deviceId, status;
  final DateTime? createdAt, startedAt, finishedAt;
  final int downloaded, newRecords;
  final String? errorMessage;
  bool get isActive => status == 'queued' || status == 'running';
}

class AttendancePeriod {
  AttendancePeriod.fromJson(AttendanceJson j)
      : start = DateTime.parse(j['start_date'] as String),
        endExclusive = DateTime.parse(j['end_exclusive'] as String);
  final DateTime start, endExclusive;
}

class AttendanceEmployee {
  AttendanceEmployee.fromJson(AttendanceJson j)
      : id = j['id'] as String,
        name = j['full_name'] as String,
        document = j['document_number'] as String?,
        itemCode = j['item_code'] as String?,
        unit = j['unit_name'] as String?,
        position = j['position_name'] as String?,
        contract = j['contract_type_name'] as String?;
  final String id, name;
  final String? document, itemCode, unit, position, contract;
}

class AttendanceSummary {
  AttendanceSummary.fromJson(AttendanceJson j)
      : evaluated = _count(j, 'days_evaluated'),
        normal = _count(j, 'normal_days'),
        observations = _count(j, 'observation_days'),
        anomalies = _count(j, 'anomaly_days'),
        noData = _count(j, 'no_data_days'),
        records = _count(j, 'total_records'),
        incidents = _count(j, 'total_incidents'),
        lateMinutes = _number(j['total_late_minutes']),
        earlyMinutes = _number(j['total_early_exit_minutes']),
        grossEarlyMinutes = _number(j['total_gross_early_exit_minutes']),
        absenceMinutes = _number(j['total_absence_minutes']),
        overtimeMinutes = _number(j['total_overtime_minutes']),
        totalsComplete = j['totals_complete'] == true;
  final int evaluated,
      normal,
      observations,
      anomalies,
      noData,
      records,
      incidents;
  final double? lateMinutes, earlyMinutes, grossEarlyMinutes, absenceMinutes, overtimeMinutes;
  final bool totalsComplete;
}

class AttendanceEmployeeResult {
  AttendanceEmployeeResult.fromJson(AttendanceJson j)
      : employee = AttendanceEmployee.fromJson(
            Map<String, dynamic>.from(j['employee'] as Map)),
        summary = j['summary'] == null
            ? null
            : AttendanceSummary.fromJson(
                Map<String, dynamic>.from(j['summary'] as Map)),
        status = j['status'] as String? ?? 'UNKNOWN',
        ready = j['ready'] == true,
        shifts = List.unmodifiable(
            _rows(j['shifts']).map((e) => e['name'] as String));
  final AttendanceEmployee employee;
  final AttendanceSummary? summary;
  final String status;
  final bool ready;
  final List<String> shifts;
}

class AttendanceGeneration {
  AttendanceGeneration.fromJson(AttendanceJson j)
      : ready = j['ready'] == true,
        periodConfirmed = j['period_confirmed'] == true,
        period = j['period'] == null
            ? null
            : AttendancePeriod.fromJson(
                Map<String, dynamic>.from(j['period'] as Map)),
        pending = List.unmodifiable(_strings(j['pending_configuration'])),
        employees = List.unmodifiable(
            _rows(j['employees']).map(AttendanceEmployeeResult.fromJson)),
        message = j['message'] as String? ?? '',
        coverage = j['biometric_coverage'] as String? ?? 'unknown';
  final bool ready, periodConfirmed;
  final AttendancePeriod? period;
  final List<String> pending;
  final List<AttendanceEmployeeResult> employees;
  final String message, coverage;
}

class AttendanceMark {
  AttendanceMark.fromJson(AttendanceJson j)
      : timestamp = DateTime.parse(j['timestamp'] as String),
        recordId = j['record_id'] as String,
        status = j['status'] as int?,
        punch = j['punch'] as int?,
        uid = j['uid'] as int?,
        sourceFileName = j['source_file_name'] as String?,
        importBatchId = j['import_batch_id'] as String?,
        source = j['source'] as String;
  final DateTime timestamp;
  final String recordId, source;
  final int? status, punch, uid;
  final String? sourceFileName, importBatchId;
}

class ServerAttendanceSuggestion {
  ServerAttendanceSuggestion.fromJson(AttendanceJson j)
      : description = j['description'] as String,
        recordIds = List.unmodifiable(_strings(j['record_ids'])),
        suggestedRecordId = j['suggested_record_id'] as String?;
  final String description;
  final List<String> recordIds;
  final String? suggestedRecordId;
}

class ServerAttendanceIncident {
  ServerAttendanceIncident.fromJson(AttendanceJson j)
      : type = j['type'] as String,
        severity = j['severity'] as String,
        description = j['description'] as String,
        minutes = _number(j['minutes']),
        recordIds = List.unmodifiable(_strings(j['record_ids'])),
        suggestion = j['suggestion'] == null
            ? null
            : ServerAttendanceSuggestion.fromJson(
                Map<String, dynamic>.from(j['suggestion'] as Map));
  final String type, severity, description;
  final double? minutes;
  final List<String> recordIds;
  final ServerAttendanceSuggestion? suggestion;
}

class ServerAttendanceDay {
  ServerAttendanceDay.fromJson(AttendanceJson j)
      : date = DateTime.parse(j['date'] as String),
        status = j['status'] as String,
        shift = j['schedule'] == null
            ? null
            : (j['schedule'] as Map)['name'] as String?,
        expectedTimes = List.unmodifiable(j['schedule'] == null
            ? <DateTime>[]
            : _rows((j['schedule'] as Map)['events'])
                .map((e) => DateTime.parse(e['expected_at'] as String))),
        morningEntry = _date(j['morning_entry']),
        morningExit = _date(j['morning_exit']),
        afternoonEntry = _date(j['afternoon_entry']),
        finalExit = _date(j['final_exit']),
        lateMinutes = _number(j['late_minutes']),
        earlyMinutes = _number(j['early_exit_minutes']),
        grossEarlyMinutes = _number(j['gross_early_exit_minutes']),
        absenceMinutes = _number(j['absence_minutes']),
        nonEvaluableMinutes = _number(j['non_evaluable_minutes']),
        overtimeMinutes = _number(j['overtime_minutes']),
        records = List.unmodifiable(
            _rows(j['original_records']).map(AttendanceMark.fromJson).toList()
              ..sort((a, b) => a.timestamp.compareTo(b.timestamp))),
        incidents = List.unmodifiable(
            _rows(j['incidents']).map(ServerAttendanceIncident.fromJson)),
        suggestions = List.unmodifiable(
            _rows(j['suggestions']).map(ServerAttendanceSuggestion.fromJson)),
        pending = List.unmodifiable(_strings(j['pending_configuration']));
  final DateTime date;
  final String status;
  final String? shift;
  final List<DateTime> expectedTimes;
  final DateTime? morningEntry, morningExit, afternoonEntry, finalExit;
  final double? lateMinutes,
      earlyMinutes,
      grossEarlyMinutes,
      absenceMinutes,
      nonEvaluableMinutes,
      overtimeMinutes;
  final List<AttendanceMark> records;
  final List<ServerAttendanceIncident> incidents;
  final List<ServerAttendanceSuggestion> suggestions;
  final List<String> pending;
}

class ServerAttendanceCalendarDay {
  ServerAttendanceCalendarDay.fromJson(AttendanceJson j)
      : date = DateTime.parse(j['date'] as String),
        status = j['status'] as String,
        totalRecords = _count(j, 'total_records'),
        firstMark = _date(j['first_mark']),
        lastMark = _date(j['last_mark']),
        incidentCount = _count(j, 'incident_count');
  final DateTime date;
  final String status;
  final int totalRecords, incidentCount;
  final DateTime? firstMark, lastMark;
}

class AttendanceReport {
  AttendanceReport.fromJson(AttendanceJson j)
      : ready = j['ready'] == true,
        periodConfirmed = j['period_confirmed'] == true,
        employee = AttendanceEmployee.fromJson(
            Map<String, dynamic>.from(j['employee'] as Map)),
        period = j['period'] == null
            ? null
            : AttendancePeriod.fromJson(
                Map<String, dynamic>.from(j['period'] as Map)),
        summary = j['summary'] == null
            ? null
            : AttendanceSummary.fromJson(
                Map<String, dynamic>.from(j['summary'] as Map)),
        shifts = List.unmodifiable(
            _rows(j['shifts']).map((e) => e['name'] as String)),
        currentShift = j['current_shift'] == null
            ? null
            : (j['current_shift'] as Map)['name'] as String?,
        configuredShifts =
            List.unmodifiable(_strings(j['configured_shift_names'])),
        pending = List.unmodifiable(_strings(j['pending_configuration'])),
        pendingPolicies = List.unmodifiable(_strings(j['pending_policies'])),
        days = List.unmodifiable(
            _rows(j['days']).map(ServerAttendanceDay.fromJson)),
        calendar = List.unmodifiable(
            _rows(j['calendar']).map(ServerAttendanceCalendarDay.fromJson));
  final bool ready, periodConfirmed;
  final AttendanceEmployee employee;
  final AttendancePeriod? period;
  final AttendanceSummary? summary;
  final List<String> shifts, configuredShifts, pending, pendingPolicies;
  final String? currentShift;
  final List<ServerAttendanceDay> days;
  final List<ServerAttendanceCalendarDay> calendar;
}
