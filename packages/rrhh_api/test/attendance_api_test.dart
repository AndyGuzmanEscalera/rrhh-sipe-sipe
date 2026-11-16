import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_api/rrhh_api.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> calls = [];
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options);
    return ResponseBody.fromString(
        jsonEncode({
          'ready': false,
          'pending_configuration': ['employee_shift_source']
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
      'Generación y detalle usan contratos reales de API sin sincronización implícita',
      () async {
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'))
      ..httpClientAdapter = adapter;
    final api = AttendanceApi(mainApi: ApiMethod(dio: dio));
    final result =
        await api.generate(contractId: 'contract-id', year: 2026, month: 10);
    await api.report(
        employeeId: 'employee-id',
        contractId: 'contract-id',
        year: 2026,
        month: 10);
    expect(result['ready'], isFalse);
    expect(adapter.calls.length, 2);
    expect(adapter.calls[0].path, '/rrhh/attendance/generate');
    expect(adapter.calls[0].data,
        {'contract_type_id': 'contract-id', 'year': 2026, 'month': 10});
    expect(
        adapter.calls[1].path, '/rrhh/attendance/employees/employee-id/report');
    expect(adapter.calls[1].queryParameters,
        {'contract_type_id': 'contract-id', 'year': 2026, 'month': 10});
    expect(
        adapter.calls.any((call) => call.path.contains('biometric')), isFalse);
    dio.close();
  });
  test('Guardar usa PUT y segundos; sincronizar usa POST independiente',
      () async {
    final adapter = _Adapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = AttendanceApi(mainApi: ApiMethod(dio: dio));
    final parameters = <String, Object?>{
      'duplicate_window': 300,
      'valid_from': '2026-11-01',
      'valid_to': null
    };
    await api.saveParameters(parameters);
    await api.synchronize(start: '2026-10-01', end: '2026-10-02');
    expect(adapter.calls[0].method, 'PUT');
    expect(adapter.calls[0].data, parameters);
    expect(adapter.calls[1].path, '/rrhh/biometric/sync');
    expect(adapter.calls[1].data,
        {'start_date': '2026-10-01', 'end_date': '2026-10-02'});
    dio.close();
  });
}
