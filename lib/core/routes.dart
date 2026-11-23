/// Rutas del Sistema de Recursos Humanos.
class Routes {
  Routes._();
  static const initial = '/';
  static const signIn = '/login';
  static const home = '/home';
  static const biometricImport = '/importacion';
  static const attendance = '/asistencia';
  static const employees = '/funcionarios';
  static const reports = '/reportes';
  static const settings = '/configuracion';
  static String attendanceEmployee(String id) =>
      '$attendance/${Uri.encodeComponent(id)}';

  static bool isWorkspacePath(String? path) =>
      workspacePaths.contains(path) ||
      (path != null && RegExp(r'^/asistencia/[a-zA-Z0-9-]+$').hasMatch(path));
  static const workspacePaths = {
    home,
    biometricImport,
    attendance,
    employees,
    reports,
    settings,
  };
}
