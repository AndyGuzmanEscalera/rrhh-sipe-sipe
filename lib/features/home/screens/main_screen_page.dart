import 'package:rrhh_sipe_sipe/core/app/app_identity.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';
import 'package:rrhh_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:rrhh_sipe_sipe/features/attendance/views/attendance_page.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/views/biometric_import_page.dart';
import 'package:rrhh_sipe_sipe/features/employees/views/employees_page.dart';
import 'package:rrhh_sipe_sipe/features/reports/views/reports_page.dart';
import 'package:rrhh_sipe_sipe/features/settings/views/settings_page.dart';
import 'package:rrhh_sipe_sipe/features/dashboard/views/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import 'package:rrhh_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import '../widgets/home_components.dart';

class MainScreenPage extends StatelessWidget {
  const MainScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<SideMenuCubit>().state.selected;
    final session = context.watch<AppSessionCubit>().state.userSession;
    final username = session?.username ?? '';
    final identity = session?.institutionalContext;
    final initials =
        username.isEmpty ? 'RH' : username.substring(0, 1).toUpperCase();

    void showAccount() {
      showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Mi cuenta'),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(identity?.employeeName ?? username,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Usuario: $username'),
                      if (session?.email != null) Text(session!.email!),
                      if (identity?.desktopSubtitle != null)
                        Text(identity!.desktopSubtitle!),
                      const SizedBox(height: 16),
                      const Text('Roles asignados'),
                      const SizedBox(height: 8),
                      if (session?.roles.isNotEmpty ?? false)
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: session!.roles
                                .map((role) => Chip(label: Text(role)))
                                .toList())
                      else
                        const Text('Sin roles asignados'),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'))
                ],
              ));
    }

    return Scaffold(
        drawer: Drawer(
            width: 280,
            child: HomeSidebar(onAccount: showAccount, inDrawer: true)),
        body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1100;
          final compact = constraints.maxWidth < 600;
          return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (desktop) HomeSidebar(onAccount: showAccount),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: compact ? 20 : 36, vertical: 20),
                    decoration: const BoxDecoration(
                        color: UiColors.surface,
                        border: Border(
                            bottom: BorderSide(color: UiColors.borderLight))),
                    child: Row(children: [
                      if (!desktop) ...[
                        IconButton(
                            tooltip: 'Abrir menú',
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: const Icon(Icons.menu_rounded)),
                        const SizedBox(width: 12)
                      ],
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(selected.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 20)),
                            if (!compact) const Text(AppIdentity.name),
                          ])),
                      IconButton(
                          tooltip: 'Mi cuenta',
                          onPressed: showAccount,
                          icon: CircleAvatar(
                              radius: 17,
                              backgroundColor: UiColors.primarySoft,
                              child: Text(initials,
                                  style: const TextStyle(
                                      color: UiColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)))),
                      const SizedBox(width: 8),
                      if (compact)
                        IconButton(
                            tooltip: 'Cerrar sesión',
                            onPressed: () =>
                                context.read<AppSessionCubit>().logout(),
                            icon: const Icon(Icons.logout_rounded, size: 20))
                      else
                        TextButton.icon(
                            onPressed: () =>
                                context.read<AppSessionCubit>().logout(),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Cerrar sesión')),
                    ]),
                  ),
                  Expanded(
                      child: SingleChildScrollView(
                          padding: EdgeInsets.all(compact ? 20 : 36),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ContentArea(menu: selected.menu),
                                const SizedBox(height: 32),
                                const Text(AppIdentity.institution,
                                    style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.4,
                                        fontWeight: FontWeight.w600,
                                        color: UiColors.textMuted)),
                              ]))),
                ])),
          ]);
        })));
  }
}

class _ContentArea extends StatelessWidget {
  const _ContentArea({required this.menu});

  final MenuEnum menu;

  @override
  Widget build(BuildContext context) => switch (menu) {
        MenuEnum.dashboard => const DashboardPage(),
        MenuEnum.biometricImport => const BiometricImportPage(),
        MenuEnum.attendance => const AttendancePage(),
        MenuEnum.employees => const EmployeesPage(),
        MenuEnum.reports => const ReportsPage(),
        MenuEnum.settings => const SettingsPage(),
      };
}
