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

  Widget _scheduleControls(List<int> indexes) => LayoutBuilder(
        builder: (context, constraints) {
          final controlWidth = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final index in indexes)
                JournalControl(
                  key: ValueKey(
                      'journal-${_singleShift ? 'single' : 'two'}-$index'),
                  width: controlWidth,
                  label: const ['Entrada', 'Salida'][index % 2],
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
        },
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
    return LayoutBuilder(builder: (context, pageConstraints) {
      final pageWidth = pageConstraints.maxWidth;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                onPressed: () => context.go(Routes.attendance),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Volver a funcionarios'))),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.dividerColor),
          ),
          child: Padding(
            padding: EdgeInsets.all(pageWidth < 600 ? 10 : 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReportHeading(period: report?.period),
                  const Divider(height: 18),
                  if (employee != null) ...[
                    _ReportFields(fields: [
                      ('Funcionario', employee.name),
                      ('CI', employee.document ?? '—'),
                      ('Cargo', employee.position ?? '—'),
                      ('Unidad / área', employee.unit ?? '—'),
                      ('Turno', shifts.isEmpty ? '—' : shifts.join(', ')),
                    ]),
                    const SizedBox(height: 10),
                  ],
                  LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final groups = _singleShift
                        ? <(String, List<int>)>[
                            ('Jornada única', const [0, 1])
                          ]
                        : <(String, List<int>)>[
                            ('Primera jornada', const [0, 1]),
                            ('Segunda jornada', const [2, 3]),
                          ];
                    final groupWidth = width < 600
                        ? width
                        : ((width - 12) / 2).clamp(300.0, 460.0).toDouble();
                    final periodWidth = width < 600 ? width : 230.0;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: periodWidth,
                          child: InkWell(
                            key: const ValueKey('attendance-date-range'),
                            onTap: _loading ? null : _pickRange,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Periodo de consulta',
                                prefixIcon: Icon(Icons.date_range, size: 19),
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 9),
                              ),
                              child: Text(
                                '${DateFormat('dd/MM/yyyy', 'es_BO').format(_from)} — '
                                '${DateFormat('dd/MM/yyyy', 'es_BO').format(_to)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: width < 600 ? width : 180,
                          child: Row(children: [
                            Checkbox(
                              key: const ValueKey('single-shift-toggle'),
                              value: _singleShift,
                              visualDensity: VisualDensity.compact,
                              onChanged: _loading
                                  ? null
                                  : (value) => setState(
                                      () => _singleShift = value ?? false),
                            ),
                            const Expanded(child: Text('Una sola jornada')),
                          ]),
                        ),
                        for (final (label, indexes) in groups)
                          SizedBox(
                            width: groupWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary)),
                                const SizedBox(height: 3),
                                _scheduleControls(indexes),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: width < 600 ? width : 132,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _load,
                            style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10)),
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('Consultar'),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  if (_loading)
                    const LinearProgressIndicator()
                  else if (_error != null)
                    AttendanceNotice(_error!, error: true)
                  else if (report != null) ...[
                    if (!report.days.any((day) => day.records.isNotEmpty))
                      const AttendanceNotice(
                          'No existen marcaciones biométricas para este funcionario en el período seleccionado.'),
                    if (report.pending.isNotEmpty)
                      AttendancePending(report.pending),
                    const SizedBox(height: 8),
                    _EmptyDaysToggle(
                      showEmptyDays: _showEmptyDays,
                      visibleDays: visibleDays.length,
                      totalDays: report.days.length,
                      onChanged: (value) =>
                          setState(() => _showEmptyDays = value),
                    ),
                    const SizedBox(height: 8),
                    _DailyReportTable(
                        days: visibleDays, singleShift: report.singleShift),
                    const SizedBox(height: 16),
                    Text('INDICADORES DEL PERÍODO',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    _ReportSummary(summary: report.summary),
                  ],
                ]),
          ),
        ),
      ]);
    });
  }
}

class _ReportHeading extends StatelessWidget {
  const _ReportHeading({required this.period});
  final AttendancePeriod? period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const OfficialLogo(compact: true, width: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Text(AppIdentity.institution.toUpperCase(),
                  textAlign: compact ? TextAlign.start : TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: .4)),
              Text('REPORTE DE ASISTENCIA',
                  textAlign: compact ? TextAlign.start : TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (!compact && period != null) ...[
          const SizedBox(width: 10),
          Text('Período: ${attendancePeriod(period!, true)}',
              style: theme.textTheme.bodySmall),
        ],
      ]);
    });
  }
}

class _ReportFields extends StatelessWidget {
  const _ReportFields({required this.fields});
  final List<(String, String)> fields;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final columns = switch (constraints.maxWidth) {
        >= 1200 => 5,
        >= 900 => 4,
        >= 600 => 3,
        >= 400 => 2,
        _ => 1,
      };
      const spacing = 6.0;
      final cellWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final (label, value) in fields)
            SizedBox(
              width: cellWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(.35),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(value,
                          softWrap: true,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: label == 'Funcionario'
                                ? FontWeight.w700
                                : FontWeight.normal,
                          )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.summary});
  final AttendanceSummary? summary;

  @override
  Widget build(BuildContext context) {
    final values = <(String, String)>[
      ('Marcaciones', summary?.records.toString() ?? '—'),
      (
        'Días con observación',
        (summary?.evaluated ?? 0) > 0 ? summary!.observations.toString() : '—'
      ),
      ('Atrasos (min)', attendanceMinutes(summary?.lateMinutes)),
      ('Salidas anticipadas (min)', attendanceMinutes(summary?.earlyMinutes)),
      ('Ausencia (min)', attendanceMinutes(summary?.absenceMinutes)),
      ('Horas extra (min)', attendanceMinutes(summary?.overtimeMinutes)),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = ((constraints.maxWidth + 8) / 158).floor().clamp(1, 4);
      const spacing = 8.0;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      final theme = Theme.of(context);
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final (label, value) in values)
            SizedBox(
              width: width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(.35),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(value,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
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
              headingRowHeight: 40,
              dataRowMinHeight: 32,
              dataRowMaxHeight: double.infinity,
              columnSpacing: 8,
              horizontalMargin: 6,
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
                    label: SizedBox(
                      width: switch (title) {
                        'Fecha' => 82,
                        'Entrada' || 'Salida' => 100,
                        'Entrada 1ra jornada' ||
                        'Salida 1ra jornada' ||
                        'Entrada 2da jornada' ||
                        'Salida 2da jornada' =>
                          122,
                        'Marcaciones' => 82,
                        'Estado' => 92,
                        'Observaciones' => 240,
                        'Evidencia' => 142,
                        _ => 86,
                      },
                      child: Text(title, softWrap: true),
                    ),
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
                        : SizedBox(
                            width: 240,
                            child: Text(
                              day.incidents
                                  .map((incident) => incident.description)
                                  .join('; '),
                              softWrap: true,
                            ),
                          )),
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
