import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';

const attendanceTestFilter =
    AttendanceFilter(contractId: 'contract-real', year: 2026, month: 10);
Map<String, dynamic> parameterJson({int entry = 300}) => {
      'morning_entry_tolerance': entry,
      'morning_exit_tolerance': 0,
      'afternoon_entry_tolerance': 300,
      'afternoon_exit_tolerance': 0,
      'minimum_return_interval': 1800,
      'duplicate_window': 300,
      'configured': true,
      'valid_from': '2026-10-01',
      'valid_to': '2026-10-31',
      'updated_at': '2026-10-27T10:00:00Z',
    };
Map<String, dynamic> employeeJson(
        {String id = 'employee-1',
        String name = 'Ana Pérez',
        String unit = 'Finanzas'}) =>
    {
      'id': id,
      'full_name': name,
      'document_number': id == 'employee-1' ? '123456' : '987654',
      'unit_name': unit,
      'position_name': 'Analista',
      'contract_type_name': 'Contrato configurado de prueba',
      'item_code': null,
    };
Map<String, dynamic> summaryJson() => {
      'days_evaluated': 1,
      'normal_days': 0,
      'observation_days': 1,
      'anomaly_days': 0,
      'no_data_days': 1,
      'total_records': 6,
      'total_incidents': 2,
      'total_late_minutes': 5.0,
      'total_early_exit_minutes': null,
      'total_gross_early_exit_minutes': 10.0,
      'totals_complete': false
    };
Map<String, dynamic> generationJson({bool ready = true, bool empty = false}) =>
    {
      'ready': ready,
      'period_confirmed': ready,
      'contract_type_id': 'contract-real',
      'year': 2026,
      'month': 10,
      'period': {'start_date': '2026-10-01', 'end_exclusive': '2026-10-03'},
      'pending_configuration': ready
          ? []
          : ['confirmed_contract_period_policy', 'employee_shift_source'],
      'biometric_coverage': 'unknown',
      'message': 'Resultado del backend',
      'employees': !ready || empty
          ? []
          : [
              {
                'employee': employeeJson(),
                'ready': true,
                'summary': summaryJson(),
                'status': 'OBSERVATION',
                'shifts': [
                  {'id': 'shift-a', 'name': 'Turno de prueba'}
                ]
              },
              {
                'employee': employeeJson(
                    id: 'employee-2', name: 'Luis Rojas', unit: 'Obras'),
                'ready': true,
                'summary': summaryJson(),
                'status': 'ANOMALY',
                'shifts': []
              },
            ]
    };
Map<String, dynamic> dayJson(
        {String date = '2026-10-01',
        String status = 'OBSERVATION',
        bool empty = false}) =>
    {
      'date': date,
      'status': status,
      'schedule': {
        'name': 'Turno de prueba',
        'events': [
          {'kind': 'morning_entry', 'expected_at': '${date}T08:00:00'},
          {'kind': 'final_exit', 'expected_at': '${date}T18:00:00'}
        ]
      },
      'morning_entry': empty ? null : '${date}T08:10:00',
      'morning_exit': empty ? null : '${date}T12:05:00',
      'afternoon_entry': empty ? null : '${date}T13:55:00',
      'final_exit': null,
      'late_minutes': empty ? null : 5.0,
      'early_exit_minutes': null,
      'gross_early_exit_minutes': empty ? null : 10.0,
      'absence_minutes': null,
      'non_evaluable_minutes': null,
      'overtime_minutes': null,
      'pending_configuration': [],
      'original_records': empty
          ? []
          : [
              for (final (i, time) in [
                '08:10:00',
                '12:05:00',
                '13:55:00',
                '18:10:00',
                '18:12:00',
                '18:15:00'
              ].indexed)
                {
                  'record_id': 'record-$i',
                  'timestamp': '${date}T$time',
                  'status': 89,
                  'punch': 42,
                  'source': 'SOURCE_API'
                }
            ],
      'incidents': empty
          ? []
          : [
              {
                'type': 'LATE',
                'severity': 'OBSERVATION',
                'description': 'Entrada posterior al límite de tolerancia.',
                'minutes': 5.0,
                'record_ids': ['record-0']
              },
              {
                'type': 'POSSIBLE_DUPLICATE',
                'severity': 'OBSERVATION',
                'description': 'Se detectaron tres marcaciones cercanas.',
                'record_ids': ['record-3', 'record-4', 'record-5']
              },
            ],
      'suggestions': empty
          ? []
          : [
              {
                'description':
                    'Revisar las marcas cercanas; solo una sugerencia.',
                'record_ids': ['record-3', 'record-4', 'record-5'],
                'suggested_record_id': 'record-3'
              }
            ],
    };
