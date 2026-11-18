import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _FakeAuthRepository extends Fake implements AuthenticationRepository {
  @override
  Future<Result<UserSession?, Failure>> restoreSession() async =>
      ok<UserSession?, Failure>(null);
}

void main() {
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
    router.go(Routes.home);
    await tester.pumpWidget(const AppView());
    await tester.pumpAndSettle();
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
      expect(router.routeInformationProvider.value.uri.path, Routes.home);
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
      expect(router.routeInformationProvider.value.uri.path, Routes.home);
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
    router.go(Routes.signIn);
    await tester.pumpWidget(const AppView());
    await tester.pumpAndSettle();
    router.go(Routes.home);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, Routes.signIn);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await session.close();
    await sl.reset();
  });
}
