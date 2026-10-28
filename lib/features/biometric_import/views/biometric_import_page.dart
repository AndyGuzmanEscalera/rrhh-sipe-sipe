import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/platform/format_file_size.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';
import 'package:rrhh_sipe_sipe/features/home/widgets/home_components.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/app_surface.dart';
import '../cubit/biometric_import_cubit.dart';
import '../widgets/biometric_preview.dart';
import '../widgets/biometric_errors_dialog.dart';
import '../widgets/attendance_configuration_dialog.dart';
import '../widgets/attendance_analysis_view.dart';

class BiometricImportPage extends StatelessWidget {
  const BiometricImportPage({super.key});

  @override
  Widget build(BuildContext context) => const BiometricImportView();
}

class BiometricImportView extends StatelessWidget {
  const BiometricImportView({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BiometricImportCubit, BiometricImportState>(
          builder: (context, state) {
        final cubit = context.read<BiometricImportCubit>();
        final busy = state.generalStatus == GeneralStatus.loading;
        final result = state.result;
        final warnings = result != null &&
            (result.errors.isNotEmpty || result.records.isEmpty);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Importar Biométrico',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text(
              'Selecciona un archivo .dat o .txt para validar y previsualizar sus marcaciones. No se guardarán automáticamente.'),
          const SizedBox(height: 24),
          AppSurface(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                ElevatedButton.icon(
                    onPressed:
                        busy || state.analyzing ? null : cubit.selectFile,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Text(state.filename == null
                        ? 'Seleccionar archivo'
                        : 'Seleccionar otro archivo')),
                const SizedBox(height: 16),
                if (state.filename != null) ...[
                  SelectableText(state.filename!,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                      'Tamaño: ${state.size == 0 ? '0 B' : formatFileSize(state.size)}'),
                  if (state.selectedAt != null)
                    Text(
                        'Seleccionado: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(state.selectedAt!)}'),
                  if (result != null && !busy)
                    Text('Registros encontrados: ${result.foundRecords}'),
                ] else if (!busy && state.generalStatus != GeneralStatus.error)
                  const Text(
                      'Sin archivo seleccionado. Se esperan 6 campos separados por tabulaciones.'),
                if (busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(state.message)
                ],
                if (!busy && state.message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                      state.generalStatus == GeneralStatus.error
                          ? 'Error de lectura: ${state.message}'
                          : state.message,
                      style: TextStyle(
                          color: state.generalStatus == GeneralStatus.error
                              ? UiColors.danger
                              : warnings
                                  ? UiColors.warning
                                  : UiColors.success)),
                ],
              ])),
          if (result != null && !busy) ...[
            const SizedBox(height: 24),
            _Summary(result: result),
            const SizedBox(height: 16),
            Text(
                '${result.ignoredLines} líneas vacías ignoradas. Los duplicados se conservan; los identificadores únicos se cuentan entre registros válidos.'),
            const SizedBox(height: 24),
            Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (result.errors.isNotEmpty)
                    OutlinedButton.icon(
                        onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                BiometricErrorsDialog(errors: result.errors)),
                        icon: const Icon(Icons.error_outline),
                        label: const Text('Ver errores')),
                  Text(state.readyToImport
                      ? 'Listo para importar: ${result.records.length} registros válidos.'
                      : 'No hay registros válidos para importar.'),
                ]),
            const SizedBox(height: 24),
            Wrap(spacing: 12, runSpacing: 12, children: [
              OutlinedButton.icon(
                  onPressed: state.analyzing
                      ? null
                      : () async {
                          final config =
                              await showDialog<AttendanceConfiguration>(
                                  context: context,
                                  builder: (_) => AttendanceConfigurationDialog(
                                      configuration: cubit.configuration));
                          if (config != null && context.mounted) {
                            await cubit.reanalyze(configuration: config);
                          }
                        },
                  icon: const Icon(Icons.tune),
                  label: const Text('Configurar análisis')),
              TextButton(
                  onPressed: state.analyzing ? null : cubit.reanalyze,
                  child: const Text('Reanalizar y actualizar funcionarios')),
            ]),
            const SizedBox(height: 12),
            if (state.analyzing) const LinearProgressIndicator(),
            if (state.analysisMessage.isNotEmpty) Text(state.analysisMessage),
            if (state.analysis != null && !state.analyzing)
              AttendanceAnalysisView(analysis: state.analysis!),
            const SizedBox(height: 24),
            Text('Previsualización',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            BiometricPreview(state: state, onPageChanged: cubit.changePage),
            const SizedBox(height: 24),
            const Tooltip(
                message: 'El guardado en el servidor aún no está disponible.',
                child: ElevatedButton(
                    onPressed: null, child: Text('Importar marcaciones'))),
            const SizedBox(height: 12),
            const Text(
                'La previsualización está disponible. El guardado definitivo se habilitará cuando exista el servicio de importación.'),
          ],
        ]);
      });
}

class _Summary extends StatelessWidget {
  const _Summary({required this.result});
  final BiometricParseResult result;
  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm:ss');
    final metrics = [
      ('Total de líneas', '${result.totalLines}'),
      ('Registros válidos', '${result.records.length}'),
      ('Registros inválidos', '${result.errors.length}'),
      ('Identificadores únicos', '${result.uniqueIdentifiers}'),
      (
        'Fecha mínima',
        result.minTimestamp == null
            ? 'Sin datos'
            : date.format(result.minTimestamp!)
      ),
      (
        'Fecha máxima',
        result.maxTimestamp == null
            ? 'Sin datos'
            : date.format(result.maxTimestamp!)
      ),
    ];
    return LayoutBuilder(builder: (context, size) {
      final columns = size.maxWidth >= 900
          ? 3
          : size.maxWidth >= 550
              ? 2
              : 1;
      final width = (size.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: metrics
              .map((metric) => SizedBox(
                  width: width,
                  child: HomeInfoCard(
                      icon: Icons.analytics_outlined,
                      label: 'RESUMEN',
                      value: metric.$2,
                      detail: metric.$1,
                      color: UiColors.primary,
                      background: UiColors.primarySoft)))
              .toList());
    });
  }
}
