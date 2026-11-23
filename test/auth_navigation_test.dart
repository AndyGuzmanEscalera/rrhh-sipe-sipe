import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/cubit/biometric_import_cubit.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/data/biometric_file_picker.dart';
import 'package:failures/failures.dart';
import 'package:rrhh_sipe_sipe/features/home/side_menu/helpers/menu_options.dart';
import 'package:rrhh_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:rrhh_sipe_sipe/features/home/screens/main_screen_page.dart';
import 'package:rrhh_sipe_sipe/features/home/widgets/home_components.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/feature_placeholder.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/app/app.dart';
import 'package:rrhh_sipe_sipe/core/router.dart';
import 'package:rrhh_sipe_sipe/core/routes.dart';
import 'package:rrhh_sipe_sipe/features/authentication/sign_in/cubit/sign_in_cubit.dart';
import 'package:rrhh_sipe_sipe/injection/get_it.dart';
import 'features/attendance/attendance_fixtures.dart';

class _FakeAuthRepository extends Fake implements AuthenticationRepository {
  @override
  Future<Result<UserSession?, Failure>> restoreSession() async =>
      ok<UserSession?, Failure>(null);
}

class _AttendanceEmployees extends Fake implements EmployeesAdminRepository {
  final queries = <String?>[];

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
    queries.add(search);
    return ok(AdminPage(
      items: [
        EmployeeAdmin(
            id: 'fixture-employee',
            firstName: 'Persona',
            lastName: 'Sintética',
            positionName: 'Cargo de prueba',
            unitName: 'Unidad de prueba',
            isActive: true,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026))
      ],
      page: page,
      pageSize: pageSize,
      total: 1,
      totalPages: 1,
    ));
  }
}

class _AttendanceRange extends Fake implements AttendanceRepository {
  final requests = <(String, String, String)>[];
  bool empty = false;
  bool fail = false;

  @override
  Future<Result<AttendanceReport, Failure>> reportRange(
      String id, String from, String to) async {
    requests.add((id, from, to));
    if (fail) return err(const GenericFailure('Error de consulta de prueba'));
    return ok(AttendanceReport.fromJson({
      'employee': employeeJson(id: id, name: 'Persona Sintética'),
      'period': {'start_date': from, 'end_exclusive': to},
      'days': [dayJson(date: from, empty: empty)],
    }));
  }
}

