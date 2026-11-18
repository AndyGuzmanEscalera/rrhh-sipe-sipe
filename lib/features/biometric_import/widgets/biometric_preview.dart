import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import '../cubit/biometric_import_cubit.dart';

class BiometricPreview extends StatelessWidget {
  const BiometricPreview(
      {required this.state, required this.onPageChanged, super.key});
  final BiometricImportState state;
  final ValueChanged<int> onPageChanged;
  @override
  Widget build(BuildContext context) => state.pageRecords.isEmpty
      ? const Text('No se encontraron marcaciones válidas.')
      : SizedBox(
          height: 600,
          child: AppDataGrid<BiometricRecord>(
              items: state.pageRecords,
              shrinkWrap: false,
              allowSorting: false,
              currentPage: state.page,
              pageSize: BiometricImportState.pageSize,
              totalItems: state.result?.records.length ?? 0,
              totalPages: state.totalPages,
              onPageChanged: onPageChanged,
              emptyMessage: 'No se encontraron marcaciones válidas.',
              columns: [
                AppDataGridColumn(
                    key: 'line',
                    label: 'Línea',
                    value: (r) => r.lineNumber,
                    width: 75),
                AppDataGridColumn(
                    key: 'employee',
                    label: 'Identificador',
                    value: (r) => r.employeeIdentifier,
                    mobilePrimary: true,
                    width: 150),
                AppDataGridColumn(
                    key: 'date',
                    label: 'Fecha',
                    value: (r) => DateFormat('dd/MM/yyyy').format(r.timestamp),
                    width: 120),
                AppDataGridColumn(
                    key: 'time',
                    label: 'Hora',
                    value: (r) => DateFormat('HH:mm:ss').format(r.timestamp),
                    width: 100),
                AppDataGridColumn(
                    key: 'field3',
                    label: 'Campo 3',
                    value: (r) => r.field3,
                    width: 100),
                AppDataGridColumn(
                    key: 'field4',
                    label: 'Campo 4',
                    value: (r) => r.field4,
                    width: 100),
                AppDataGridColumn(
                    key: 'field5',
                    label: 'Campo 5',
                    value: (r) => r.field5,
                    width: 100),
                AppDataGridColumn(
                    key: 'field6',
                    label: 'Campo 6',
                    value: (r) => r.field6,
                    width: 100),
              ]));
}
