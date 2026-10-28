import 'package:flutter/material.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';

class BiometricErrorsDialog extends StatelessWidget {
  const BiometricErrorsDialog({required this.errors, super.key});
  final List<BiometricLineError> errors;
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text('Registros inválidos (${errors.length})'),
          content: SizedBox(
              width: 760,
              height: MediaQuery.sizeOf(context).height * .6,
              child: ListView.separated(
                  itemCount: errors.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, index) {
                    final error = errors[index];
                    return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Línea ${error.lineNumber}: ${error.reason}',
                                  style: const TextStyle(
                                      color: UiColors.danger,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              SelectableText(error.rawLine,
                                  style: const TextStyle(
                                      fontFamily: 'monospace', fontSize: 12)),
                            ]));
                  })),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'))
          ]);
}
