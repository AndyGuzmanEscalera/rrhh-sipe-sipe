import 'package:flutter/material.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import '../models/attendance_presentation.dart';
import 'attendance_common.dart';

class AttendanceResultsTable extends StatelessWidget {
  const AttendanceResultsTable(
      {required this.rows,
      required this.page,
      required this.onPage,
      required this.onSelected,
      super.key});
  final List<AttendanceEmployeeResult> rows;
  final int page;
  final ValueChanged<int> onPage;
  final ValueChanged<AttendanceEmployeeResult> onSelected;
  @override
  Widget build(BuildContext context) {
    const size = 20;
    final pages = (rows.length / size).ceil();
    final current = pages == 0 ? 1 : page.clamp(1, pages);
    final items = rows.skip((current - 1) * size).take(size).toList();
    return SizedBox(
        height: rows.isEmpty ? 160 : 470,
        child: AppDataGrid<AttendanceEmployeeResult>(
          items: items,
          onRowTap: onSelected,
          currentPage: current,
          pageSize: size,
          totalItems: rows.length,
          totalPages: pages,
          onPageChanged: onPage,
          allowSorting: false,
          emptyMessage: 'No hay funcionarios que coincidan con la búsqueda.',
          emptyWidget: const Center(
              child: Text('No hay funcionarios que coincidan con la búsqueda.',
                  style: TextStyle(fontSize: 12))),
          mobileItemBuilder: (context, row) => ListTile(
              dense: true,
              onTap: () => onSelected(row),
              title: Text(row.employee.name),
              subtitle: Text(
                  '${row.employee.document ?? '—'} · ${row.employee.unit ?? '—'}'),
              trailing: AttendanceStatusBadge(row.status)),
          columns: [
            AppDataGridColumn(
                key: 'status',
                label: 'Estado',
                width: 130,
                value: (r) => r.status,
                cellBuilder: (_, r, __) => AttendanceStatusBadge(r.status)),
            AppDataGridColumn(
                key: 'employee',
                label: 'Funcionario',
                minWidth: 200,
                value: (r) => r.employee.name),
            AppDataGridColumn(
                key: 'document',
                label: 'Documento',
                width: 125,
                value: (r) => r.employee.document),
            AppDataGridColumn(
                key: 'unit',
                label: 'Área / Unidad',
                minWidth: 150,
                value: (r) => r.employee.unit),
            AppDataGridColumn(
                key: 'position',
                label: 'Cargo',
                minWidth: 140,
                value: (r) => r.employee.position),
            AppDataGridColumn(
                key: 'shift',
                label: 'Turno',
                minWidth: 120,
                value: (r) => r.shifts.isEmpty ? null : r.shifts.join(', ')),
            AppDataGridColumn(
                key: 'normal',
                label: 'Normales',
                width: 95,
                value: (r) => r.summary?.normal),
            AppDataGridColumn(
                key: 'observations',
                label: 'Observaciones',
                width: 120,
                value: (r) => r.summary?.observations),
            AppDataGridColumn(
                key: 'anomalies',
                label: 'Anomalías',
                width: 95,
                value: (r) => r.summary?.anomalies),
            AppDataGridColumn(
                key: 'late',
                label: 'Atraso (min)',
                width: 115,
                value: (r) => r.summary?.lateMinutes,
                formatter: (value) => attendanceMinutes(value as double?)),
          ],
        ));
  }
}
