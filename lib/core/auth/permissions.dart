import 'package:rrhh_repository/rrhh_repository.dart';

class Permissions {
  const Permissions._();

  static const attendanceRead = 'rrhh.read';
  static const attendanceManage = 'rrhh.manage';

  static const organizationalUnitsRead =
      'master_data.organizational_units.read';
  static const organizationalUnitsManage =
      'master_data.organizational_units.manage';
  static const positionsRead = 'master_data.positions.read';
  static const positionsManage = 'master_data.positions.manage';
  static const employeesRead = 'master_data.employees.read';
  static const employeesManage = 'master_data.employees.manage';
  static const usersRead = 'master_data.users.read';
  static const usersManage = 'master_data.users.manage';
  static const rolesAssign = 'master_data.roles.assign';
  static const systemSettingsRead = 'system.settings.read';
  static const systemSettingsManage = 'system.settings.manage';
}

bool hasPermission(UserSession? session, String code) {
  if (session == null) return false;
  return session.permissions.contains(code);
}
