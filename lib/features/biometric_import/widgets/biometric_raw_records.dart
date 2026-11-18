import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';

/// Marcaciones en bruto de un lote.
///
/// No etiqueta entrada ni salida: `status` y `punch` se muestran como los
/// códigos crudos que registró el dispositivo o el archivo.
class BiometricRawRecords extends StatelessWidget {
  const BiometricRawRecords({required this.records, super.key});
  final List<BiometricRawRecord> records;

  @override
  Widget build(BuildContext context) => records.isEmpty
      ? const Text('Este lote no incorporó marcaciones nuevas.')
      : SizedBox(
          height: 520,
          child: AppDataGrid<BiometricRawRecord>(
            items: records,
            shrinkWrap: false,
            allowSorting: false,
            emptyMessage: 'El lote no tiene marcaciones.',
            columns: [
              AppDataGridColumn(
                  key: 'user',
                  label: 'Usuario biométrico',
                  value: (r) => r.userId,
                  mobilePrimary: true,
                  width: 160),
              AppDataGridColumn(
                  key: 'timestamp',
                  label: 'Fecha/hora',
                  value: (r) =>
                      DateFormat('dd/MM/yyyy HH:mm:ss').format(r.timestamp),
                  width: 170),
              AppDataGridColumn(
                  key: 'status',
                  label: 'Status',
                  value: (r) => r.status,
                  width: 90),
              AppDataGridColumn(
                  key: 'punch',
                  label: 'Punch',
                  value: (r) => r.punch,
                  width: 90),
              AppDataGridColumn(
                  key: 'origin',
                  label: 'Origen',
                  value: (r) => r.originLabel,
                  width: 120),
            ],
          ));
}
