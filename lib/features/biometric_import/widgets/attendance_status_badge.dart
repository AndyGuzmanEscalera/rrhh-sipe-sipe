import 'package:flutter/material.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';

class AttendanceStatusBadge extends StatelessWidget {
  const AttendanceStatusBadge({required this.status, super.key});
  final AttendanceStatus status;
  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      AttendanceStatus.normal => (
          'SIN NOVEDAD',
          UiColors.success,
          UiColors.successSoft
        ),
      AttendanceStatus.observation => (
          'OBSERVACIÓN',
          UiColors.warning,
          UiColors.warningSoft
        ),
      AttendanceStatus.anomaly => (
          'ANOMALÍA',
          UiColors.danger,
          const Color(0xFFFEE2E2)
        ),
    };
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)));
  }
}
