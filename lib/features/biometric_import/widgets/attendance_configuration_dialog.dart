import 'package:flutter/material.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/app_form_dialog.dart';

class AttendanceConfigurationDialog extends StatefulWidget {
  const AttendanceConfigurationDialog({required this.configuration, super.key});
  final AttendanceConfiguration configuration;
  @override
  State<AttendanceConfigurationDialog> createState() =>
      _AttendanceConfigurationDialogState();
}

class _AttendanceConfigurationDialogState
    extends State<AttendanceConfigurationDialog> {
  late final TextEditingController _schedule,
      _tolerance,
      _duplicate,
      _matching,
      _entries,
      _exits;
  late Set<int> _weekdays;
  late BiometricTypeField _field;
  String? _error;
  @override
  void initState() {
    super.initState();
    final config = widget.configuration;
    _schedule = TextEditingController(
        text: config.expectedMarks
            .map((mark) =>
                '${(mark.minuteOfDay ~/ 60).toString().padLeft(2, '0')}:${(mark.minuteOfDay % 60).toString().padLeft(2, '0')} '
                '${mark.direction == MarkDirection.entry ? 'E' : 'S'}')
            .join('\n'));
    _tolerance =
        TextEditingController(text: '${config.lateTolerance.inMinutes}');
    _duplicate =
        TextEditingController(text: '${config.duplicateWindow.inMinutes}');
    _matching =
        TextEditingController(text: '${config.matchingWindow.inMinutes}');
    _entries = TextEditingController(
        text: config.typeCodes.entries
            .where((e) => e.value == MarkDirection.entry)
            .map((e) => e.key)
            .join(', '));
    _exits = TextEditingController(
        text: config.typeCodes.entries
            .where((e) => e.value == MarkDirection.exit)
            .map((e) => e.key)
            .join(', '));
    _weekdays = Set.of(config.workingWeekdays);
    _field = config.typeField;
  }

  @override
  void dispose() {
    for (final controller in [
      _schedule,
      _tolerance,
      _duplicate,
      _matching,
      _entries,
      _exits
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    try {
      final config = const AttendanceConfigurationParser().parse(
          schedule: _schedule.text,
          weekdays: _weekdays,
          toleranceMinutes: _tolerance.text,
          duplicateMinutes: _duplicate.text,
          matchingMinutes: _matching.text,
          typeField: _field,
          entryCodes: _entries.text,
          exitCodes: _exits.text);
      Navigator.pop(context, config);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Widget _number(TextEditingController controller, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label)));
  @override
  Widget build(BuildContext context) => AppFormDialog(
        title: 'Configurar análisis',
        maxWidth: 620,
        onSubmit: _save,
        submitLabel: 'Aplicar al análisis',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text(
          'Configuración de esta sesión. E = entrada, S = salida. '
              'Confirme el horario real; el ejemplo no se aplica automáticamente. '
              'Los originales permanecen intactos.'),
          const SizedBox(height: 16),
          TextField(
              controller: _schedule,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                  labelText: 'Horario esperado (una marca por línea)',
                  hintText: '08:00 E\n12:00 S\n14:00 E\n18:00 S')),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (var i = 1; i <= 7; i++)
              FilterChip(
                  label: Text(const [
                    'Lun',
                    'Mar',
                    'Mié',
                    'Jue',
                    'Vie',
                    'Sáb',
                    'Dom'
                  ][i - 1]),
                  selected: _weekdays.contains(i),
                  onSelected: (value) => setState(() {
                        if (value) {
                          _weekdays.add(i);
                        } else {
                          _weekdays.remove(i);
                        }
                      }))
          ]),
          const SizedBox(height: 16),
          _number(_tolerance, 'Tolerancia de atraso (minutos)'),
          _number(_duplicate, 'Ventana de posibles duplicados (minutos)'),
          _number(
              _matching, 'Ventana para asociar una marca al horario (minutos)'),
          DropdownButtonFormField<BiometricTypeField>(
              value: _field,
              decoration: const InputDecoration(
                  labelText: 'Campo del tipo de marcación'),
              items: [
                for (final field in BiometricTypeField.values)
                  DropdownMenuItem(
                      value: field, child: Text('Campo ${field.index + 3}'))
              ],
              onChanged: (value) => setState(() => _field = value!)),
          const SizedBox(height: 16),
          TextField(
              controller: _entries,
              decoration: const InputDecoration(
                  labelText: 'Códigos de entrada (separados por coma)')),
          const SizedBox(height: 16),
          TextField(
              controller: _exits,
              decoration: const InputDecoration(
                  labelText: 'Códigos de salida (separados por coma)')),
          const SizedBox(height: 12),
          const Text(
              'Sin códigos confirmados, solo se compara la proximidad horaria y '
              'el valor original del campo para posibles duplicados. No se interpretan salidas ni retornos.'),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
        ]),
      );
}
