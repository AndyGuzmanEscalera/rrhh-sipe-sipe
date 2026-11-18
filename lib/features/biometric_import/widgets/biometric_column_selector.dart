import 'package:flutter/material.dart';
import 'package:rrhh_repository/rrhh_repository.dart';

/// Selección de las columnas del archivo que aportan los códigos crudos.
///
/// El módulo no deduce el significado de ninguna columna: el operador declara
/// cuál contiene status, cuál punch y cuál uid. Si un campo no es numérico, la
/// marcación se cuenta como error y el lote continúa.
class BiometricColumnSelector extends StatelessWidget {
  const BiometricColumnSelector(
      {required this.mapping, required this.onChanged, super.key});
  final BiometricColumnMapping mapping;
  final ValueChanged<BiometricColumnMapping> onChanged;

  static const _labels = {
    BiometricColumn.none: 'Ninguno',
    BiometricColumn.field3: 'Campo 3',
    BiometricColumn.field4: 'Campo 4',
    BiometricColumn.field5: 'Campo 5',
    BiometricColumn.field6: 'Campo 6',
  };

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _dropdown('Status', mapping.status,
              (value) => onChanged(mapping.copyWith(status: value))),
          _dropdown('Punch', mapping.punch,
              (value) => onChanged(mapping.copyWith(punch: value))),
          _dropdown('Uid', mapping.uid,
              (value) => onChanged(mapping.copyWith(uid: value))),
        ],
      );

  Widget _dropdown(String label, BiometricColumn value,
          ValueChanged<BiometricColumn> onChange) =>
      SizedBox(
        width: 190,
        child: DropdownButtonFormField<BiometricColumn>(
          value: value,
          decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: const OutlineInputBorder()),
          items: BiometricColumn.values
              .map((option) => DropdownMenuItem<BiometricColumn>(
                  value: option, child: Text(_labels[option] ?? option.name)))
              .toList(),
          onChanged: (option) {
            if (option != null) onChange(option);
          },
        ),
      );
}
