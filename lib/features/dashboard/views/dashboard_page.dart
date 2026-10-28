import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import 'package:rrhh_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:rrhh_sipe_sipe/features/home/widgets/home_components.dart';

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
      const metrics = [
        ('Total de funcionarios', '0', Icons.people_outline_rounded),
        ('Marcaciones importadas', '0', Icons.fact_check_outlined),
        ('Atrasos', '0', Icons.schedule_outlined),
        ('Inconsistencias', '0', Icons.rule_outlined),
        ('Última importación', 'Sin importaciones', Icons.upload_file_outlined),
      ];
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HomeWelcome(username: username, compact: size.maxWidth < 600),
        const SizedBox(height: 28),
        Text('Resumen de Recursos Humanos',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: UiColors.warningSoft,
                borderRadius: BorderRadius.circular(12)),
            child: const Text(
                'Datos temporales de demostración. Los indicadores aún no están conectados a información real.',
                style: TextStyle(color: UiColors.warning))),
        const SizedBox(height: 20),
        Wrap(
            spacing: 16,
            runSpacing: 16,
            children: metrics
                .map((metric) => SizedBox(
                    width: width,
                    child: HomeInfoCard(
                        icon: metric.$3,
                        label: 'TEMPORAL',
                        value: metric.$2,
                        detail: metric.$1,
                        color: UiColors.primary,
                        background: UiColors.primarySoft)))
                .toList()),
      ]);
    });
  }
}
