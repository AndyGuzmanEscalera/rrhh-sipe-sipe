import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:failures/failures.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/theme/app_theme.dart';
import 'package:rrhh_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:rrhh_sipe_sipe/features/employees/views/employees_page.dart';
import 'package:rrhh_sipe_sipe/features/administration/basic_data/employee_detail/employee_detail_page.dart';
import 'package:rrhh_sipe_sipe/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import 'package:rrhh_sipe_sipe/injection/get_it.dart';

final _employee = EmployeeAdmin(
    id: 'e1',
    firstName: 'Ana',
    lastName: 'Pérez',
    documentNumber: '123',
    unitName: 'Administración',
    positionName: 'Técnico',
    isActive: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026));

class _Repository extends Fake implements EmployeesAdminRepository {
  String? query;
  @override
  Future<Result<AdminPage<EmployeeAdmin>, Failure>> list(
      {int page = 1,
      int pageSize = 50,
      String? search,
      bool? isActive,
      String? unitId,
      String? positionId,
      bool availableForUser = false,
      String? exceptUserId}) async {
    query = search;
    return Ok(AdminPage(
        items: [_employee], page: 1, pageSize: 20, total: 1, totalPages: 1));
  }

  @override
  Future<Result<EmployeeAdmin, Failure>> get(String id) async => Ok(_employee);
}

class _Auth extends Fake implements AuthenticationRepository {}

void main() {
  for (final width in [375.0, 1440.0]) {
    testWidgets('Listado compartido, búsqueda y detalle a $width px',
        (tester) async {
      await sl.reset();
      final repository = _Repository();
      final session = AppSessionCubit(authRepository: _Auth());
      session.onSignedIn(const UserSession(
          id: 'u1',
          username: 'tester',
          isActive: true,
          permissions: [
            'master_data.employees.read',
            'master_data.employees.manage'
          ]));
      sl.registerSingleton<EmployeesAdminRepository>(repository);
      sl.registerFactory<EmployeesCubit>(() => EmployeesCubit(repository));
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        await session.close();
        await sl.reset();
      });
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider.value(
              value: session,
              child: const Scaffold(
                  body: SingleChildScrollView(
                      padding: EdgeInsets.all(16), child: EmployeesPage())))));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo funcionario'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(repository.query, 'Ana');
      final listElement = tester.element(find.byType(EmployeesPage));
      await tester.ensureVisible(find.text('Ana Pérez'));
      await tester.tap(find.text('Ana Pérez'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle del funcionario'), findsOneWidget);
      expect(find.byType(EmployeeDetailPage), findsOneWidget);
      expect(find.byType(EmployeesPage), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('CI: 123'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.element(find.byType(EmployeesPage)), same(listElement));
      expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          'Ana');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
