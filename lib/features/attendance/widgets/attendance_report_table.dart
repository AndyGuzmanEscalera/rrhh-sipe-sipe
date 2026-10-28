import 'package:flutter/material.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import '../models/attendance_presentation.dart';
import 'attendance_common.dart';

class AttendanceReportTable extends StatelessWidget {
  const AttendanceReportTable(
      {required this.days, required this.onSelected, super.key});
  final List<ServerAttendanceDay> days;
  final ValueChanged<DateTime> onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 530,
      child: AppDataGrid<ServerAttendanceDay>(
        items: days,
        allowSorting: false,
        onRowTap: (day) => onSelected(day.date),
        emptyMessage: 'No hay días recibidos para el período.',
        mobileItemBuilder: (context, day) => ListTile(
            dense: true,
            onTap: () => onSelected(day.date),
            title: Text(attendanceDate(day.date)),
            subtitle: Text(
                'Entradas: ${attendanceTime(day.morningEntry)} / ${attendanceTime(day.afternoonEntry)}\nSalidas: ${attendanceTime(day.morningExit)} / ${attendanceTime(day.finalExit)}'),
            trailing: AttendanceStatusBadge(day.status)),
        columns: [
          AppDataGridColumn(
              key: 'date',
              label: 'Fecha',
              width: 110,
              value: (d) => attendanceDate(d.date)),
          AppDataGridColumn(
              key: 'shift',
              label: 'Turno',
              minWidth: 120,
              value: (d) => d.shift),
          AppDataGridColumn(
              key: 'entry',
              label: 'Entrada / Retorno',
              width: 150,
              value: (d) =>
                  '${attendanceTime(d.morningEntry)} / ${attendanceTime(d.afternoonEntry)}'),
          AppDataGridColumn(
              key: 'exit',
              label: 'Salida / Final',
              width: 140,
              value: (d) =>
                  '${attendanceTime(d.morningExit)} / ${attendanceTime(d.finalExit)}'),
          AppDataGridColumn(
              key: 'late',
              label: 'Atraso (min)',
              width: 115,
              value: (d) => attendanceMinutes(d.lateMinutes)),
          AppDataGridColumn(
              key: 'early',
              label: 'S. anticipada',
              width: 125,
              value: (d) => attendanceMinutes(d.earlyMinutes)),
          AppDataGridColumn(
              key: 'absence',
              label: 'Ausencia',
              width: 95,
              value: (d) => attendanceMinutes(d.absenceMinutes)),
          AppDataGridColumn(
              key: 'overtime',
              label: 'H. extra (min)',
              width: 120,
              value: (d) => attendanceMinutes(d.overtimeMinutes)),
          AppDataGridColumn(
              key: 'status',
              label: 'Estado',
              width: 135,
              value: (d) => d.status,
              cellBuilder: (_, d, __) => AttendanceStatusBadge(d.status)),
        ],
      ));
}
