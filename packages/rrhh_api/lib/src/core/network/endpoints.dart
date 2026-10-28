/// All FastAPI paths used by the app live here.
///
/// Backend endpoints (see backend/app/modules/auth/router.py):
class Endpoints {
  const Endpoints._();

  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  static const attendanceParameters = '/rrhh/attendance/parameters';
  static const attendanceContracts = '/rrhh/attendance/contracts';
  static const attendanceGenerate = '/rrhh/attendance/generate';
  static String attendanceReport(String id) =>
      '/rrhh/attendance/employees/${Uri.encodeComponent(id)}/report';
  static const biometricStatus = '/rrhh/biometric/status';
  static const biometricSync = '/rrhh/biometric/sync';
  static const biometricLatestSync = '/rrhh/biometric/syncs/latest';
  static String biometricSyncStatus(String id) =>
      '/rrhh/biometric/syncs/${Uri.encodeComponent(id)}';

  static const adminEmployees = '/admin/employees';
  static String adminEmployee(String id) => '$adminEmployees/$id';
  static String adminEmployeeActive(String id) => '$adminEmployees/$id/active';
  static const adminOrganizationalUnits = '/admin/organizational-units';
  static String adminOrganizationalUnit(String id) =>
      '$adminOrganizationalUnits/$id';
  static String adminOrganizationalUnitActive(String id) =>
      '$adminOrganizationalUnits/$id/active';
  static const adminPositions = '/admin/positions';
  static String adminPosition(String id) => '$adminPositions/$id';
  static String adminPositionActive(String id) => '$adminPositions/$id/active';
}
