import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/auth/permission_guard.dart';
import 'package:rrhh_sipe_sipe/core/auth/permissions.dart';
import 'package:rrhh_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:rrhh_sipe_sipe/core/theme/app_theme.dart';
import 'package:rrhh_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_api/rrhh_api.dart';

class _FakeAuthRepository extends Fake implements AuthenticationRepository {}

UserSession _session(List<String> permissions) {
  return UserSession(
    id: 'u1',
    username: 'tester',
    isActive: true,
    permissions: permissions,
  );
}

void main() {
  group('PermissionGuard', () {
    late AppSessionCubit sessionCubit;

    setUp(() {
      sessionCubit = AppSessionCubit(authRepository: _FakeAuthRepository());
    });

    tearDown(() async {
      await sessionCubit.close();
    });

    testWidgets(
        'Gestor usa capacidades de la fachada sin obtener administración',
        (tester) async {
      // The API derives these reads from its institutional access policy.
      // Flutter consumes the response; it does not grant permissions by role.
      sessionCubit.onSignedIn(UserResponse.fromJson({
        'id': 'gestor-fixture',
        'username': 'gestor',
        'is_active': true,
        'roles': ['MANAGER'],
        'permissions': [Permissions.attendanceRead, Permissions.employeesRead],
      }).toEntity());
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
        body: BlocProvider.value(
            value: sessionCubit,
            child: const Column(children: [
              PermissionGuard(
                  permission: Permissions.attendanceRead,
                  child: Text('Lectura asistencia')),
              PermissionGuard(
                  permission: Permissions.employeesRead,
                  child: Text('Lectura funcionarios')),
              PermissionGuard(
                  permission: Permissions.attendanceManage,
                  child: Text('Administración RRHH')),
            ])),
      )));
      expect(find.text('Lectura asistencia'), findsOneWidget);
      expect(find.text('Lectura funcionarios'), findsOneWidget);
      expect(find.text('Administración RRHH'), findsNothing);
    });

    test('Flutter no deduce permisos por el nombre del rol', () {
      const session = UserSession(
          id: 'fixture',
          username: 'gestor',
          isActive: true,
          roles: ['MANAGER']);
      expect(hasPermission(session, Permissions.attendanceRead), isFalse);
      expect(hasPermission(session, Permissions.attendanceManage), isFalse);
    });

    Future<void> pumpGuard(
      WidgetTester tester, {
      required List<String> permissions,
      required String requiredPermission,
    }) async {
      sessionCubit.onSignedIn(_session(permissions));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: ResponsiveBreakpointsConfig.builder,
          home: Scaffold(
            body: Column(
              children: [
                BlocProvider<AppSessionCubit>.value(
                  value: sessionCubit,
                  child: PermissionGuard(
                    permission: requiredPermission,
                    child: const Text('Contenido protegido'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('con read entra al módulo', (tester) async {
      await pumpGuard(
        tester,
        permissions: [Permissions.usersRead],
        requiredPermission: Permissions.usersRead,
      );
      expect(find.text('Contenido protegido'), findsOneWidget);
    });

    testWidgets('sin read muestra acceso restringido', (tester) async {
      await pumpGuard(
        tester,
        permissions: [Permissions.employeesRead],
        requiredPermission: Permissions.usersRead,
      );
      expect(find.text('Contenido protegido'), findsNothing);
      expect(find.text('Acceso restringido'), findsOneWidget);
      expect(
        find.text('No tienes permisos para acceder a esta sección.'),
        findsOneWidget,
      );
    });

    testWidgets('permiso de otro módulo no habilita acceso', (tester) async {
      await pumpGuard(
        tester,
        permissions: [Permissions.usersManage],
        requiredPermission: Permissions.organizationalUnitsRead,
      );
      expect(find.text('Contenido protegido'), findsNothing);
    });
  });
}
