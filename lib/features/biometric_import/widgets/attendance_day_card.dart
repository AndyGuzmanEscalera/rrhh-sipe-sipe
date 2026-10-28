import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/app_surface.dart';
import 'attendance_status_badge.dart';

class AttendanceDayCard extends StatelessWidget {
  const AttendanceDayCard(
      {required this.day, this.configuration, this.noData = false, super.key});
  final AttendanceDay day;
  final AttendanceConfiguration? configuration;
  final bool noData;
  static String incidentLabel(IncidentType type) => switch (type) {
        IncidentType.late => 'ATRASO',
        IncidentType.earlyExit => 'SALIDA_ANTICIPADA',
        IncidentType.lateReturn => 'RETORNO_TARDIO',
        IncidentType.missingMark => 'MARCACIÓN_FALTANTE',
        IncidentType.extraMark => 'MARCACIÓN_ADICIONAL',
        IncidentType.possibleDuplicate => 'POSIBLE_DUPLICADO',
        IncidentType.intermediateExit => 'SALIDA_INTERMEDIA',
        IncidentType.inconsistentSequence => 'SECUENCIA_INCOHERENTE',
        IncidentType.configurationMissing => 'CONFIGURACIÓN_PENDIENTE',
        IncidentType.unknownMarkType => 'TIPO_SIN_CONFIGURAR',
      };
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AppSurface(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                        '${const [
                          'Lunes',
                          'Martes',
                          'Miércoles',
                          'Jueves',
                          'Viernes',
                          'Sábado',
                          'Domingo'
                        ][day.date.weekday - 1]} '
                        '${day.date.day.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(DateFormat('dd/MM/yyyy').format(day.date)),
                    if (noData)
                      const Chip(label: Text('SIN DATOS'))
                    else
                      AttendanceStatusBadge(status: day.status),
                  ]),
              const SizedBox(height: 12),
              Text(
                  '${day.records.length} marcaciones originales, en orden cronológico.'),
              if (day.records.isEmpty)
                const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Sin marcaciones en esta fecha del período.')),
              for (final record in day.records)
                Padding(
                    key: ValueKey('original-${record.lineNumber}'),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(DateFormat('HH:mm:ss').format(record.timestamp),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text('Línea original ${record.lineNumber}'),
                          if (configuration != null)
                            Text(
                                'Tipo/código original: ${configuration!.rawType(record)}'),
                          Text(
                              'Campo 3: ${record.field3} · Campo 4: ${record.field4}'),
                          Text(
                              'Campo 5: ${record.field5} · Campo 6: ${record.field6}'),
                          const SizedBox(height: 4),
                          SelectableText(record.rawLine,
                              style: const TextStyle(fontSize: 12)),
                          const Divider(),
                        ])),
              for (final incident in day.incidents)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: incident.status == AttendanceStatus.anomaly
                                ? const Color(0xFFFEE2E2)
                                : UiColors.warningSoft,
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(incidentLabel(incident.type),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(incident.message),
                              if (incident.suggestion != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                    'Sugerencia: ${incident.suggestion!.message}'),
                                const Text(
                                    'Revisión pendiente. Aceptar/ignorar se habilitará en una etapa posterior.'),
                              ],
                            ]))),
            ])),
      );
}
