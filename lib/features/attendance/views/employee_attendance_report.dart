import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/app/app_identity.dart';
import 'package:rrhh_sipe_sipe/core/routes.dart';
import 'package:rrhh_sipe_sipe/injection/get_it.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/official_logo.dart';

import '../models/attendance_presentation.dart';
import '../widgets/attendance_common.dart';
import 'journal_control.dart';

class EmployeeAttendanceReport extends StatefulWidget {
  const EmployeeAttendanceReport({required this.employeeId, super.key});
  final String employeeId;

  @override
  State<EmployeeAttendanceReport> createState() =>
      _EmployeeAttendanceReportState();
}

class _EmployeeAttendanceReportState extends State<EmployeeAttendanceReport> {
  late DateTime _from;
  late DateTime _to;
  AttendanceReport? _report;
  String? _error;
  bool _loading = false;
  // Solo visual: los días sin marcación se ocultan, los datos no cambian.
  bool _showEmptyDays = false;
  final _tolerances = List<int>.filled(4, 5);
  final _times = [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 12, minute: 0), const TimeOfDay(hour: 14, minute: 0), const TimeOfDay(hour: 18, minute: 0)];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month);
    _to = DateTime(now.year, now.month + 1, 0);
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _error = null);
    final days = DateTime.utc(_to.year, _to.month, _to.day)
        .difference(DateTime.utc(_from.year, _from.month, _from.day))
        .inDays;
    if (days < 0 || days > 366) {
      setState(() => _error = 'Seleccione un rango válido de hasta 367 días.');
      return;
    }
    if (_tolerances.any((value) => value < 0)) {
      setState(() => _error = 'Las tolerancias deben ser enteros no negativos.'); return;
    }
    setState(() => _loading = true);
    final format = DateFormat('yyyy-MM-dd');
    if (!(_times[0].hour * 60 + _times[0].minute < _times[1].hour * 60 + _times[1].minute &&
        _times[1].hour * 60 + _times[1].minute < _times[2].hour * 60 + _times[2].minute &&
        _times[2].hour * 60 + _times[2].minute < _times[3].hour * 60 + _times[3].minute)) {
      setState(() => _error = 'La jornada debe mantener el orden Inicio 1, Fin 1, Inicio 2 y Fin 2.'); return;
    }
    String clock(TimeOfDay value) => '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    final response = await sl<AttendanceRepository>().reportRange(widget.employeeId, format.format(_from), format.format(_to), evaluation: {
      'morning_start': clock(_times[0]), 'morning_end': clock(_times[1]), 'afternoon_start': clock(_times[2]), 'afternoon_end': clock(_times[3]),
      'morning_start_tolerance': _tolerances[0], 'morning_end_tolerance': _tolerances[1], 'afternoon_start_tolerance': _tolerances[2], 'afternoon_end_tolerance': _tolerances[3],
    });
    if (!mounted) return;
    setState(() {
      _loading = false;
      response.when(
          ok: (value) => _report = value,
          err: (failure) => _error = failure.message);
    });
  }

  Future<void> _pick(bool start) async {
    final value = await showDatePicker(
        context: context,
        initialDate: start ? _from : _to,
        firstDate: DateTime(1901),
        lastDate: DateTime(9998, 12, 31));
    if (!mounted || value == null) return;
    setState(() {
      if (start) {
        _from = value;
      } else {
        _to = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = _report;
    final employee = report?.employee;
    final shifts = report?.configuredShifts ?? const <String>[];
    // Días sin marcación RAW: se ocultan por defecto y solo cambian la vista.
    final allDays = report?.days ?? const <ServerAttendanceDay>[];
    final visibleDays = _showEmptyDays
        ? allDays
        : allDays.where((day) => day.records.isNotEmpty).toList(growable: false);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
              onPressed: () => context.go(Routes.attendance),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver a funcionarios'))),
      const SizedBox(height: 8),
      DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const OfficialLogo(compact: true, width: 44),
            const SizedBox(height: 10),
            Text(AppIdentity.institution.toUpperCase(),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text('REPORTE DE ASISTENCIA',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (report?.period != null)
              Text('Período: ${attendancePeriod(report!.period, true)}',
                  textAlign: TextAlign.center),
            const Divider(height: 24),
            if (employee != null) ...[
              _ReportFields(fields: [
                ('Funcionario', employee.name),
                ('Documento', employee.document ?? '—'),
                ('Cargo', employee.position ?? '—'),
                ('Unidad / área', employee.unit ?? '—'),
                ('Turno', shifts.isEmpty ? '—' : shifts.join(', ')),
              ]),
              const SizedBox(height: 12),
            ],
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton(
                  onPressed: _loading ? null : () => _pick(true),
                  child: Text('Desde: ${attendanceDate(_from)}')),
              OutlinedButton(
                  onPressed: _loading ? null : () => _pick(false),
                  child: Text('Hasta: ${attendanceDate(_to)}')),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var index = 0; index < 4; index++) JournalControl(
                label: const ['Inicio 1ra jornada', 'Fin 1ra jornada', 'Inicio 2da jornada', 'Fin 2da jornada'][index],
                value: _times[index], tolerance: _tolerances[index], disabled: _loading,
                onTime: () async { final value = await showTimePicker(context: context, initialTime: _times[index], builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!)); if (value != null && mounted) setState(() => _times[index] = value); },
                onTolerance: (value) { _tolerances[index] = int.tryParse(value) ?? -1; }),
              FilledButton(
                  onPressed: _loading ? null : _load,
                  child: const Text('Consultar')),
            ]),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null)
              AttendanceNotice(_error!, error: true)
            else if (report != null) ...[
              if (!report.days.any((day) => day.records.isNotEmpty))
                const AttendanceNotice(
                    'No existen marcaciones biométricas para este funcionario en el período seleccionado.'),
              if (report.pending.isNotEmpty) AttendancePending(report.pending),
              const SizedBox(height: 8),
              _EmptyDaysToggle(
                showEmptyDays: _showEmptyDays,
                visibleDays: visibleDays.length,
                totalDays: report.days.length,
                onChanged: (value) => setState(() => _showEmptyDays = value),
              ),
              const SizedBox(height: 8),
              _DailyReportTable(days: visibleDays),
              const SizedBox(height: 16),
              Text('TOTALES DEL PERÍODO',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _ReportFields(fields: [
                ('Marcaciones', report.summary?.records.toString() ?? '—'),
                (
                  'Días con observación',
                  (report.summary?.evaluated ?? 0) > 0
                      ? report.summary!.observations.toString()
                      : '—'
                ),
                (
                  'Atrasos (min)',
                  attendanceMinutes(report.summary?.lateMinutes)
                ),
                (
                  'Salidas anticipadas (min)',
                  attendanceMinutes(report.summary?.earlyMinutes)
                ),
                ('Ausencia (min)', attendanceMinutes(report.summary?.absenceMinutes)),
                ('Horas extra (min)', attendanceMinutes(report.summary?.overtimeMinutes)),
              ]),
            ],
          ]),
        ),
      ),
    ]);
  }
}

