import 'package:flutter/material.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_status_badge.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import '../models/attendance_presentation.dart';

class AttendanceStatusBadge extends StatelessWidget {
  const AttendanceStatusBadge(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) => AppStatusBadge(
      label: attendanceStatusLabel(status),
      variant: switch (status) {
        'NORMAL' => AppStatusBadgeVariant.success,
        'OBSERVATION' => AppStatusBadgeVariant.warning,
        'ANOMALY' => AppStatusBadgeVariant.danger,
        _ => AppStatusBadgeVariant.neutral
      });
}

class AttendanceNotice extends StatelessWidget {
  const AttendanceNotice(this.message,
      {this.error = false, this.onRetry, super.key});
  final String message;
  final bool error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(error ? Icons.error_outline : Icons.info_outline,
            size: 18, color: error ? UiColors.danger : UiColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 12,
                    color: error ? UiColors.danger : UiColors.textSecondary))),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ]));
}

class AttendancePending extends StatelessWidget {
  const AttendancePending(this.dependencies, {super.key});
  final List<String> dependencies;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AttendanceNotice(
            'El reporte aún no puede evaluarse completamente.'),
        for (final item in dependencies)
          Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 4),
              child: Text('• ${attendanceDependency(item)}',
                  style: const TextStyle(fontSize: 12))),
      ]);
}

class AttendanceSummaryStrip extends StatelessWidget {
  const AttendanceSummaryStrip(this.summary, {super.key});
  final AttendanceSummary? summary;
  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) {
      return const AttendanceNotice(
          'No hay un resumen evaluado para este período.');
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 20, runSpacing: 10, children: [
        for (final pair in [
          ('Normales', '${s.normal}'),
          ('Observaciones', '${s.observations}'),
          ('Anomalías', '${s.anomalies}'),
          ('Atraso (min)', attendanceMinutes(s.lateMinutes)),
          ('Salida anticipada (min)', attendanceMinutes(s.earlyMinutes)),
          ('Incidencias', '${s.incidents}'),
          ('Marcaciones', '${s.records}')
        ])
          Text.rich(TextSpan(children: [
            TextSpan(
                text: '${pair.$1}  ',
                style: const TextStyle(
                    fontSize: 11, color: UiColors.textSecondary)),
            TextSpan(
                text: pair.$2,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))
          ])),
      ]),
      if (!s.totalsComplete)
        const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
                'Totales incompletos o cobertura sin confirmar. — indica un valor no determinado.',
                style: TextStyle(fontSize: 11, color: UiColors.textMuted))),
    ]);
  }
}
