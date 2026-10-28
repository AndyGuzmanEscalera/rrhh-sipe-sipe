import 'package:flutter/material.dart';
import 'package:rrhh_sipe_sipe/core/auth/permission_guard.dart';
import 'package:rrhh_sipe_sipe/core/auth/permissions.dart';
import 'attendance_view.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) => const PermissionGuard(
      permission: Permissions.attendanceRead, child: AttendanceView());
}
