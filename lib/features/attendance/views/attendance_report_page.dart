import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/app/app_identity.dart';
import 'package:rrhh_sipe_sipe/core/auth/permission_guard.dart';
import 'package:rrhh_sipe_sipe/core/auth/permissions.dart';
import 'package:rrhh_sipe_sipe/injection/get_it.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/app_surface.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/official_logo.dart';
import '../cubit/attendance_report_cubit.dart';
import '../models/attendance_presentation.dart';
import '../widgets/attendance_calendar.dart';
import '../widgets/attendance_common.dart';
import '../widgets/attendance_day_detail.dart';
import '../widgets/attendance_report_table.dart';

class AttendanceReportPage extends StatelessWidget {
  const AttendanceReportPage(
      {required this.employeeId, required this.filter, super.key});
  final String employeeId;
  final AttendanceFilter filter;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Asistencia del funcionario')),
      body: PermissionGuard(
          permission: Permissions.attendanceRead,
          child: _ReportProvider(employeeId: employeeId, filter: filter)));
}

class _ReportProvider extends StatelessWidget {
  const _ReportProvider({required this.employeeId, required this.filter});
  final String employeeId;
  final AttendanceFilter filter;
  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => sl<AttendanceReportCubit>()..load(employeeId, filter),
      child: AttendanceReportView(
          initialMonth: DateTime(filter.year, filter.month),
          onRetry: (context) =>
              context.read<AttendanceReportCubit>().load(employeeId, filter)));
}

class AttendanceReportView extends StatefulWidget {
  const AttendanceReportView({this.onRetry, this.initialMonth, super.key});
  final void Function(BuildContext)? onRetry;
  final DateTime? initialMonth;
  @override
  State<AttendanceReportView> createState() => _AttendanceReportViewState();
}

