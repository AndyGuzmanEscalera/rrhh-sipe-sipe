import 'package:rrhh_sipe_sipe/core/routes.dart';
import 'package:rrhh_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_sipe_sipe/core/router.dart';

/// Escucha fin de sesión y redirige con GoRouter (como Inventario +
/// [SessionCubit] en `DataConfigPage`).
class AppNavigationListener extends StatelessWidget {
  const AppNavigationListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppSessionCubit, AppSessionState>(
      listenWhen: (previous, current) =>
          previous.isAuthenticated && !current.isAuthenticated,
      listener: (context, state) {
        final path = router.routeInformationProvider.value.uri.path;
        if (path == Routes.home) {
          router.go(Routes.signIn);
        }
      },
      child: child,
    );
  }
}
