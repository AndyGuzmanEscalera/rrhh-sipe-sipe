import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';

const attendanceMonths = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre'
];
String attendanceTime(DateTime? value, {bool seconds = false}) => value == null
    ? '—'
    : DateFormat(seconds ? 'HH:mm:ss' : 'HH:mm').format(value);
String attendanceMinutes(double? value) =>
    value == null ? '—' : NumberFormat('0.##').format(value);
String attendanceDate(DateTime value) => DateFormat('dd/MM/yyyy').format(value);
String attendancePeriod(AttendancePeriod? period, bool confirmed) => period ==
        null
    ? 'Período pendiente'
    : '${attendanceDate(period.start)} al ${attendanceDate(period.endExclusive.subtract(const Duration(days: 1)))}${confirmed ? '' : ' · provisional'}';
String attendanceStatusLabel(String status) =>
    const {
      'NORMAL': 'Normal',
      'OBSERVATION': 'Observación',
      'ANOMALY': 'Anomalía',
      'NO_DATA': 'Sin datos'
    }[status] ??
    'Sin clasificar';
Color attendanceStatusColor(String status) => switch (status) {
      'NORMAL' => UiColors.success,
      'OBSERVATION' => UiColors.warning,
      'ANOMALY' => UiColors.danger,
      _ => UiColors.textMuted,
    };
String attendanceDependency(String key) =>
    const {
      'confirmed_contract_period_policy':
          'Política de corte contractual pendiente',
      'confirmed_contract_period_semantics':
          'Semántica del período contractual sin confirmar',
      'employee_contract_assignment':
          'Contratos y asignaciones de funcionarios pendientes',
      'employee_shift_source':
          'Turno histórico o calendario laboral sin configurar',
      'association_windows': 'Ventanas de asociación de marcaciones pendientes',
      'attendance_parameters': 'Parámetros de asistencia sin configurar',
      'biometric_coverage':
          'Cobertura de marcaciones incompleta o todavía abierta',
      'confirmed_work_calendar':
          'Calendario laboral sin confirmar para estas fechas',
      'overnight_shift_policy': 'Reglas de turnos nocturnos pendientes',
      'biometric_employee_link':
          'Vínculo explícito entre biométrico y funcionario pendiente',
      'exit_tolerance_semantics':
          'Aplicación de tolerancia de salida pendiente',
      'absence_policy': 'Política de ausencias pendiente',
      'overtime_policy': 'Política de horas extra pendiente',
    }[key] ??
    'Configuración pendiente: ${key.replaceAll('_', ' ')}';
String attendanceIncidentLabel(String key) =>
    const {
      'LATE': 'Atraso',
      'LATE_RETURN': 'Retorno tardío',
      'EARLY_EXIT': 'Salida anticipada',
      'MISSING_MARK': 'Marcación faltante',
      'EXTRA_MARK': 'Marcación adicional',
      'POSSIBLE_DUPLICATE': 'Posible duplicado',
      'INTERMEDIATE_EXIT': 'Posible salida intermedia',
      'MINIMUM_BREAK_VIOLATION': 'Intervalo menor al mínimo',
      'INCONSISTENT_SEQUENCE': 'Secuencia por revisar',
    }[key] ??
    key;
