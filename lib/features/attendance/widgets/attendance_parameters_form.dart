import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/form/app_form_field_style.dart';
import '../cubit/attendance_cubit.dart';
import 'attendance_common.dart';

class AttendanceParametersForm extends StatefulWidget {
  const AttendanceParametersForm(
      {required this.parameters,
      required this.canManage,
      required this.busy,
      required this.error,
      required this.notice,
      super.key});
  final AttendanceParameters parameters;
  final bool canManage, busy;
  final String error, notice;
  @override
  State<AttendanceParametersForm> createState() =>
      _AttendanceParametersFormState();
}

class _AttendanceParametersFormState extends State<AttendanceParametersForm> {
  final _form = GlobalKey<FormState>();
  final _validFrom = TextEditingController();
  final _validTo = TextEditingController();
  final _controllers = {
    for (final key in AttendanceParameters.keys) key: TextEditingController()
  };
  static const labels = [
    'Tolerancia entrada primera jornada',
    'Tolerancia salida primera jornada',
    'Tolerancia entrada segunda jornada',
    'Tolerancia salida final',
    'Tiempo mínimo salida–retorno',
    'Ventana de posibles duplicados'
  ];
  @override
  void initState() {
    super.initState();
    _fill();
  }

  @override
  void didUpdateWidget(covariant AttendanceParametersForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parameters != widget.parameters) _fill();
  }

  void _fill() {
    _validFrom.text = _iso(widget.parameters.validFrom);
    _validTo.text = _iso(widget.parameters.validTo);
    for (final key in AttendanceParameters.keys) {
      final seconds = widget.parameters.seconds[key];
      _controllers[key]!.text =
          seconds == null ? '' : (seconds / 60).toString();
    }
  }

  int? _seconds(String? text) {
    final minutes = double.tryParse((text ?? '').trim().replaceAll(',', '.'));
    if (minutes == null || !minutes.isFinite || minutes < 0 || minutes > 1440) {
      return null;
    }
    final seconds = minutes * 60;
    if ((seconds - seconds.round()).abs() > 0.000001) return null;
    return seconds.round();
  }

  String _iso(DateTime? value) => value == null
      ? ''
      : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  DateTime? _parseDay(String text) {
    final value = text.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
    final date = DateTime.tryParse(value);
    return date != null && _iso(date) == value ? date : null;
  }

  @override
  void dispose() {
    _validFrom.dispose();
    _validTo.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
            'Vigencia de la revisión. Los cambios no reemplazan parámetros históricos.',
            style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
              width: 240,
              child: TextFormField(
                key: const ValueKey('parameter-valid-from'),
                controller: _validFrom,
                enabled: widget.canManage && !widget.busy,
                decoration:
                    AppFormFieldStyle.decoration(label: 'Desde (AAAA-MM-DD)'),
                onChanged: (_) =>
                    context.read<AttendanceCubit>().parametersDirty(true),
                validator: (text) => _parseDay(text ?? '') == null
                    ? 'Ingrese una fecha válida.'
                    : null,
              )),
          SizedBox(
              width: 240,
              child: TextFormField(
                key: const ValueKey('parameter-valid-to'),
                controller: _validTo,
                enabled: widget.canManage && !widget.busy,
                decoration: AppFormFieldStyle.decoration(
                    label: 'Hasta (opcional, AAAA-MM-DD)'),
                onChanged: (_) =>
                    context.read<AttendanceCubit>().parametersDirty(true),
                validator: (text) {
                  if ((text ?? '').trim().isEmpty) return null;
                  final end = _parseDay(text!);
                  final start = _parseDay(_validFrom.text);
                  return end == null || (start != null && end.isBefore(start))
                      ? 'Revise el fin de vigencia.'
                      : null;
                },
              )),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, size) {
          final columns = size.maxWidth >= 1000
              ? 3
              : size.maxWidth >= 600
                  ? 2
                  : 1;
          final width = (size.maxWidth - 12 * (columns - 1)) / columns;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (var i = 0; i < AttendanceParameters.keys.length; i++)
              SizedBox(
                  width: width,
                  child: TextFormField(
                    key: ValueKey('parameter-${AttendanceParameters.keys[i]}'),
                    controller: _controllers[AttendanceParameters.keys[i]],
                    enabled: widget.canManage && !widget.busy,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: AppFormFieldStyle.decoration(label: labels[i])
                        .copyWith(suffixText: 'min', isDense: true),
                    onChanged: (_) =>
                        context.read<AttendanceCubit>().parametersDirty(true),
                    validator: (value) => _seconds(value) == null
                        ? 'Ingrese 0 a 1440 min, con precisión de segundos.'
                        : null,
                  )),
          ]);
        }),
        const SizedBox(height: 10),
        Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                  onPressed: !widget.canManage || widget.busy
                      ? null
                      : () {
                          if (!_form.currentState!.validate()) return;
                          context.read<AttendanceCubit>().saveParameters({
                            'valid_from': _validFrom.text.trim(),
                            'valid_to': _validTo.text.trim().isEmpty
                                ? null
                                : _validTo.text.trim(),
                            for (final key in AttendanceParameters.keys)
                              key: _seconds(_controllers[key]!.text)!
                          });
                        },
                  icon: const Icon(Icons.save_outlined, size: 17),
                  label:
                      Text(widget.busy ? 'Guardando…' : 'Guardar parámetros')),
              TextButton(
                  onPressed: widget.busy
                      ? null
                      : context.read<AttendanceCubit>().loadParameters,
                  child: const Text('Recargar guardados')),
              if (!widget.canManage)
                const Text('Solo lectura', style: TextStyle(fontSize: 12)),
            ]),
        if (widget.error.isNotEmpty)
          AttendanceNotice(widget.error, error: true),
        if (widget.notice.isNotEmpty) AttendanceNotice(widget.notice),
      ]));
}