class _ReportFields extends StatelessWidget {
  const _ReportFields({required this.fields});
  final List<(String, String)> fields;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Table(
      border: TableBorder.all(color: theme.dividerColor),
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final (label, value) in fields)
          TableRow(children: [
            ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(value,
                  style: TextStyle(
                    fontWeight: label == 'Funcionario'
                        ? FontWeight.w700
                        : FontWeight.normal,
                  )),
            ),
          ]),
      ],
    );
  }
}

/// Control para mostrar u ocultar los días sin marcación RAW.
///
/// Es únicamente visual: no altera los datos, la evaluación ni los totales.
class _EmptyDaysToggle extends StatelessWidget {
  const _EmptyDaysToggle({
    required this.showEmptyDays,
    required this.visibleDays,
    required this.totalDays,
    required this.onChanged,
  });

  final bool showEmptyDays;
  final int visibleDays;
  final int totalDays;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: showEmptyDays,
            onChanged: (value) => onChanged(value ?? false),
          ),
        ),
        const SizedBox(width: 8),
        // Flexible: el rótulo se ajusta al ancho disponible en pantallas compactas.
        Flexible(
          child: Text('Mostrar días sin marcación',
              style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            '$visibleDays de $totalDays días',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _DailyReportTable extends StatelessWidget {
  const _DailyReportTable({required this.days});
  final List<ServerAttendanceDay> days;

  void _showMarks(BuildContext context, ServerAttendanceDay day) {
    // Solo la hora de cada marcación RAW, en orden cronológico y numerada.
    // No se interpretan como entrada ni salida.
    final marks = day.records.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Marcaciones · ${attendanceDate(day.date)}'),
              scrollable: true,
              content: SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < marks.length; index++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: SelectableText(
                              'Marcación ${index + 1}: '
                              '${DateFormat('HH:mm:ss').format(marks[index].timestamp)}'),
                        ),
                    ],
                  )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final theme = Theme.of(context);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: box.maxWidth),
            child: DataTable(
              border: TableBorder.all(color: theme.dividerColor),
              dataTextStyle: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()]),
              headingTextStyle: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              headingRowColor: WidgetStatePropertyAll(
                  theme.colorScheme.surfaceContainerHighest),
              headingRowHeight: 42,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 40,
              columnSpacing: 12,
              horizontalMargin: 8,
              columns: [
                for (final title in const [
                  'Fecha',
                  'Entrada',
                  'Salida',
                  'Retorno',
                  'Salida final',
                  'Marcaciones',
                  'Atraso (min)',
                  'Salida anticipada (min)',
                  'Ausencia (min)',
                  'Horas extra (min)',
                  'Justificación / observación',
                  'Estado',
                  'Evidencia',
                ])
                  DataColumn(
                    numeric: title.endsWith('(min)'),
                    label: Text(title),
                  ),
              ],
              rows: [
                for (final day in days)
                  DataRow(cells: [
                    DataCell(Text(attendanceDate(day.date))),
                    for (final stamp in [
                      day.morningEntry,
                      day.morningExit,
                      day.afternoonEntry,
                      day.finalExit
                    ])
                      DataCell(Text(attendanceTime(stamp))),
                    DataCell(Text('${day.records.length}')),
                    for (final minutes in [
                      day.lateMinutes,
                      day.earlyMinutes,
                      day.absenceMinutes,
                      day.overtimeMinutes
                    ])
                      DataCell(Text(attendanceMinutes(minutes))),
                    DataCell(day.incidents.isEmpty
                        ? const Text('—')
                        : Tooltip(message: day.incidents.map((incident) => incident.description).join('\n'),
                            child: Text(day.incidents.map((incident) => incident.description).join('; '), maxLines: 2, overflow: TextOverflow.ellipsis))),
                    DataCell(AttendanceStatusBadge(day.status)),
                    DataCell(day.records.isEmpty
                        ? const Text('—')
                        : TextButton(
                            onPressed: () => _showMarks(context, day),
                            child: Text(
                                'Ver marcaciones (${day.records.length})'))),
                  ]),
              ],
            ),
          ),
        );
      });
}
