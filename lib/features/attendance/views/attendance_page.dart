import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/auth/permission_guard.dart';
import 'package:rrhh_sipe_sipe/core/auth/permissions.dart';
import 'package:rrhh_sipe_sipe/core/routes.dart';
import 'package:rrhh_sipe_sipe/injection/get_it.dart';
import '../widgets/attendance_common.dart';
import 'employee_attendance_report.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({this.employeeId, super.key});
  final String? employeeId;

  @override
  Widget build(BuildContext context) => PermissionGuard(
      permission: Permissions.attendanceRead,
      child: employeeId == null
          ? const _EmployeeList()
          : EmployeeAttendanceReport(
              key: ValueKey(employeeId), employeeId: employeeId!));
}

class _EmployeeList extends StatefulWidget {
  const _EmployeeList();

  @override
  State<_EmployeeList> createState() => _EmployeeListState();
}

class _EmployeeListState extends State<_EmployeeList> {
  AdminPage<EmployeeAdmin>? _employees;
  Timer? _debounce;
  String _query = '';
  String? _error;
  int _request = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([int page = 1]) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await sl<EmployeesAdminRepository>()
        .list(page: page, search: _query.isEmpty ? null : _query);
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      response.when(
          ok: (value) => _employees = value,
          err: (failure) => _error = failure.message);
    });
  }

  void _search(String input) {
    final query = input.trim();
    if (query == _query) return;
    _query = query;
    _request++;
    setState(() => _loading = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _employees;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Asistencia', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      TextField(
        onChanged: _search,
        decoration: const InputDecoration(
          labelText: 'Buscar funcionario',
          hintText: 'Nombre, apellido o documento',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 12),
      if (_loading)
        const LinearProgressIndicator()
      else if (_error != null)
        AttendanceNotice(_error!, error: true, onRetry: () => _load())
      else if (page == null || page.items.isEmpty)
        const AttendanceNotice('No se encontraron funcionarios.')
      else ...[
        for (final employee in page.items)
          ListTile(
            title: Text(employee.fullName),
            subtitle: Text([
              if (employee.positionName case final position?) position,
              if (employee.unitName case final unit?) unit,
              if (!employee.isActive) 'Inactivo',
            ].join('\n')),
            trailing: TextButton(
                onPressed: () =>
                    context.go(Routes.attendanceEmployee(employee.id)),
                child: const Text('Ver asistencia')),
            onTap: () => context.go(Routes.attendanceEmployee(employee.id)),
          ),
        if (page.totalPages > 1)
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
                tooltip: 'Página anterior',
                onPressed: page.page > 1 ? () => _load(page.page - 1) : null,
                icon: const Icon(Icons.chevron_left)),
            Text('${page.page} / ${page.totalPages}'),
            IconButton(
                tooltip: 'Página siguiente',
                onPressed: page.page < page.totalPages
                    ? () => _load(page.page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right)),
          ]),
      ],
    ]);
  }
}
