import 'package:get_it/get_it.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import '../features/app/cubit/app_session_cubit.dart';
import '../features/home/side_menu/cubit/side_menu_cubit.dart';
import '../features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import '../features/administration/basic_data/employees/upsert_employees/cubit/upsert_employees_cubit.dart';
import '../features/authentication/sign_in/cubit/sign_in_cubit.dart';
import '../features/splash/cubit/splash_cubit.dart';
import '../features/biometric_import/cubit/biometric_import_cubit.dart';
import '../features/biometric_import/data/biometric_file_picker.dart';
import '../features/attendance/cubit/attendance_cubit.dart';
import '../features/attendance/cubit/attendance_report_cubit.dart';

final getIt = GetIt.instance;

void registerCubits() {
  getIt.registerFactory<AttendanceCubit>(
      () => AttendanceCubit(getIt<AttendanceRepository>()));
  getIt.registerFactory<AttendanceReportCubit>(
      () => AttendanceReportCubit(getIt<AttendanceRepository>()));
  getIt.registerFactory<EmployeesCubit>(
      () => EmployeesCubit(getIt<EmployeesAdminRepository>()));
  getIt.registerFactory<UpsertEmployeesCubit>(() => UpsertEmployeesCubit(
      employeesRepository: getIt<EmployeesAdminRepository>(),
      unitsRepository: getIt<OrganizationalUnitsAdminRepository>(),
      positionsRepository: getIt<PositionsAdminRepository>()));
  getIt.registerFactory<SideMenuCubit>(() => SideMenuCubit());
  getIt.registerLazySingleton<BiometricFilePicker>(() => BiometricFilePicker());
  getIt.registerFactory<BiometricImportCubit>(() => BiometricImportCubit(
      repository: getIt<BiometricImportRepository>(),
      analysisRepository: getIt<AttendanceAnalysisRepository>(),
      picker: getIt<BiometricFilePicker>()));
  getIt.registerLazySingleton<AppSessionCubit>(
    () => AppSessionCubit(authRepository: getIt<AuthenticationRepository>()),
  );
  getIt.registerFactory<SplashCubit>(
    () => SplashCubit(authRepository: getIt<AuthenticationRepository>()),
  );
  getIt.registerFactory<SignInCubit>(
    () => SignInCubit(authRepository: getIt<AuthenticationRepository>()),
  );
}
