import 'package:rrhh_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:rrhh_sipe_sipe/features/home/side_menu/helpers/menu_options.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/cubit/biometric_import_cubit.dart';
import 'package:rrhh_sipe_sipe/features/attendance/cubit/attendance_cubit.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';
import 'package:rrhh_sipe_sipe/injection/get_it.dart';
import 'package:rrhh_sipe_sipe/core/presentation/screens/error_screen.dart';
import 'package:rrhh_sipe_sipe/core/routes.dart';
import 'package:rrhh_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:rrhh_sipe_sipe/features/authentication/sign_in/views/sign_in_page.dart';
import 'package:rrhh_sipe_sipe/features/home/screens/main_screen_page.dart';
import 'package:rrhh_sipe_sipe/features/splash/views/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// GoRouter global — mismo patrón que Inventario (`core/router.dart`).
final GoRouter router = GoRouter(
  initialLocation: Routes.initial,
  routes: [
    GoRoute(
      path: Routes.initial,
      builder: (context, state) => const SplashPage(),
    ),
    for (final entry in const {
      '/rrhh': Routes.initial,
      '/rrhh/login': Routes.signIn,
      '/rrhh/home': Routes.home,
    }.entries)
      GoRoute(
        path: entry.key,
        redirect: (_, state) => state.uri.replace(path: entry.value).toString(),
      ),
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) => const SignInPage(),
    ),
    for (final option in menuOptions)
      GoRoute(
        path: option.path,
        pageBuilder: (_, state) => NoTransitionPage<void>(
          key: const ValueKey('workspace'),
          child: _ProtectedHomePage(option: option),
        ),
      ),
    GoRoute(
      path: '${Routes.attendance}/:employeeId',
      pageBuilder: (_, state) => NoTransitionPage<void>(
        key: const ValueKey('workspace'),
        child: _ProtectedHomePage(
          option: menuOptions
              .firstWhere((item) => item.menu == MenuEnum.attendance),
          employeeId: state.pathParameters['employeeId']!,
        ),
      ),
    ),
  ],
  errorBuilder: (context, state) => const ErrorScreen(),
);

/// Restaura la sesión al abrir directamente una sección del espacio de trabajo.
class _ProtectedHomePage extends StatefulWidget {
  const _ProtectedHomePage({required this.option, this.employeeId});

  final MenuOption option;
  final String? employeeId;

  @override
  State<_ProtectedHomePage> createState() => _ProtectedHomePageState();
}

class _ProtectedHomePageState extends State<_ProtectedHomePage> {
  bool _checking = true;
  late final SideMenuCubit _menu = sl<SideMenuCubit>()..select(widget.option);

  @override
  void didUpdateWidget(covariant _ProtectedHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.option != widget.option && !_checking) {
      _menu.select(widget.option);
    }
  }

  @override
  void dispose() {
    if (!_checking) _menu.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    if (!mounted) return;
    final appSession = context.read<AppSessionCubit>();

    if (appSession.state.isAuthenticated) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    final restored = await appSession.tryRestoreSession();
    if (!mounted) return;

    if (restored) {
      setState(() => _checking = false);
      return;
    }

    final path = widget.employeeId == null
        ? widget.option.path
        : Routes.attendanceEmployee(widget.employeeId!);
    context.go(path == Routes.home
        ? Routes.signIn
        : Uri(path: Routes.signIn, queryParameters: {'next': path}).toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = context.watch<AppSessionCubit>().state;
    if (!session.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _menu),
        BlocProvider(create: (_) => sl<BiometricImportCubit>()),
        BlocProvider(create: (_) => sl<AttendanceCubit>()),
      ],
      child: MainScreenPage(attendanceEmployeeId: widget.employeeId),
    );
  }
}
