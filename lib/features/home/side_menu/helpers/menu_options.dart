import 'package:flutter/material.dart';
import 'package:rrhh_sipe_sipe/core/routes.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';

class MenuOption {
  const MenuOption(this.label, this.menu, this.icon);
  final String label;
  final MenuEnum menu;
  final IconData icon;

  String get path => switch (menu) {
        MenuEnum.dashboard => Routes.home,
        MenuEnum.biometricImport => Routes.biometricImport,
        MenuEnum.attendance => Routes.attendance,
        MenuEnum.employees => Routes.employees,
        MenuEnum.reports => Routes.reports,
        MenuEnum.settings => Routes.settings,
      };
}

const dashboardMenu =
    MenuOption('Dashboard', MenuEnum.dashboard, Icons.space_dashboard_outlined);

const menuOptions = [
  dashboardMenu,
  MenuOption('Importar Biométrico', MenuEnum.biometricImport,
      Icons.upload_file_outlined),
  MenuOption('Asistencia', MenuEnum.attendance, Icons.fact_check_outlined),
  MenuOption('Funcionarios', MenuEnum.employees, Icons.people_outline_rounded),
  MenuOption('Reportes', MenuEnum.reports, Icons.bar_chart_rounded),
  MenuOption('Configuración', MenuEnum.settings, Icons.settings_outlined),
];
