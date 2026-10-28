import 'package:flutter/material.dart';

import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';

import '../views/employee_attendance_page.dart';

class AttendanceAnalysisView extends StatefulWidget {
  const AttendanceAnalysisView({required this.analysis, super.key});
  final ImportAttendanceAnalysis analysis;
  @override
  State<AttendanceAnalysisView> createState() => _AttendanceAnalysisViewState();
}

class _AttendanceAnalysisViewState extends State<AttendanceAnalysisView> {
  String _query = '';
  int _page = 1;
  @override
  void didUpdateWidget(covariant AttendanceAnalysisView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysis != widget.analysis) {
      _page = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Funcionarios del archivo',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (widget.analysis.lookupWarning != null)
        Text(widget.analysis.lookupWarning!),
      const Text(
          'Análisis para revisión. Los días corresponden al período del archivo completo; '
          'no se determinan causas ni se aplican cambios.'),
      const SizedBox(height: 12),
      TextField(
          decoration: const InputDecoration(
              labelText: 'Buscar por nombre o CI',
              prefixIcon: Icon(Icons.search)),
          onChanged: (text) => setState(() {
                _query = text;
                _page = 1;
              })),
      const SizedBox(height: 12),
      _list(),
    ]);
  }

  Widget _list() {
    final query = _query.trim().toLowerCase();
    final filtered = widget.analysis.employees
        .where((employee) =>
            employee.name.toLowerCase().contains(query) ||
            employee.identifier.contains(query))
        .toList();
    final pages = (filtered.length / 20).ceil().clamp(1, 1 << 30);
    final page = _page.clamp(1, pages);
    final items = filtered.skip((page - 1) * 20).take(20).toList();
    return SizedBox(
        height: 480,
        child: AppDataGrid<EmployeeAttendanceAnalysis>(
          items: items,
          onRowTap: (employee) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => EmployeeAttendancePage(
                      employee: employee, analysis: widget.analysis))),
          currentPage: page, pageSize: 20, totalItems: filtered.length,
          totalPages: pages,
          onPageChanged: (value) => setState(() => _page = value),
          // Ordenación global se mantiene en el servicio; no ordenar solo una página.
          allowSorting: false,
          columns: [
            AppDataGridColumn(
                key: 'name',
                label: 'Funcionario',
                value: (e) => e.name,
                mobilePrimary: true),
            AppDataGridColumn(
                key: 'ci',
                label: 'CI/identificador',
                value: (e) => e.identifier),
            AppDataGridColumn(
                key: 'days',
                label: 'Días analizados',
                value: (e) => e.days.length),
            AppDataGridColumn(
                key: 'normal',
                label: 'Sin novedad',
                value: (e) => e.count(AttendanceStatus.normal)),
            AppDataGridColumn(
                key: 'observation',
                label: 'Observaciones',
                value: (e) => e.count(AttendanceStatus.observation)),
            AppDataGridColumn(
                key: 'anomaly',
                label: 'Anomalías',
                value: (e) => e.count(AttendanceStatus.anomaly)),
          ],
        ));
  }
}
