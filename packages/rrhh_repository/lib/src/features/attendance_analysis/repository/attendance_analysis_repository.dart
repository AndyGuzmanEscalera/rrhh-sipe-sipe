import 'package:failures/failures.dart';
import '../../biometric_import/entities/biometric_record.dart';
import '../../organization/entities/employee_admin.dart';
import '../../organization/repository/employees_admin_repository.dart';
import '../entities/attendance_analysis.dart';
import '../services/attendance_analyzer.dart';

class AttendanceAnalysisRepository {
  AttendanceAnalysisRepository({
    EmployeesAdminRepository? employeesRepository,
    AttendanceAnalyzer analyzer = const AttendanceAnalyzer(),
  })  : _employeesRepository = employeesRepository,
        _analyzer = analyzer;
  final EmployeesAdminRepository? _employeesRepository;
  final AttendanceAnalyzer _analyzer;

  Future<ImportAttendanceAnalysis> analyze(
      List<BiometricRecord> records, AttendanceConfiguration config) async {
    final employees = <EmployeeAdmin>[];
    String? warning;
    if (records.isNotEmpty) {
      if (_employeesRepository == null) {
        warning =
            'Catálogo de funcionarios no disponible; los identificadores siguen visibles.';
      } else {
        // Incluye inactivos: un archivo histórico puede contener sus marcaciones.
        var page = 1;
        while (true) {
          final result =
              await _employeesRepository.list(page: page, pageSize: 100);
          if (result case Err(:final failure)) {
            warning = FailureGeneric.message(
                failure: failure,
                messageResult:
                    'No se pudo consultar el catálogo compartido de funcionarios.');
            employees.clear();
            break;
          }
          final data = result.valueOrNull()!;
          employees.addAll(data.items);
          if (page >= data.totalPages) break;
          page++;
        }
      }
    }
    return _analyzer.analyze(
        records: records,
        configuration: config,
        employees: employees,
        lookupWarning: warning);
  }
}
