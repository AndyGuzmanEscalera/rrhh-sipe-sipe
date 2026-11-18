import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_sipe_sipe/core/auth/permission_guard.dart';
import 'package:rrhh_sipe_sipe/core/auth/permissions.dart';
import 'package:rrhh_sipe_sipe/core/platform/format_file_size.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';
import 'package:rrhh_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/app_surface.dart';
import '../cubit/biometric_import_cubit.dart';
import '../widgets/biometric_column_selector.dart';
import '../widgets/biometric_errors_dialog.dart';
import '../widgets/biometric_preview.dart';
import '../widgets/biometric_raw_records.dart';

/// Importación biométrica.
///
/// Recibe marcaciones y las guarda en bruto. No calcula entradas, salidas,
/// atrasos, ausencias ni anomalías: la evidencia se conserva tal como llega.
class BiometricImportPage extends StatelessWidget {
  const BiometricImportPage({super.key});

  @override
  Widget build(BuildContext context) => PermissionGuard(
        permission: Permissions.attendanceRead,
        child: BiometricImportView(
          canManage: hasPermission(
              context.watch<AppSessionCubit>().state.userSession,
              Permissions.attendanceManage),
        ),
      );
}

class BiometricImportView extends StatefulWidget {
  const BiometricImportView({super.key, required this.canManage});
  final bool canManage;
  @override
  State<BiometricImportView> createState() => _BiometricImportViewState();
}

