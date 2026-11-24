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
  bool _singleShift = false;
  final _tolerances = List<int>.filled(4, 5);
  final _times = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 18, minute: 0)
  ];

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
    if (_tolerances.take(_singleShift ? 2 : 4).any((value) => value < 0)) {
      setState(
          () => _error = 'Las tolerancias deben ser enteros no negativos.');
      return;
    }
    final format = DateFormat('yyyy-MM-dd');
    final first = _times[0].hour * 60 + _times[0].minute;
    final second = _times[1].hour * 60 + _times[1].minute;
    final third = _times[2].hour * 60 + _times[2].minute;
    final fourth = _times[3].hour * 60 + _times[3].minute;
    if (_singleShift
        ? first >= second
        : !(first < second && second < third && third < fourth)) {
      setState(() => _error = _singleShift
          ? 'La hora de salida debe ser posterior a la hora de entrada.'
          : 'La jornada debe mantener el orden de entrada y salida.');
      return;
    }
    setState(() => _loading = true);
    String clock(TimeOfDay value) =>
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    final evaluation = <String, Object?>{
      'single_shift': _singleShift,
      'morning_start': clock(_times[0]),
      'morning_end': clock(_times[1]),
      'morning_start_tolerance': _tolerances[0],
      'morning_end_tolerance': _tolerances[1],
      if (!_singleShift) ...{
        'afternoon_start': clock(_times[2]),
        'afternoon_end': clock(_times[3]),
        'afternoon_start_tolerance': _tolerances[2],
        'afternoon_end_tolerance': _tolerances[3],
      },
    };
    final response = await sl<AttendanceRepository>().reportRange(
        widget.employeeId, format.format(_from), format.format(_to),
        evaluation: evaluation);
    if (!mounted) return;
    setState(() {
      _loading = false;
      response.when(
          ok: (value) => _report = value,
          err: (failure) => _error = failure.message);
    });
  }

  Future<void> _pickRange() async {
    final value = await showDateRangePicker(
        context: context,
        initialDateRange: DateTimeRange(start: _from, end: _to),
        firstDate: DateTime(1901),
        lastDate: DateTime(9998, 12, 31),
        locale: const Locale('es', 'BO'),
        helpText: 'Periodo de consulta',
        cancelText: 'Cancelar',
        confirmText: 'Aplicar',
        saveText: 'Aplicar');
    if (!mounted || value == null) return;
    setState(() {
      _from = value.start;
      _to = value.end;
    });
  }

  Future<void> _pickTime(int index) async {
    final value = await showTimePicker(
        context: context,
        initialTime: _times[index],
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!));
    if (value != null && mounted) setState(() => _times[index] = value);
  }

  Widget _scheduleControls(List<int> indexes) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final index in indexes)
            JournalControl(
              key:
                  ValueKey('journal-${_singleShift ? 'single' : 'two'}-$index'),
              label: _singleShift
                  ? const ['Hora de entrada', 'Hora de salida'][index]
                  : const ['Hora de entrada', 'Hora de salida'][index % 2],
              value: _times[index],
              tolerance: _tolerances[index],
              disabled: _loading,
              onTime: () => _pickTime(index),
              onTolerance: (value) => setState(() {
                _tolerances[index] = int.tryParse(value) ?? -1;
              }),
            ),
        ],
      );

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
        : allDays
            .where((day) => day.records.isNotEmpty)
            .toList(growable: false);
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
            SizedBox(
              width: 360,
              child: InkWell(
                key: const ValueKey('attendance-date-range'),
                onTap: _loading ? null : _pickRange,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Periodo de consulta',
                    prefixIcon: Icon(Icons.date_range),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${DateFormat('dd/MM/yyyy', 'es_BO').format(_from)} — '
                    '${DateFormat('dd/MM/yyyy', 'es_BO').format(_to)}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              key: const ValueKey('single-shift-toggle'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Una sola jornada'),
              value: _singleShift,
              onChanged: _loading
                  ? null
                  : (value) => setState(() => _singleShift = value ?? false),
            ),
            const SizedBox(height: 4),
            Text('Horario de trabajo',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_singleShift)
              _scheduleControls(const [0, 1])
            else
              LayoutBuilder(builder: (context, constraints) {
                final groups = [
                  ('Primera jornada', const [0, 1]),
                  ('Segunda jornada', const [2, 3]),
                ];
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (final (label, indexes) in groups)
                      SizedBox(
                        width: constraints.maxWidth >= 1050
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label.toUpperCase(),
                                style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary)),
                            const SizedBox(height: 5),
                            _scheduleControls(indexes),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            const SizedBox(height: 10),
            FilledButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.search),
                label: const Text('Consultar')),
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
              _DailyReportTable(
                  days: visibleDays, singleShift: report.singleShift),
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
                (
                  'Ausencia (min)',
                  attendanceMinutes(report.summary?.absenceMinutes)
                ),
                (
                  'Horas extra (min)',
                  attendanceMinutes(report.summary?.overtimeMinutes)
                ),
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
  const _DailyReportTable({required this.days, required this.singleShift});
  final List<ServerAttendanceDay> days;
  final bool singleShift;

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
                          child: SelectableText('Marcación ${index + 1}: '
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
                for (final title in [
                  'Fecha',
                  if (singleShift) ...[
                    'Entrada',
                    'Salida'
                  ] else ...[
                    'Entrada 1ra jornada',
                    'Salida 1ra jornada',
                    'Entrada 2da jornada',
                    'Salida 2da jornada',
                  ],
                  'Atraso (min)',
                  'Salida anticipada (min)',
                  'Ausencia (min)',
                  'Horas extra (min)',
                  'Marcaciones',
                  'Estado',
                  'Observaciones',
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
                    for (final stamp in singleShift
                        ? [day.morningEntry, day.finalExit]
                        : [
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
                        : Tooltip(
                            message: day.incidents
                                .map((incident) => incident.description)
                                .join('\n'),
                            child: Text(
                                day.incidents
                                    .map((incident) => incident.description)
                                    .join('; '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis))),
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
