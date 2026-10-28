import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/app_surface.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/form/app_form_field_style.dart';
import '../cubit/attendance_cubit.dart';
import '../models/attendance_presentation.dart';
import '../views/attendance_report_page.dart';
import 'attendance_common.dart';
import 'attendance_results_table.dart';

/// Independent subscription: polling the device does not rebuild employee rows.
class AttendanceResultsSection extends StatelessWidget {
  const AttendanceResultsSection({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AttendanceCubit, AttendanceState>(
          buildWhen: (a, b) =>
              a.generation != b.generation ||
              a.generating != b.generating ||
              a.resultError != b.resultError ||
              a.query != b.query ||
              a.page != b.page ||
              a.needsRefresh != b.needsRefresh ||
              a.contractId != b.contractId ||
              a.year != b.year ||
              a.month != b.month,
          builder: (context, state) {
            final cubit = context.read<AttendanceCubit>();
            final generation = state.generation;
            return AppSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Resultados',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      if (state.resultError.isNotEmpty)
                        AttendanceNotice(state.resultError,
                            error: true,
                            onRetry:
                                state.filter == null ? null : cubit.generate),
                      if (state.generating)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: LinearProgressIndicator()),
                      if (state.needsRefresh)
                        const AttendanceNotice(
                            'Los datos o parámetros cambiaron. Genere el reporte nuevamente para actualizarlos.'),
                      if (generation == null &&
                          !state.generating &&
                          state.resultError.isEmpty)
                        const AttendanceNotice(
                            'Seleccione contrato, mes y año y genere el reporte con las marcaciones almacenadas.'),
                      if (generation != null && !generation.ready)
                        AttendancePending(generation.pending),
                      if (generation != null && generation.ready) ...[
                        const SizedBox(height: 8),
                        Text(
                            attendancePeriod(
                                generation.period, generation.periodConfirmed),
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 12),
                        TextField(
                            key: const ValueKey('attendance-search'),
                            decoration: AppFormFieldStyle.decoration(
                                    label:
                                        'Buscar funcionario, documento o área',
                                    prefixIcon: Icons.search)
                                .copyWith(isDense: true),
                            onChanged: cubit.search),
                        const SizedBox(height: 12),
                        AttendanceResultsTable(
                            rows: state.filtered,
                            page: state.page,
                            onPage: cubit.changePage,
                            onSelected: (row) => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    settings: RouteSettings(
                                        name:
                                            '/rrhh/attendance/employees/${row.employee.id}/report'),
                                    builder: (_) => AttendanceReportPage(
                                        employeeId: row.employee.id,
                                        filter: state.filter!)))),
                      ],
                    ]));
          });
}
