import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/auth/permissions.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';
import 'package:rrhh_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:rrhh_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:rrhh_sipe_sipe/features/home/side_menu/helpers/menu_options.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/app_surface.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/form/app_form_field_style.dart';
import '../cubit/attendance_cubit.dart';
import '../models/attendance_presentation.dart';
import '../widgets/attendance_common.dart';
import '../widgets/attendance_parameters_form.dart';
import '../widgets/attendance_results_section.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});
  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceCubit>().initialize();
  }

  Future<void> _sync() async {
    final cubit = context.read<AttendanceCubit>();
    final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(1901),
        lastDate: DateTime(9998, 12, 31),
        initialDateRange: DateTimeRange(
            start: DateTime(cubit.state.year, cubit.state.month),
            end: DateTime(cubit.state.year, cubit.state.month + 1, 0)),
        helpText: 'Rango de consulta para la sincronización',
        saveText: 'Continuar');
    if (!mounted || range == null) return;
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Sincronizar biométrico'),
                content: const Text(
                    'El backend descargará las marcaciones del rango seleccionado '
                    'desde la API biométrica y las guardará sin duplicados. '
                    'Puede tardar según el tamaño del período.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sincronizar'))
                ]));
    if (accepted == true && mounted) {
      await cubit.synchronize(range.start, range.end);
    }
  }

  Widget _surface(List<Widget> children) => AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children));

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AttendanceCubit, AttendanceState>(builder: (context, state) {
        final cubit = context.read<AttendanceCubit>();
        final manage = hasPermission(
            context.watch<AppSessionCubit>().state.userSession,
            Permissions.attendanceManage);
        final job = state.sync;
        final busy = state.startingSync || job?.isActive == true;

        final lastDate = job?.finishedAt ?? job?.startedAt ?? job?.createdAt;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                    child: Text('Asistencia Biométrica',
                        style: Theme.of(context).textTheme.titleLarge)),
                TextButton.icon(
                    onPressed: () => context.read<SideMenuCubit>().select(
                        menuOptions.firstWhere(
                            (o) => o.menu == MenuEnum.biometricImport)),
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Importar archivo'))
              ]),
              const SizedBox(height: 12),
              _surface([
                Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Sincronización',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          state.checkingDevice
                              ? 'Consultando dispositivo…'
                              : state.device?.apiAvailable == false
                                  ? 'API biométrica no disponible'
                                  : state.device?.apiAvailable == true &&
                                          state.device?.deviceConnected == false
                                      ? 'API disponible · dispositivo desconectado'
                                      : state.device?.connected == true
                                          ? '${state.device?.model ?? 'Biométrico'} · conectado (${state.device?.transport ?? '—'})'
                                          : 'Dispositivo sin conexión confirmada',
                          style: const TextStyle(fontSize: 12)),
                      TextButton(
                          onPressed:
                              state.checkingDevice ? null : cubit.refreshDevice,
                          child: const Text('Consultar conexión')),
                      OutlinedButton.icon(
                          onPressed:
                              !manage || busy || state.loading ? null : _sync,
                          icon: const Icon(Icons.sync, size: 18),
                          label: Text(busy
                              ? 'Sincronización en curso'
                              : 'Sincronizar biométrico')),
                      TextButton(
                          onPressed: cubit.refreshSync,
                          child: const Text('Actualizar estado')),
                    ]),
                if (job == null)
                  Text(
                      state.syncLoaded
                          ? 'Sin sincronizaciones registradas.'
                          : 'Última sincronización no disponible.',
                      style: const TextStyle(fontSize: 12))
                else
                  Wrap(spacing: 18, runSpacing: 5, children: [
                    Text(
                        'Última: ${lastDate == null ? '—' : DateFormat('dd/MM/yyyy HH:mm:ss').format(lastDate.toLocal())}',
                        style: const TextStyle(fontSize: 12)),
                    Text(
                        'Estado: ${const {
                              'queued': 'En cola',
                              'running': 'Descargando',
                              'completed': 'Completada',
                              'failed': 'Fallida'
                            }[job.status] ?? job.status}',
                        style: const TextStyle(fontSize: 12)),
                    Text('Descargadas: ${job.downloaded}',
                        style: const TextStyle(fontSize: 12)),
                    Text('Nuevas: ${job.newRecords}',
                        style: const TextStyle(fontSize: 12)),
                  ]),
                if (busy)
                  const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator()),
                if (job?.status == 'failed')
                  const AttendanceNotice(
                      'La sincronización falló. Revise la conexión con la API biométrica y reintente.',
                      error: true),
                if (state.deviceError.isNotEmpty)
                  AttendanceNotice(state.deviceError, error: true),
                if (state.syncError.isNotEmpty)
                  AttendanceNotice(state.syncError, error: true),
              ]),
              const SizedBox(height: 12),
              _surface([
                const Text('Filtros del reporte',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<String>(
                              key: const ValueKey('attendance-contract'),
                              isExpanded: true,
                              value: state.contractId,
                              decoration: AppFormFieldStyle.dropdownDecoration(
                                  label: 'Tipo de contrato'),
                              items: [
                                for (final contract in state.contracts?.items ??
                                    const <AttendanceContract>[])
                                  DropdownMenuItem(
                                      value: contract.id,
                                      child: Text(contract.name))
                              ],
                              onChanged: state.generating
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        cubit.selectFilter(contractId: value);
                                      }
                                    })),
                      SizedBox(
                          width: 165,
                          child: DropdownButtonFormField<int>(
                              key: const ValueKey('attendance-month'),
                              isExpanded: true,
                              value: state.month,
                              decoration: AppFormFieldStyle.dropdownDecoration(
                                  label: 'Mes'),
                              items: [
                                for (var i = 1; i <= 12; i++)
                                  DropdownMenuItem(
                                      value: i,
                                      child: Text(attendanceMonths[i - 1]))
                              ],
                              onChanged: state.generating
                                  ? null
                                  : (value) =>
                                      cubit.selectFilter(month: value))),
                      SizedBox(
                          width: 120,
                          child: DropdownButtonFormField<int>(
                              key: const ValueKey('attendance-year'),
                              isExpanded: true,
                              value: state.year,
                              decoration: AppFormFieldStyle.dropdownDecoration(
                                  label: 'Año'),
                              items: [
                                for (var i = state.year - 10;
                                    i <= state.year + 10;
                                    i++)
                                  if (i >= 1901 && i <= 9998)
                                    DropdownMenuItem(
                                        value: i, child: Text('$i'))
                              ],
                              onChanged: state.generating
                                  ? null
                                  : (value) =>
                                      cubit.selectFilter(year: value))),
                      FilledButton.icon(
                          key: const ValueKey('attendance-generate'),
                          onPressed: state.generating ||
                                  state.saving ||
                                  state.dirty ||
                                  state.filter == null ||
                                  state.loading
                              ? null
                              : cubit.generate,
                          icon: const Icon(Icons.fact_check_outlined, size: 18),
                          label: Text(state.generating
                              ? 'Generando…'
                              : 'Generar reporte')),
                    ]),
                if (state.loading)
                  const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator()),
                if (!state.loading &&
                    state.contracts != null &&
                    state.contracts!.items.isEmpty)
                  const AttendanceNotice(
                      'No hay tipos de contrato confirmados configurados.'),
                if (state.contractError.isNotEmpty)
                  AttendanceNotice(state.contractError,
                      error: true, onRetry: cubit.loadContracts),
                for (final dependency
                    in state.contracts?.pending ?? const <String>[])
                  Text(attendanceDependency(dependency),
                      style: const TextStyle(fontSize: 11)),
                const Divider(height: 26),
                const Text('Parámetros de asistencia · minutos',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (state.parameters != null)
                  AttendanceParametersForm(
                      parameters: state.parameters!,
                      canManage: manage,
                      busy: state.saving || state.generating,
                      error: state.parameterError,
                      notice: state.parameterNotice)
                else
                  AttendanceNotice(
                      state.parameterError.isEmpty
                          ? 'Cargando parámetros…'
                          : state.parameterError,
                      error: state.parameterError.isNotEmpty,
                      onRetry: cubit.loadParameters),
                if (state.dirty)
                  const AttendanceNotice(
                      'Hay parámetros sin guardar. Guárdelos o recargue los guardados antes de generar.'),
              ]),
              const SizedBox(height: 12),
              const AttendanceResultsSection(),
            ]);
      });
}
