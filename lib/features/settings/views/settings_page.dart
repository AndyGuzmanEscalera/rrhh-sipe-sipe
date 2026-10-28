import 'package:flutter/material.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/feature_placeholder.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholder(
        title: 'Configuración',
        description: 'Preferencias generales del Sistema de Recursos Humanos.',
        icon: Icons.settings_outlined,
        sections: ['Institución', 'Preferencias', 'Opciones del sistema'],
      );
}
