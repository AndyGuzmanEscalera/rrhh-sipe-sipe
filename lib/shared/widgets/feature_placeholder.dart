import 'package:flutter/material.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';
import 'package:rrhh_sipe_sipe/shared/widgets/app_surface.dart';

/// Estructura visual; no ejecuta operaciones ni consultas al backend.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder(
      {required this.title,
      required this.description,
      required this.icon,
      required this.sections,
      super.key});
  final String title;
  final String description;
  final IconData icon;
  final List<String> sections;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(description),
        const SizedBox(height: 24),
        AppSurface(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: UiColors.primary, size: 44),
          const SizedBox(height: 20),
          Text('Próximamente', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const Text(
              'Pantalla base. Las funciones estarán disponibles en una etapa posterior.'),
          const SizedBox(height: 24),
          Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  sections.map((label) => Chip(label: Text(label))).toList()),
        ])),
      ]);
}
