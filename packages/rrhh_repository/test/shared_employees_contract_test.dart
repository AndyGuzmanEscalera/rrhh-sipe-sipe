import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_api/rrhh_api.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:failures/failures.dart';

Map<String, dynamic> employeeJson(String id, String ci) => {
      'id': id,
      'first_name': 'Ana',
      'last_name': 'Pérez',
      'document_number': ci,
      'unit_id': 'unit',
      'unit_name': 'Administración',
      'position_id': 'position',
      'position_name': 'Técnico',
      'is_active': true,
      'created_at': '2026-01-01T00:00:00',
      'updated_at': '2026-01-01T00:00:00',
    };

class _Api extends Fake implements ApiMethod {
  final calls = <(String, String, Object?)>[];
  bool fail = false;
  @override
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters, String? operation}) async {
    calls.add(('GET', path, queryParameters));
    if (fail) throw ForbiddenException('Sin permiso');
    if (path == '/admin/employees') {
      final page = queryParameters?['page'] ?? 1;
      return {
        'items': [employeeJson('e$page', page == 1 ? '123' : '456')],
        'page': page,
        'page_size': 100,
        'total': 2,
        'total_pages': 2
      };
    }
    return employeeJson('e1', '123');
  }

  @override
  Future<Map<String, dynamic>> post(String path,
      {Object? data, String? operation, bool allowEmptyBody = false}) async {
    calls.add(('POST', path, data));
    return employeeJson('e1', '123');
  }

  @override
  Future<Map<String, dynamic>> put(String path,
      {Object? data, String? operation}) async {
    calls.add(('PUT', path, data));
    return employeeJson('e1', '123');
  }

  @override
  Future<Map<String, dynamic>> patch(String path,
      {Object? data, String? operation}) async {
    calls.add(('PATCH', path, data));
    return {...employeeJson('e1', '123'), 'is_active': false};
  }
}

void main() {
  test(
      'CRUD y detalle usan exactamente los endpoints compartidos de funcionarios',
      () async {
    final api = _Api();
    final repository =
        EmployeesAdminRepository(api: EmployeesAdminApi(mainApi: api));
    const input = EmployeeInput(
        firstName: 'Ana',
        lastName: 'Pérez',
        documentNumber: '123',
        unitId: 'unit',
        positionId: 'position');
    expect(
        (await repository.list(search: 'Ana', isActive: true))
            .valueOrNull()!
            .items
            .first
            .documentNumber,
        '123');
    expect((await repository.get('e1')).valueOrNull()!.fullName, 'Ana Pérez');
    await repository.create(input);
    await repository.update('e1', input);
    expect(
        (await repository.setActive('e1', isActive: false))
            .valueOrNull()!
            .isActive,
        isFalse);
    expect(api.calls.map((call) => (call.$1, call.$2)), [
      ('GET', '/admin/employees'),
      ('GET', '/admin/employees/e1'),
      ('POST', '/admin/employees'),
      ('PUT', '/admin/employees/e1'),
      ('PATCH', '/admin/employees/e1/active'),
    ]);
    expect((api.calls[2].$3 as Map)['document_number'], '123');
    expect(api.calls.last.$3, {'is_active': false});
  });
  test(
      'La asociación recorre todas las páginas e incluye funcionarios inactivos',
      () async {
    final api = _Api();
    final repository = AttendanceAnalysisRepository(
        employeesRepository:
            EmployeesAdminRepository(api: EmployeesAdminApi(mainApi: api)));
    final record = BiometricRecord(
        employeeIdentifier: '456',
        timestamp: DateTime(2026, 9, 1, 8),
        field3: '1',
        field4: '0',
        field5: 'X',
        field6: '0',
        rawLine: 'original',
        lineNumber: 1);
    final analysis =
        await repository.analyze([record], AttendanceConfiguration());
    expect(analysis.employees.single.employee!.id, 'e2');
    expect(api.calls.length, 2);
    expect((api.calls.first.$3 as Map).containsKey('is_active'), isFalse);
    api.fail = true;
    final unavailable =
        await repository.analyze([record], AttendanceConfiguration());
    expect(unavailable.lookupWarning, isNotNull);
    expect(unavailable.employees.single.employee, isNull);
    expect(
        unavailable.employees.single.days.single.records.single, same(record));
  });
}
