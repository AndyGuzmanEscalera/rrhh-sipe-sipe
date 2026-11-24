import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import 'package:rrhh_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:rrhh_sipe_sipe/features/home/widgets/home_components.dart';
import 'package:go_router/go_router.dart';
import 'package:rrhh_sipe_sipe/core/routes.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final username =
        context.watch<AppSessionCubit>().state.userSession?.username ?? '';
    return LayoutBuilder(builder: (context, size) {
      final columns = size.maxWidth >= 1000
          ? 3
          : size.maxWidth >= 550
              ? 2
              : 1;
      final width = (size.maxWidth - (columns - 1) * 16) / columns;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HomeWelcome(username: username, compact: size.maxWidth < 600),
        const SizedBox(height: 28),
        Text('Accesos del sistema',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 16, children: [
          for (final item in [
            ('Funcionarios', Icons.people_outline_rounded, Routes.employees),
            ('Asistencia', Icons.fact_check_outlined, Routes.attendance),
            ('Importar biométrico', Icons.upload_file_outlined, Routes.biometricImport),
          ]) SizedBox(width: width, child: Card(child: ListTile(leading: Icon(item.$2, color: UiColors.primary), title: Text(item.$1), trailing: const Icon(Icons.arrow_forward), onTap: () => context.go(item.$3))))
        ]),
      ]);
    });
  }
}