class _BiometricImportViewState extends State<BiometricImportView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BiometricImportCubit>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BiometricImportCubit, BiometricImportState>(
          builder: (context, state) {
        final cubit = context.read<BiometricImportCubit>();
        final busy = state.generalStatus == GeneralStatus.loading;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('IMPORTACIÓN BIOMÉTRICA',
              style: Theme.of(context).textTheme.headlineSmall),
          if (widget.canManage) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: busy || state.importing ? null : cubit.selectFile,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Importar archivo TXT'),
                ),
                OutlinedButton.icon(
                  onPressed: state.syncing ? null : () => _synchronize(context),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar dispositivo'),
                ),
              ],
            ),
          ],
          if (state.message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(
                  color: state.generalStatus == GeneralStatus.error
                      ? UiColors.danger
                      : UiColors.success),
            ),
          ],
          if (state.importing || state.syncing) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (widget.canManage && state.result != null) ...[
            const SizedBox(height: 24),
            _filePanel(context, cubit, state),
          ],
          const SizedBox(height: 24),
          _lastImport(context, state),
          const SizedBox(height: 24),
          _history(context, cubit, state),
          if (state.selectedBatch != null) ...[
            const SizedBox(height: 24),
            _batchDetail(context, cubit, state),
          ],
        ]);
      });

  Widget _filePanel(BuildContext context, BiometricImportCubit cubit,
      BiometricImportState state) {
    final result = state.result!;
    return AppSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Expanded(
              child: SelectableText(state.filename ?? '',
                  style: Theme.of(context).textTheme.titleMedium)),
          TextButton(
              onPressed: state.importing ? null : cubit.selectFile,
              child: const Text('Otro archivo')),
        ],
      ),
      const SizedBox(height: 4),
      Text(
          'Tamaño: ${state.size == null || state.size == 0 ? '0 B' : formatFileSize(state.size!)}'
          ' · Registros válidos: ${result.records.length}'
          ' · Líneas con error: ${result.errors.length}'),
      const SizedBox(height: 12),
      Text('Dispositivo de origen',
          style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: state.devices.contains(state.deviceId) ? state.deviceId : null,
        decoration:
            const InputDecoration(isDense: true, border: OutlineInputBorder()),
        items: state.devices
            .map((id) => DropdownMenuItem<String>(value: id, child: Text(id)))
            .toList(),
        onChanged: (value) {
          if (value != null) cubit.setDevice(value);
        },
      ),
      const SizedBox(height: 16),
      Text('Columnas del archivo',
          style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      const Text(
          'Declare qué campo contiene cada código. Los valores se copian sin '
          'interpretarlos.'),
      const SizedBox(height: 8),
      BiometricColumnSelector(
          mapping: state.mapping, onChanged: cubit.setMapping),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: state.readyToImport ? cubit.importFile : null,
            icon: const Icon(Icons.save_alt),
            label: const Text('Guardar lote'),
          ),
          if (result.errors.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BiometricErrorsDialog(errors: result.errors)),
              icon: const Icon(Icons.error_outline),
              label: const Text('Ver errores'),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Text('Previsualización', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      BiometricPreview(state: state, onPageChanged: cubit.changePage),
    ]));
  }

  Widget _lastImport(BuildContext context, BiometricImportState state) {
    final batch = state.lastImport;
    final date = DateFormat('dd/MM/yyyy HH:mm');
    final metrics = <(String, String)>[
      (
        'Fecha',
        batch?.createdAt == null
            ? '—'
            : date.format(batch!.createdAt!.toLocal())
      ),
      ('Origen', batch?.originLabel ?? '—'),
      ('Registros recibidos', '${batch?.receivedRecords ?? 0}'),
      ('Nuevos', '${batch?.newRecords ?? 0}'),
      ('Duplicados', '${batch?.duplicateRecords ?? 0}'),
      ('Errores', '${batch?.errorRecords ?? 0}'),
      ('Estado', batch?.statusLabel ?? '—'),
    ];
    return AppSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Última importación',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      for (final metric in metrics)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 190,
                  child: Text(metric.$1,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: UiColors.textSecondary))),
              Expanded(
                  child: Text(metric.$2,
                      style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
        ),
    ]));
  }

  Widget _history(BuildContext context, BiometricImportCubit cubit,
      BiometricImportState state) {
    final date = DateFormat('dd/MM/yyyy HH:mm');
    return AppSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Expanded(
              child: Text('Historial',
                  style: Theme.of(context).textTheme.titleMedium)),
          IconButton(
              onPressed: state.historyLoading ? null : cubit.refreshHistory,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar historial'),
        ],
      ),
      const SizedBox(height: 12),
      if (state.history.isEmpty && !state.historyLoading)
        const Text('Todavía no hay importaciones ni sincronizaciones.')
      else
        for (final batch in state.history)
          ListTile(
            key: ValueKey('batch-${batch.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
                batch.isFromFile ? Icons.description_outlined : Icons.sync),
            title: Text(
                '${batch.originLabel} · ${batch.createdAt == null ? '—' : date.format(batch.createdAt!.toLocal())}'),
            subtitle: Text(
                '${batch.sourceFileName == null ? '' : '${batch.sourceFileName} · '}'
                'Recibidos ${batch.receivedRecords} · Nuevos ${batch.newRecords} · '
                'Duplicados ${batch.duplicateRecords} · Errores ${batch.errorRecords}'),
            trailing: Text(batch.statusLabel),
            onTap: () => cubit.openBatch(batch),
          ),
      if (state.historyTotal > BiometricImportState.historyPageSize)
        Wrap(children: [
          TextButton(
            onPressed: state.historyLoading || state.historyPage == 1
                ? null
                : () => cubit.refreshHistory(page: state.historyPage - 1),
            child: const Text('Historial anterior'),
          ),
          TextButton(
            onPressed: state.historyLoading ||
                    state.historyPage * BiometricImportState.historyPageSize >=
                        state.historyTotal
                ? null
                : () => cubit.refreshHistory(page: state.historyPage + 1),
            child: const Text('Historial siguiente'),
          ),
        ]),
    ]));
  }

  Widget _batchDetail(BuildContext context, BiometricImportCubit cubit,
      BiometricImportState state) {
    final batch = state.selectedBatch!;
    return AppSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Expanded(
            child: Text('Detalle del lote · ${batch.originLabel}',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(
              onPressed: cubit.closeBatch,
              icon: const Icon(Icons.close),
              tooltip: 'Cerrar'),
        ],
      ),
      const SizedBox(height: 8),
      if (batch.sourceFileName != null) Text(batch.sourceFileName!),
      if (batch.requestedStartDate != null && batch.requestedEndDate != null)
        Text('${DateFormat('dd/MM/yyyy').format(batch.requestedStartDate!)}'
            ' – ${DateFormat('dd/MM/yyyy').format(batch.requestedEndDate!)}'),
      if (batch.executedBy != null) Text('Ejecutado por ${batch.executedBy}'),
      if (batch.errorMessage != null) Text(batch.errorMessage!),
      const SizedBox(height: 12),
      if (state.batchLoading)
        const LinearProgressIndicator()
      else
        BiometricRawRecords(records: state.batchRecords),
      if (state.batchOffset > 0 || state.batchHasMore)
        Wrap(children: [
          TextButton(
            onPressed: state.batchLoading || state.batchOffset == 0
                ? null
                : () => cubit.openBatch(batch,
                    offset:
                        state.batchOffset - BiometricImportState.rawPageSize),
            child: const Text('Página anterior'),
          ),
          TextButton(
            onPressed: state.batchLoading || !state.batchHasMore
                ? null
                : () => cubit.openBatch(batch,
                    offset:
                        state.batchOffset + BiometricImportState.rawPageSize),
            child: const Text('Página siguiente'),
          ),
        ]),
    ]));
  }

  Future<void> _synchronize(BuildContext context) async {
    final cubit = context.read<BiometricImportCubit>();
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1901),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day)),
    );
    if (range == null || !context.mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sincronizar biométrico'),
        content: const Text(
            'Se consultará el rango seleccionado y se guardarán las marcaciones nuevas.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sincronizar')),
        ],
      ),
    );
    if (accepted == true && context.mounted) {
      await cubit.synchronize(range.start, range.end);
    }
  }
}
