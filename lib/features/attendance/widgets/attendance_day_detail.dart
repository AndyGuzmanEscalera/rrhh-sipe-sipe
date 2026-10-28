import 'package:flutter/material.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import '../models/attendance_presentation.dart';
import 'attendance_common.dart';

class AttendanceDayDetail extends StatelessWidget {
  const AttendanceDayDetail({required this.day, super.key});
  final ServerAttendanceDay day;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Detalle del día · ${attendanceDate(day.date)}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Align(
                alignment: Alignment.centerLeft,
                child: AttendanceStatusBadge(day.status)),
            const SizedBox(height: 12),
            Text(day.shift ?? 'Turno no determinado',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (day.expectedTimes.isNotEmpty)
              Text(
                  'Horario esperado: ${day.expectedTimes.map((time) => attendanceTime(time)).join(' · ')}',
                  style: const TextStyle(fontSize: 12)),
            const Divider(height: 24),
            for (final event in [
              ('Entrada principal', day.morningEntry),
              ('Salida primera jornada', day.morningExit),
              ('Entrada segunda jornada', day.afternoonEntry),
              ('Salida final', day.finalExit)
            ])
              if (event.$2 != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(
                          child: Text(event.$1,
                              style: const TextStyle(fontSize: 12))),
                      Text(attendanceTime(event.$2, seconds: true)),
                    ])),
            const SizedBox(height: 10),
            Wrap(spacing: 16, runSpacing: 8, children: [
              Text('Atraso: ${attendanceMinutes(day.lateMinutes)} min',
                  style: const TextStyle(fontSize: 12)),
              Text(
                  'Salida anticipada: ${attendanceMinutes(day.earlyMinutes)} min',
                  style: const TextStyle(fontSize: 12)),
              if (day.grossEarlyMinutes != null && day.earlyMinutes == null)
                Text(
                    'Tiempo bruto anterior: ${attendanceMinutes(day.grossEarlyMinutes)} min',
                    style: const TextStyle(fontSize: 12)),
              Text('Ausencia: ${attendanceMinutes(day.absenceMinutes)} min',
                  style: const TextStyle(fontSize: 12)),
              if (day.nonEvaluableMinutes != null)
                Text(
                    'No evaluable: ${attendanceMinutes(day.nonEvaluableMinutes)} min'),
              if (day.overtimeMinutes != null)
                Text(
                    'Horas extra: ${attendanceMinutes(day.overtimeMinutes)} min'),
            ]),
            if (day.status == 'NO_DATA')
              const AttendanceNotice(
                  'Sin datos suficientes o sin cobertura confirmada. Esto no equivale a ausencia.'),
            for (final dependency in day.pending)
              AttendanceNotice(attendanceDependency(dependency)),
            const Divider(height: 24),
            const Text('Marcaciones originales',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (day.records.isEmpty)
              const Text('No hay marcaciones para este día.',
                  style: TextStyle(fontSize: 12)),
            for (final mark in day.records)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(attendanceTime(mark.timestamp, seconds: true),
                      style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()]))),
            if (day.records.isNotEmpty)
              ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Datos técnicos originales',
                      style: TextStyle(fontSize: 12)),
                  children: [
                    for (final mark in day.records)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: SelectableText(
                                  '${attendanceTime(mark.timestamp, seconds: true)} · status: ${mark.status ?? '—'} · punch: ${mark.punch ?? '—'}\nFuente: ${mark.source}\nrecord_id: ${mark.recordId}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: UiColors.textSecondary))))
                  ]),
            if (day.incidents.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Incidencias',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              for (final incident in day.incidents)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(
                                incident.severity == 'ANOMALY'
                                    ? Icons.warning_amber_rounded
                                    : Icons.info_outline,
                                size: 16,
                                color:
                                    attendanceStatusColor(incident.severity)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(
                                    attendanceIncidentLabel(incident.type),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)))
                          ]),
                          Text(incident.description,
                              style: const TextStyle(fontSize: 12)),
                          if (incident.minutes != null)
                            Text('${attendanceMinutes(incident.minutes)} min',
                                style: const TextStyle(fontSize: 11)),
                        ])),
            ],
            if (day.suggestions.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Sugerencias del sistema',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              for (final suggestion in day.suggestions)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(suggestion.description,
                              style: const TextStyle(fontSize: 12)),
                          if (suggestion.suggestedRecordId != null)
                            SelectableText(
                                'Marcación sugerida: ${suggestion.suggestedRecordId}',
                                style: const TextStyle(fontSize: 11))
                        ])),
              const AttendanceNotice(
                  'Las sugerencias requieren revisión. No se aplican cambios automáticamente.'),
            ],
          ]));
}
