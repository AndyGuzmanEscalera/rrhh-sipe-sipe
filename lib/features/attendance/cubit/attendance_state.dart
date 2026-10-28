part of 'attendance_cubit.dart';

class AttendanceState extends Equatable implements StatusState {
  const AttendanceState(
      {required this.year,
      required this.month,
      this.contractId,
      this.contracts,
      this.parameters,
      this.device,
      this.sync,
      this.generation,
      this.loading = false,
      this.saving = false,
      this.generating = false,
      this.startingSync = false,
      this.checkingDevice = false,
      this.syncLoaded = false,
      this.dirty = false,
      this.needsRefresh = false,
      this.contractError = '',
      this.parameterError = '',
      this.deviceError = '',
      this.syncError = '',
      this.resultError = '',
      this.parameterNotice = '',
      this.query = '',
      this.page = 1});
  final int year, month, page;
  final String? contractId;
  final AttendanceContracts? contracts;
  final AttendanceParameters? parameters;
  final BiometricDeviceStatus? device;
  final BiometricSync? sync;
  final AttendanceGeneration? generation;
  final bool loading,
      saving,
      generating,
      startingSync,
      checkingDevice,
      dirty,
      needsRefresh;
  final bool syncLoaded;
  final String contractError,
      parameterError,
      deviceError,
      syncError,
      resultError,
      parameterNotice,
      query;
  AttendanceFilter? get filter => contractId == null
      ? null
      : AttendanceFilter(contractId: contractId!, year: year, month: month);
  List<AttendanceEmployeeResult> get filtered {
    final needle = query.trim().toLowerCase();
    return (generation?.employees ?? const <AttendanceEmployeeResult>[])
        .where((row) =>
            '${row.employee.name} ${row.employee.document ?? ''} ${row.employee.unit ?? ''}'
                .toLowerCase()
                .contains(needle))
        .toList(growable: false);
  }

  @override
  GeneralStatus get generalStatus => generating || loading
      ? GeneralStatus.loading
      : resultError.isNotEmpty
          ? GeneralStatus.error
          : GeneralStatus.success;
  @override
  DialogMessage get dialogMessage => const DialogMessage.empty();

  AttendanceState copyWith(
          {int? year,
          int? month,
          int? page,
          String? contractId,
          AttendanceContracts? contracts,
          AttendanceParameters? parameters,
          BiometricDeviceStatus? device,
          BiometricSync? sync,
          AttendanceGeneration? generation,
          bool clearGeneration = false,
          bool clearContract = false,
          bool clearSync = false,
          bool clearDevice = false,
          bool? loading,
          bool? saving,
          bool? generating,
          bool? startingSync,
          bool? checkingDevice,
          bool? syncLoaded,
          bool? dirty,
          bool? needsRefresh,
          String? contractError,
          String? parameterError,
          String? deviceError,
          String? syncError,
          String? resultError,
          String? parameterNotice,
          String? query}) =>
      AttendanceState(
          year: year ?? this.year,
          month: month ?? this.month,
          contractId: clearContract ? null : contractId ?? this.contractId,
          page: page ?? this.page,
          contracts: contracts ?? this.contracts,
          parameters: parameters ?? this.parameters,
          device: clearDevice ? null : device ?? this.device,
          sync: clearSync ? null : sync ?? this.sync,
          generation: clearGeneration ? null : generation ?? this.generation,
          loading: loading ?? this.loading,
          saving: saving ?? this.saving,
          generating: generating ?? this.generating,
          startingSync: startingSync ?? this.startingSync,
          checkingDevice: checkingDevice ?? this.checkingDevice,
          syncLoaded: syncLoaded ?? this.syncLoaded,
          dirty: dirty ?? this.dirty,
          needsRefresh: needsRefresh ?? this.needsRefresh,
          contractError: contractError ?? this.contractError,
          parameterError: parameterError ?? this.parameterError,
          deviceError: deviceError ?? this.deviceError,
          syncError: syncError ?? this.syncError,
          resultError: resultError ?? this.resultError,
          parameterNotice: parameterNotice ?? this.parameterNotice,
          query: query ?? this.query);
  @override
  List<Object?> get props => [
        year,
        month,
        page,
        contractId,
        contracts,
        parameters,
        device,
        sync,
        generation,
        loading,
        saving,
        generating,
        startingSync,
        checkingDevice,
        syncLoaded,
        dirty,
        needsRefresh,
        contractError,
        parameterError,
        deviceError,
        syncError,
        resultError,
        parameterNotice,
        query
      ];
}
