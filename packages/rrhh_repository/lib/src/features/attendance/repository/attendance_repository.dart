import 'package:failures/failures.dart';
import 'package:rrhh_api/rrhh_api.dart';
import '../entities/attendance_models.dart';

class AttendanceRepository {
  AttendanceRepository({required AttendanceApi api}) : _api = api;
  final AttendanceApi _api;
  Future<Result<T, Failure>> _read<T>(
          String operation, Future<T> Function() action) =>
      handleExceptions(action, feature: 'attendance', operation: operation);
  Future<Result<AttendanceParameters, Failure>> parameters() => _read(
      'parameters',
      () async => AttendanceParameters.fromJson(await _api.parameters()));
  Future<Result<AttendanceParameters, Failure>> saveParameters(
          Map<String, int> seconds) =>
      _read(
          'saveParameters',
          () async => AttendanceParameters.fromJson(
              await _api.saveParameters(seconds)));
  Future<Result<AttendanceContracts, Failure>> contracts() => _read('contracts',
      () async => AttendanceContracts.fromJson(await _api.contracts()));
  Future<Result<BiometricDeviceStatus, Failure>> deviceStatus() => _read(
      'deviceStatus',
      () async => BiometricDeviceStatus.fromJson(await _api.deviceStatus()));
  Future<Result<BiometricSync?, Failure>> latestSync() =>
      _read('latestSync', () async {
        final json = await _api.latestSync();
        return json['sync'] == null
            ? null
            : BiometricSync.fromJson(
                Map<String, dynamic>.from(json['sync'] as Map));
      });
  Future<Result<BiometricSync, Failure>> syncStatus(String id) => _read(
      'syncStatus',
      () async => BiometricSync.fromJson(await _api.syncStatus(id)));
  Future<Result<BiometricSync, Failure>> synchronize(
          {required String start, required String end}) =>
      _read(
          'synchronize',
          () async => BiometricSync.fromJson(
              await _api.synchronize(start: start, end: end)));
  Future<Result<AttendanceGeneration, Failure>> generate(
          AttendanceFilter filter) =>
      _read(
          'generate',
          () async => AttendanceGeneration.fromJson(await _api.generate(
              contractId: filter.contractId,
              year: filter.year,
              month: filter.month)));
  Future<Result<AttendanceReport, Failure>> report(
          String id, AttendanceFilter filter) =>
      _read(
          'report',
          () async => AttendanceReport.fromJson(await _api.report(
              employeeId: id,
              contractId: filter.contractId,
              year: filter.year,
              month: filter.month)));
}
