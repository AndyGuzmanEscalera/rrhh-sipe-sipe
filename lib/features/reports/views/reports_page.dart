import 'package:flutter/material.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/feature_placeholder.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholder(
        title: 'Reportes',
        description: 'Espacio para los futuros reportes de Recursos Humanos.',
        icon: Icons.bar_chart_rounded,
        sections: ['Período', 'Tipo de reporte', 'Resultados'],
      );
}
