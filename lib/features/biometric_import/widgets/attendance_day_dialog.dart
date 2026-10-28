import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import '../models/attendance_calendar_month.dart';
import 'attendance_day_card.dart';

class AttendanceDayDialog extends StatelessWidget {
  const AttendanceDayDialog(
      {required this.employee,
      required this.day,
      required this.configuration,
      super.key});
  final EmployeeAttendanceAnalysis employee;
  final AttendanceCalendarDay day;
  final AttendanceConfiguration configuration;
  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 760,
                maxHeight: MediaQuery.sizeOf(context).height * .85),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                  child: Row(children: [
                    Expanded(
                        child: Text(DateFormat('dd/MM/yyyy').format(day.date),
                            style: Theme.of(context).textTheme.titleLarge)),
                    IconButton(
                        tooltip: 'Cerrar detalle',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))
                  ])),
              Flexible(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(employee.name,
                                style: Theme.of(context).textTheme.titleLarge),
                            Text('CI/identificador: ${employee.identifier}'),
                            const SizedBox(height: 16),
                            if (day.analysis == null)
                              const Text(
                                  'SIN DATOS: no hay análisis para esta fecha. Solo se evalúa el período importado.')
                            else
                              AttendanceDayCard(
                                  day: day.analysis!,
                                  configuration: configuration,
                                  noData:
                                      day.status == CalendarDayStatus.noData),
                          ]))),
            ])),
      );
}
