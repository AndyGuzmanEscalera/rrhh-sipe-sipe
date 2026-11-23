import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';

/// Shared authenticated mainApi. Flutter never opens a device connection.
class AttendanceApi {
  AttendanceApi({required ApiMethod mainApi}) : _api = mainApi;
  final ApiMethod _api;
  Future<Map<String, dynamic>> parameters() => _api
      .get(Endpoints.attendanceParameters, operation: 'attendance.parameters');
  Future<Map<String, dynamic>> saveParameters(Map<String, Object?> values) =>
      _api.put(Endpoints.attendanceParameters,
          data: values, operation: 'attendance.parameters.save');
  Future<Map<String, dynamic>> contracts() => _api
      .get(Endpoints.attendanceContracts, operation: 'attendance.contracts');
  Future<Map<String, dynamic>> deviceStatus() =>
      _api.get(Endpoints.biometricStatus, operation: 'biometric.status');
  Future<Map<String, dynamic>> latestSync() => _api
      .get(Endpoints.biometricLatestSync, operation: 'biometric.sync.latest');
  Future<Map<String, dynamic>> syncStatus(String id) =>
      _api.get(Endpoints.biometricSyncStatus(id),
          operation: 'biometric.sync.status');
  Future<Map<String, dynamic>> synchronize(
          {required String start, required String end}) =>
      _api.post(Endpoints.biometricSync,
          data: {'start_date': start, 'end_date': end},
          operation: 'biometric.sync');
  Future<Map<String, dynamic>> generate(
          {required String contractId,
          required int year,
          required int month}) =>
      _api.post(Endpoints.attendanceGenerate,
          data: {'contract_type_id': contractId, 'year': year, 'month': month},
          operation: 'attendance.generate');
  Future<Map<String, dynamic>> report(
          {required String employeeId,
          required String contractId,
          required int year,
          required int month}) =>
      _api.get(Endpoints.attendanceReport(employeeId),
          queryParameters: {
            'contract_type_id': contractId,
            'year': year,
            'month': month
          },
          operation: 'attendance.report');

  Future<Map<String, dynamic>> reportRange({
    required String employeeId,
    required String from,
    required String to,
  }) =>
      _api.requestWithoutBodyLogging(Endpoints.attendanceReport(employeeId),
          method: 'GET',
          queryParameters: {'date_from': from, 'date_to': to},
          operation: 'attendance.reportRange');
}