Map<String, dynamic> reportJson({bool ready = true, bool empty = false}) => {
      'ready': ready,
      'period_confirmed': ready,
      'employee': employeeJson(),
      'period': {'start_date': '2026-10-01', 'end_exclusive': '2026-10-03'},
      'summary': empty ? null : summaryJson(),
      'shifts': [
        {'id': 'shift-a', 'name': 'Turno de prueba'}
      ],
      'current_shift': null,
      'pending_configuration': ready ? [] : ['employee_shift_source'],
      'pending_policies': ['exit_tolerance_semantics'],
      'days': empty
          ? []
          : [
              dayJson(),
              dayJson(date: '2026-10-02', status: 'NO_DATA', empty: true)
            ],
      'calendar': empty
          ? []
          : [
              {
                'date': '2026-10-01',
                'status': 'OBSERVATION',
                'total_records': 6,
                'first_mark': '2026-10-01T08:10:00',
                'last_mark': '2026-10-01T18:15:00',
                'incident_count': 2
              },
              {
                'date': '2026-10-02',
                'status': 'NO_DATA',
                'total_records': 0,
                'first_mark': null,
                'last_mark': null,
                'incident_count': 0
              },
            ],
    };
Map<String, dynamic> syncJson({String status = 'queued'}) => {
      'id': 'job-1',
      'device_id': 'device-1',
      'status': status,
      'created_at': '2026-10-27T10:00:00Z',
      'started_at': null,
      'finished_at': status == 'completed' ? '2026-10-27T10:05:00Z' : null,
      'downloaded_records': status == 'completed' ? 100000 : 0,
      'new_records': status == 'completed' ? 1 : 0,
      'error_message': null
    };

class FakeAttendanceRepository extends Fake implements AttendanceRepository {
  Result<AttendanceGeneration, Failure> generationResult =
      ok(AttendanceGeneration.fromJson(generationJson()));
  Result<AttendanceReport, Failure> reportResult =
      ok(AttendanceReport.fromJson(reportJson()));
  Result<AttendanceParameters, Failure> parametersResult =
      ok(AttendanceParameters.fromJson(parameterJson()));
  AttendanceContracts catalog = AttendanceContracts.fromJson({
    'items': [
      {'id': 'contract-real', 'name': 'Contrato configurado de prueba'}
    ],
    'pending_configuration': []
  });
  BiometricSync? latest;
  int generateCalls = 0, syncCalls = 0, statusCalls = 0, parameterCalls = 0;
  final List<Map<String, Object?>> saves = [];
  final List<(String, AttendanceFilter)> reports = [];
  Future<Result<AttendanceGeneration, Failure>> Function()? generateOverride;
  @override
  Future<Result<AttendanceParameters, Failure>> parameters() async {
    parameterCalls++;
    return parametersResult;
  }

  @override
  Future<Result<AttendanceParameters, Failure>> saveParameters(
      Map<String, Object?> seconds) async {
    saves.add(seconds);
    return ok(AttendanceParameters.fromJson({...seconds, 'configured': true}));
  }

  @override
  Future<Result<AttendanceContracts, Failure>> contracts() async => ok(catalog);
  @override
  Future<Result<BiometricDeviceStatus, Failure>> deviceStatus() async =>
      ok(BiometricDeviceStatus.fromJson({
        'device_id': 'device-1',
        'connected': true,
        'model': 'Reloj de prueba',
        'transport': 'TCP'
      }));
  @override
  Future<Result<BiometricSync?, Failure>> latestSync() async => ok(latest);
  @override
  Future<Result<BiometricSync, Failure>> syncStatus(String id) async {
    statusCalls++;
    return ok(BiometricSync.fromJson(syncJson(status: 'completed')));
  }

  @override
  Future<Result<BiometricSync, Failure>> synchronize(
      {required String start, required String end}) async {
    syncCalls++;
    latest = BiometricSync.fromJson(syncJson());
    return ok(latest!);
  }

  @override
  Future<Result<AttendanceGeneration, Failure>> generate(
      AttendanceFilter filter) async {
    generateCalls++;
    return generateOverride?.call() ?? generationResult;
  }

  @override
  Future<Result<AttendanceReport, Failure>> report(
      String id, AttendanceFilter filter) async {
    reports.add((id, filter));
    return reportResult;
  }
}