class _AttendanceReportViewState extends State<AttendanceReportView> {
  DateTime? _month;
  int _tab = 0;
  void _select(DateTime date, bool desktop) {
    final cubit = context.read<AttendanceReportCubit>();
    cubit.selectDay(date);
    if (!desktop) {
      final day = cubit.state.selectedDay;
      if (day == null) return;
      showDialog<void>(
          context: context,
          builder: (context) => Dialog(
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: 600,
                      maxHeight: MediaQuery.sizeOf(context).height * .85),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                            tooltip: 'Cerrar detalle',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close))),
                    Flexible(
                        child: SingleChildScrollView(
                            child: AttendanceDayDetail(day: day)))
                  ]))));
    }
  }

  Widget _header(AttendanceReport report) => AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          OfficialLogo(compact: true, width: 30),
          SizedBox(width: 10),
          Expanded(
              child: Text(AppIdentity.institution,
                  style: TextStyle(fontSize: 11, letterSpacing: 1))),
        ]),

        const SizedBox(height: 6),
        Text(report.employee.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 20, runSpacing: 6, children: [
          Text('Documento: ${report.employee.document ?? '—'}'),
          if (report.employee.itemCode != null)
            Text('Ítem: ${report.employee.itemCode}'),
          Text('Unidad: ${report.employee.unit ?? '—'}'),
          Text('Cargo: ${report.employee.position ?? '—'}'),
          Text('Contrato: ${report.employee.contract ?? 'Pendiente'}'),
          Text(
              '${report.shifts.isEmpty && report.currentShift != null ? 'Turno actual sin vigencia histórica confirmada' : 'Turno'}: ${report.shifts.isNotEmpty ? report.shifts.join(', ') : report.currentShift ?? 'Pendiente'}'),
        ]),
        const SizedBox(height: 8),
        Text(attendancePeriod(report.period, report.periodConfirmed)),
        if (!report.ready) AttendancePending(report.pending),
      ]));

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AttendanceReportCubit, AttendanceReportState>(
          builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error.isNotEmpty) {
          return Padding(
              padding: const EdgeInsets.all(24),
              child: AttendanceNotice(state.error,
                  error: true,
                  onRetry: widget.onRetry == null
                      ? null
                      : () => widget.onRetry!(context)));
        }
        final report = state.report;
        if (report == null) {
          return const Center(child: Text('No se recibió un reporte.'));
        }
        final start = report.period?.start ??
            (report.days.isNotEmpty ? report.days.first.date : null);
        final preferred = widget.initialMonth;
        final preferredFits = preferred != null &&
            report.period != null &&
            preferred.isBefore(report.period!.endExclusive) &&
            DateTime(preferred.year, preferred.month + 1)
                .isAfter(report.period!.start);
        final month = _month ??
            (preferredFits
                ? preferred
                : (start == null ? null : DateTime(start.year, start.month)));
        return LayoutBuilder(builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1100;
          final selectedDay = state.selectedDay;
          return SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth < 600 ? 12 : 24),
              child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1520),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _header(report),
                            const SizedBox(height: 14),
                            AttendanceSummaryStrip(report.summary),
                            const SizedBox(height: 16),
                            DefaultTabController(
                                length: 2,
                                initialIndex: _tab,
                                child: TabBar(
                                    onTap: (value) =>
                                        setState(() => _tab = value),
                                    tabs: const [
                                      Tab(text: 'Calendario'),
                                      Tab(text: 'Reporte')
                                    ])),
                            const SizedBox(height: 12),
                            if (report.days.isEmpty)
                              const AttendanceNotice(
                                  'No hay días disponibles para el período recibido.')
                            else
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: _tab == 1
                                            ? AppSurface(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      const Padding(
                                                          padding:
                                                              EdgeInsets.all(8),
                                                          child: Text(
                                                              'HOJA INDIVIDUAL DE ASISTENCIA',
                                                              style: TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700))),
                                                      AttendanceReportTable(
                                                          days: report.days,
                                                          onSelected: (date) =>
                                                              _select(date,
                                                                  desktop)),
                                                    ]))
                                            : month == null
                                                ? const AttendanceNotice(
                                                    'No hay calendario disponible.')
                                                : AppSurface(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    child: Column(children: [
                                                      Row(children: [
                                                        Expanded(
                                                            child: Text(
                                                                '${attendanceMonths[month.month - 1]} ${month.year}',
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700))),
                                                        IconButton(
                                                            tooltip:
                                                                'Mes anterior',
                                                            onPressed: report.period ==
                                                                        null ||
                                                                    !DateTime(month.year, month.month).isAfter(DateTime(
                                                                        report
                                                                            .period!
                                                                            .start
                                                                            .year,
                                                                        report
                                                                            .period!
                                                                            .start
                                                                            .month))
                                                                ? null
                                                                : () => setState(() =>
                                                                    _month = DateTime(
                                                                        month
                                                                            .year,
                                                                        month.month -
                                                                            1)),
                                                            icon: const Icon(
                                                                Icons.chevron_left)),
                                                        IconButton(
                                                            tooltip:
                                                                'Mes siguiente',
                                                            onPressed: report.period ==
                                                                        null ||
                                                                    !DateTime(month.year, month.month + 1).isBefore(report
                                                                        .period!
                                                                        .endExclusive)
                                                                ? null
                                                                : () => setState(() =>
                                                                    _month = DateTime(
                                                                        month
                                                                            .year,
                                                                        month.month +
                                                                            1)),
                                                            icon: const Icon(Icons
                                                                .chevron_right)),
                                                      ]),
                                                      AttendanceCalendar(
                                                          month: month,
                                                          days: report.calendar,
                                                          selected: state
                                                              .selectedDate,
                                                          onSelected: (date) =>
                                                              _select(date,
                                                                  desktop)),
                                                      const SizedBox(height: 8),
                                                      const Text(
                                                          'Seleccione un día para ver todas sus marcaciones e incidencias.',
                                                          style: TextStyle(
                                                              fontSize: 11)),
                                                    ]))),
                                    if (desktop) ...[
                                      const SizedBox(width: 16),
                                      SizedBox(
                                          width: 360,
                                          child: AppSurface(
                                              padding: EdgeInsets.zero,
                                              child: selectedDay == null
                                                  ? const Padding(
                                                      padding:
                                                          EdgeInsets.all(20),
                                                      child: Text(
                                                          'Seleccione un día del calendario o del reporte.'))
                                                  : SizedBox(
                                                      height: 610,
                                                      child: SingleChildScrollView(
                                                          child: AttendanceDayDetail(
                                                              day:
                                                                  selectedDay)))))
                                    ],
                                  ]),
                            if (report.pendingPolicies.isNotEmpty)
                              ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: const Text('Políticas pendientes',
                                      style: TextStyle(fontSize: 12)),
                                  children: [
                                    for (final policy in report.pendingPolicies)
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 6),
                                              child: Text(
                                                  attendanceDependency(policy),
                                                  style: const TextStyle(
                                                      fontSize: 12))))
                                  ]),
                          ]))));
        });
      });
}
