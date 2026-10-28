import 'package:flutter/material.dart';
import 'package:rrhh_sipe_sipe/core/auth/permission_guard.dart';
import 'package:rrhh_sipe_sipe/core/auth/permissions.dart';
import 'package:rrhh_sipe_sipe/features/administration/basic_data/employees/list_employees/views/employees_page.dart'
    as shared;

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) => const PermissionGuard(
        permission: Permissions.employeesRead,
        child: shared.EmployeesPage(),
      );
}
