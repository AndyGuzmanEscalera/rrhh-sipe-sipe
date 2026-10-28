import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import '../models/attendance_calendar_month.dart';
import '../widgets/attendance_month_calendar.dart';
import '../widgets/attendance_day_dialog.dart';

class EmployeeAttendancePage extends StatefulWidget {
  const EmployeeAttendancePage(
      {required this.employee, required this.analysis, super.key});
  final EmployeeAttendanceAnalysis employee;
  final ImportAttendanceAnalysis analysis;
  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  late DateTime _month;
  @override
  void initState() {
    super.initState();
    final start = widget.analysis.start ??
        (widget.employee.days.isEmpty
            ? DateTime(2000)
            : widget.employee.days.first.date);
    _month = DateTime(start.year, start.month);
  }

  void _navigate(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));
  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy');
    final employee = widget.employee;
    final analysis = widget.analysis;
    final month = AttendanceCalendarMonth(
        month: _month, employee: employee, importAnalysis: analysis);
    return Scaffold(
      appBar: AppBar(title: const Text('Marcaciones del funcionario')),
      body: SafeArea(
          child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                      MediaQuery.sizeOf(context).width < 600 ? 12 : 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(employee.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Wrap(spacing: 16, runSpacing: 4, children: [
                          Text('CI ${employee.identifier}',
                              style: const TextStyle(
                                  fontSize: 12, color: UiColors.textSecondary)),
                          if (analysis.start != null && analysis.end != null)
                            Text(
                                '${date.format(analysis.start!)} — ${date.format(analysis.end!)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: UiColors.textSecondary)),
                          Text('${employee.totalMarks} marcaciones',
                              style: const TextStyle(
                                  fontSize: 12, color: UiColors.textSecondary)),
                        ]),
                        if (employee.identityMessage != null)
                          Text(employee.identityMessage!,
                              style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: Text(
                                  '${const [
                                    'Enero',
                                    'Febrero',
                                    'Marzo',
                                    'Abril',
                                    'Mayo',
                                    'Junio',
                                    'Julio',
                                    'Agosto',
                                    'Septiembre',
                                    'Octubre',
                                    'Noviembre',
                                    'Diciembre'
                                  ][_month.month - 1]} ${_month.year}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700))),
                          IconButton(
                              tooltip: 'Mes anterior',
                              onPressed: () => _navigate(-1),
                              icon: const Icon(Icons.chevron_left),
                              constraints: const BoxConstraints.tightFor(
                                  width: 36, height: 36),
                              padding: const EdgeInsets.all(6)),
                          IconButton(
                              tooltip: 'Mes siguiente',
                              onPressed: () => _navigate(1),
                              icon: const Icon(Icons.chevron_right),
                              constraints: const BoxConstraints.tightFor(
                                  width: 36, height: 36),
                              padding: const EdgeInsets.all(6)),
                        ]),
                        const SizedBox(height: 6),
                        Wrap(spacing: 18, runSpacing: 6, children: [
                          for (final (status, label) in const [
                            (CalendarDayStatus.normal, 'Normales'),
                            (CalendarDayStatus.observation, 'Observaciones'),
                            (CalendarDayStatus.anomaly, 'Anomalías'),
                            (CalendarDayStatus.noData, 'Sin datos'),
                          ])
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                      color:
                                          AttendanceMonthCalendar.style(status)
                                              .$2,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(
                                  status == CalendarDayStatus.noData
                                      ? label
                                      : '$label: ${month.count(status)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: UiColors.textSecondary)),
                            ]),
                        ]),
                        const SizedBox(height: 8),
                        AttendanceMonthCalendar(
                            month: month,
                            onDaySelected: (day) => showDialog<void>(
                                context: context,
                                builder: (_) => AttendanceDayDialog(
                                    employee: employee,
                                    day: day,
                                    configuration: analysis.configuration))),
                        const SizedBox(height: 8),
                        const Text(
                            'Seleccione un día para ver el detalle. Solo se analiza el rango importado.',
                            style: TextStyle(
                                fontSize: 11, color: UiColors.textMuted)),
                      ]),
                ),
              ))),
    );
  }
}
