import 'package:flutter/material.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';

class MenuOption {
  const MenuOption(this.label, this.menu, this.icon);
  final String label;
  final MenuEnum menu;
  final IconData icon;
}

const dashboardMenu =
    MenuOption('Dashboard', MenuEnum.dashboard, Icons.space_dashboard_outlined);

const menuOptions = [
  dashboardMenu,
  MenuOption('Importar Biométrico', MenuEnum.biometricImport,
      Icons.upload_file_outlined),
  MenuOption('Asistencia Biométrica', MenuEnum.attendance, Icons.fact_check_outlined),
  MenuOption('Funcionarios', MenuEnum.employees, Icons.people_outline_rounded),
  MenuOption('Reportes', MenuEnum.reports, Icons.bar_chart_rounded),
  MenuOption('Configuración', MenuEnum.settings, Icons.settings_outlined),
];
