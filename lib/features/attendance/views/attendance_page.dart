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
          ? const AttendanceEmployeeList()
          : EmployeeAttendanceReport(
              key: ValueKey(employeeId), employeeId: employeeId!));
}

/// Listado compacto que usa únicamente el catálogo paginado de Correspondencia.
class AttendanceEmployeeList extends StatefulWidget {
  const AttendanceEmployeeList({super.key});

  @override
  State<AttendanceEmployeeList> createState() => _AttendanceEmployeeListState();
}

class _AttendanceEmployeeListState extends State<AttendanceEmployeeList> {
  static const _pageSize = 20;
  static const _sourcePageSize = 100;
  final List<EmployeeAdmin> _employees = [];
  String _query = '';
  String? _error;
  int _request = 0;
  int _page = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    final loaded = <EmployeeAdmin>[];
    String? error;
    var totalPages = 1;
    final repository = sl<EmployeesAdminRepository>();
    final first = await repository.list(page: 1, pageSize: _sourcePageSize);
    first.when(
      ok: (value) {
        loaded.addAll(value.items);
        totalPages = value.totalPages;
      },
      err: (failure) => error = failure.message,
    );
    for (var page = 2; error == null && page <= totalPages; page++) {
      final response = await repository.list(
          page: page, pageSize: _sourcePageSize);
      response.when(
        ok: (value) => loaded.addAll(value.items),
        err: (failure) => error = failure.message,
      );
    }
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      _error = error;
      if (error == null) {
        _employees
          ..clear()
          ..addAll(loaded);
      }
    });
  }

  void _search(String input) {
    final query = input.trim();
    if (query == _query) return;
    setState(() {
      _query = query;
      _page = 1;
    });
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');

  bool _matches(EmployeeAdmin employee, String query) {
    final fields = [
      employee.firstName,
      employee.lastName,
      employee.fullName,
      employee.documentNumber ?? '',
      employee.positionName ?? '',
      employee.unitName ?? '',
    ];
    return fields.any((value) => _normalize(value).contains(query));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _normalize(_query);
    final filtered = query.isEmpty
        ? _employees
        : _employees.where((item) => _matches(item, query)).toList();
    final pages = (filtered.length / _pageSize).ceil();
    final current = pages == 0 ? 1 : _page.clamp(1, pages);
    final visible = filtered.skip((current - 1) * _pageSize).take(_pageSize);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Asistencia', style: theme.textTheme.headlineSmall),
      const SizedBox(height: 16),
      TextField(
        onChanged: _search,
        decoration: const InputDecoration(
          labelText: 'Buscar funcionario',
          hintText: 'Nombre, apellidos, CI, cargo o unidad',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 10),
      if (_loading)
        const LinearProgressIndicator()
      else if (_error != null)
        AttendanceNotice(_error!, error: true, onRetry: _load)
      else if (filtered.isEmpty)
        AttendanceNotice(_query.isEmpty
            ? 'No se encontraron funcionarios.'
            : 'No hay funcionarios que coincidan con la búsqueda.')
      else ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('${filtered.length} funcionarios',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        for (final employee in visible) ...[
          _AttendanceEmployeeRow(
            employee: employee,
            onTap: () => context.go(Routes.attendanceEmployee(employee.id)),
          ),
          Divider(height: 1, color: theme.dividerColor),
        ],
        if (pages > 1)
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
                tooltip: 'Página anterior',
                onPressed: current > 1
                    ? () => setState(() => _page = current - 1)
                    : null,
                icon: const Icon(Icons.chevron_left)),
            Text('$current / $pages'),
            IconButton(
                tooltip: 'Página siguiente',
                onPressed: current < pages
                    ? () => setState(() => _page = current + 1)
                    : null,
                icon: const Icon(Icons.chevron_right)),
          ]),
      ],
    ]);
  }
}

class _AttendanceEmployeeRow extends StatelessWidget {
  const _AttendanceEmployeeRow({required this.employee, required this.onTap});
  final EmployeeAdmin employee;
  final VoidCallback onTap;

  String get _initials {
    final names = employee.fullName.trim().split(RegExp(r'\s+'));
    if (names.isEmpty || names.first.isEmpty) return '?';
    return names.length == 1
        ? names.first.substring(0, 1).toUpperCase()
        : '${names.first.substring(0, 1)}${names.last.substring(0, 1)}'
            .toUpperCase();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final theme = Theme.of(context);
        final position = employee.positionName?.trim().isNotEmpty == true
            ? employee.positionName!.trim()
            : 'Sin cargo asignado';
        final unit = employee.unitName?.trim().isNotEmpty == true
            ? employee.unitName!.trim()
            : 'Sin unidad asignada';
        final employeeBlock = Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Text(_initials,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Tooltip(
                    message: employee.fullName,
                    child: Text(employee.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700))),
                Text('CI: ${employee.documentNumber?.trim().isNotEmpty == true ? employee.documentNumber : '—'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ])),
        ]);
        final organizationalBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                  message: position,
                  child: Text(position,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600))),
              Tooltip(
                  message: unit,
                  child: Text(unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant))),
              if (!employee.isActive)
                Text('Inactivo',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600)),
            ]);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            hoverColor: theme.colorScheme.primary.withAlpha(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: box.maxWidth >= 700
                  ? Row(children: [
                      Expanded(flex: 5, child: employeeBlock),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: organizationalBlock),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 20),
                    ])
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(child: employeeBlock),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 20),
                        ]),
                        Padding(
                          padding: const EdgeInsets.only(left: 46, top: 6),
                          child: organizationalBlock,
                        ),
                      ],
                    ),
            ),
          ),
        );
      });
}
