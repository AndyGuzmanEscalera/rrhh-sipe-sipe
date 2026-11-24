import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/features/attendance/views/attendance_page.dart';
import 'package:rrhh_sipe_sipe/injection/get_it.dart';

class _EmployeesRepository extends Fake implements EmployeesAdminRepository {
  final calls = <(int, int)>[];
  final employees = [
    EmployeeAdmin(
      id: 'employee-1',
      firstName: 'Marta',
      lastName: 'Quiroga',
      documentNumber: '123456',
      positionName: 'Contadora',
      unitName: 'Finanzas',
      isActive: true,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    ),
    EmployeeAdmin(
      id: 'employee-2',
      firstName: 'Óscar',
      lastName: 'Rojas',
      documentNumber: '987654',
      isActive: true,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    ),
  ];

  @override
  Future<Result<AdminPage<EmployeeAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
    String? unitId,
    String? positionId,
    bool availableForUser = false,
    String? exceptUserId,
  }) async {
    calls.add((page, pageSize));
    return ok(AdminPage(
      items: employees,
      page: 1,
      pageSize: pageSize,
      total: employees.length,
      totalPages: 1,
    ));
  }
}

void main() {
  late _EmployeesRepository repository;
  setUp(() {
    repository = _EmployeesRepository();
    sl.registerSingleton<EmployeesAdminRepository>(repository);
  });
  tearDown(() => sl.reset());

  testWidgets('El listado conserva nombre, CI, cargo y unidad en móvil',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AttendanceEmployeeList())));
    await tester.pumpAndSettle();

    expect(find.text('Marta Quiroga'), findsOneWidget);
    expect(find.text('CI: 123456'), findsOneWidget);
    expect(find.text('Contadora'), findsOneWidget);
    expect(find.text('Finanzas'), findsOneWidget);
    expect(find.text('Sin cargo asignado'), findsOneWidget);
    expect(find.text('Sin unidad asignada'), findsOneWidget);
    expect(repository.calls, [(1, 100)]);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('El buscador filtra nombre, apellido, CI, cargo y unidad sin pedir cada empleado',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AttendanceEmployeeList())));
    await tester.pumpAndSettle();
    final search = find.byType(TextField);

    for (final query in ['marta', 'quiroga', '123456', 'contadora', 'finanzas']) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(find.text('Marta Quiroga'), findsOneWidget, reason: query);
      expect(find.text('Óscar Rojas'), findsNothing, reason: query);
    }
    expect(repository.calls, [(1, 100)]);

    await tester.enterText(search, 'sin coincidencia');
    await tester.pumpAndSettle();
    expect(find.text('No hay funcionarios que coincidan con la búsqueda.'),
        findsOneWidget);
  });
}