void main() {
  testWidgets('Consulta por funcionario, rango y evidencia en móvil',
      (tester) async {
    await sl.reset();
    final auth = _FakeAuthRepository();
    final session = AppSessionCubit(authRepository: auth);
    final employees = _AttendanceEmployees();
    final reports = _AttendanceRange();
    sl.registerSingleton<AppSessionCubit>(session);
    sl.registerFactory<SideMenuCubit>(SideMenuCubit.new);
    sl.registerSingleton<EmployeesAdminRepository>(employees);
    sl.registerSingleton<AttendanceRepository>(reports);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await session.close();
      await sl.reset();
      await tester.binding.setSurfaceSize(null);
    });
    session.onSignedIn(const UserSession(
        id: 'fixture',
        username: 'fixture',
        isActive: true,
        permissions: ['rrhh.read']));
    await tester.binding.setSurfaceSize(const Size(390, 900));
    router.go('/asistencia');
    await tester.pumpWidget(const AppView());
    await tester.pumpAndSettle();
    expect(find.textContaining('Cargo de prueba'), findsOneWidget);
    expect(find.textContaining('Unidad de prueba'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '007');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(employees.queries, [null, '007']);
    await tester.tap(find.text('Persona Sintética'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path,
        '/asistencia/fixture-employee');
    final now = DateTime.now();
    final iso = DateFormat('yyyy-MM-dd');
    expect(reports.requests.single, (
      'fixture-employee',
      iso.format(DateTime(now.year, now.month)),
      iso.format(DateTime(now.year, now.month + 1, 0))
    ));
    expect(find.text('REPORTE DE ASISTENCIA'), findsOneWidget);
    final marks = find.text('Ver marcaciones (6)');
    await tester.ensureVisible(marks);
    await tester.pumpAndSettle();
    await tester.tap(marks);
    await tester.pumpAndSettle();
    expect(find.textContaining('status_raw: 89', findRichText: true),
        findsWidgets);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    final startDate = find.textContaining('Desde:');
    await tester.ensureVisible(startDate);
    await tester.tap(startDate);
    await tester.pumpAndSettle();
    final picker = find.byType(DatePickerDialog);
    await tester
        .tap(find.descendant(of: picker, matching: find.text('2')).last);
    await tester.tap(find
        .text(MaterialLocalizations.of(tester.element(picker)).okButtonLabel));
    await tester.pumpAndSettle();
    reports.empty = true;
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();
    expect(
        reports.requests.last.$2, iso.format(DateTime(now.year, now.month, 2)));
    expect(find.textContaining('No existen marcaciones'), findsOneWidget);
    reports.fail = true;
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();
    expect(find.text('Error de consulta de prueba'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inicio autenticado y salida al login al terminar la sesión',
      (tester) async {
    await sl.reset();
    final repository = _FakeAuthRepository();
    final session = AppSessionCubit(authRepository: repository);
    sl.registerSingleton<AppSessionCubit>(session);
    sl.registerFactory<SideMenuCubit>(() => SideMenuCubit());
    sl.registerFactory<BiometricImportCubit>(() => BiometricImportCubit(
        repository: const BiometricImportRepository(),
        picker: BiometricFilePicker()));
    sl.registerFactory<SignInCubit>(
        () => SignInCubit(authRepository: repository));
    session.onSignedIn(
        const UserSession(id: 'u1', username: 'tester', isActive: true));
    router.go('/rrhh/home');
    await tester.pumpWidget(const AppView());
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(find.text('Bienvenido, tester'), findsOneWidget);
    for (final width in [375.0, 800.0, 1440.0, 1912.0]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenido, tester'), findsOneWidget);
      if (width >= 1100) {
        final sidebar = tester.getRect(find.byType(HomeSidebar));
        expect(sidebar.top, 0);
        expect(sidebar.height, 900);
      }
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byTooltip('Mi cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Sin roles asignados'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    final homeElement = tester.element(find.byType(MainScreenPage));
    final importCubit = homeElement.read<BiometricImportCubit>();
    for (final option in menuOptions) {
      await tester.tap(find.widgetWithText(ListTile, option.label));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, option.path);
      expect(tester.element(find.byType(MainScreenPage)), same(homeElement));
      expect(homeElement.read<BiometricImportCubit>(), same(importCubit));
      expect(
          tester
              .widget<ListTile>(find.widgetWithText(ListTile, option.label))
              .selected,
          isTrue);
      if (option.menu == MenuEnum.biometricImport ||
          option.menu == MenuEnum.employees ||
          option.menu == MenuEnum.attendance) {
        expect(find.text('Acceso restringido'), findsOneWidget);
      } else if (option.menu != MenuEnum.dashboard) {
        expect(find.text('Próximamente'), findsOneWidget);
        final content = tester.getRect(find.byType(FeaturePlaceholder));
        expect(content.left, 244 + 36);
        expect(content.width, 1912 - 244 - 72);
      }
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(const Size(375, 900));
    await tester.pumpAndSettle();
    for (final option in menuOptions) {
      await tester.tap(find.byTooltip('Abrir menú'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(ListTile, option.label));
      await tester.tap(find.widgetWithText(ListTile, option.label));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, option.path);
      expect(find.byType(Drawer), findsNothing);
      expect(
          homeElement.read<SideMenuCubit>().state.selected.menu, option.menu);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
    Navigator.of(homeElement).push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Detalle de registro'))));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de registro'), findsOneWidget);
    session.onAuthCleared();
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Detalle de registro'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, Routes.signIn);
    session.onSignedIn(
        const UserSession(id: 'u2', username: 'otro', isActive: true));
    router.go(Routes.home);
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido, otro'), findsOneWidget);
    expect(
        tester
            .element(find.byType(MainScreenPage))
            .read<SideMenuCubit>()
            .state
            .selected
            .menu,
        MenuEnum.dashboard);
    await tester.pumpWidget(const SizedBox());
    await session.close();
    await sl.reset();
  });
  testWidgets('La pantalla principal de RRHH requiere sesión', (tester) async {
    await sl.reset();
    final repository = _FakeAuthRepository();
    final session = AppSessionCubit(authRepository: repository);
    sl.registerSingleton<AppSessionCubit>(session);
    sl.registerFactory<SignInCubit>(
        () => SignInCubit(authRepository: repository));
    router.go('/rrhh/login?origen=favorito');
    await tester.pumpWidget(const AppView());
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.toString(),
        '/login?origen=favorito');
    router.go(Routes.home);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, Routes.signIn);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    router.go('/importacion');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(router.routeInformationProvider.value.uri.queryParameters['next'],
        '/importacion');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await session.close();
    await sl.reset();
  });
}
