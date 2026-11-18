part of 'biometric_import_cubit.dart';

class BiometricImportState extends Equatable implements StatusState {
  const BiometricImportState(
      {this.generalStatus = GeneralStatus.initial,
      this.filename,
      this.size,
      this.selectedAt,
      this.result,
      this.mapping = const BiometricColumnMapping(),
      this.deviceId = '',
      this.devices = const [],
      this.importing = false,
      this.syncing = false,
      this.history = const [],
      this.historyLoading = false,
      this.historyPage = 1,
      this.historyTotal = 0,
      this.lastImport,
      this.selectedBatch,
      this.batchRecords = const [],
      this.batchOffset = 0,
      this.batchHasMore = false,
      this.batchLoading = false,
      this.page = 1,
      this.message = ''});
  @override
  final GeneralStatus generalStatus;
  @override
  DialogMessage get dialogMessage => DialogMessage(message: message);
  final String? filename;
  final int? size;
  final DateTime? selectedAt;
  final BiometricParseResult? result;
  final BiometricColumnMapping mapping;
  final String deviceId;
  final List<String> devices;
  final bool importing;
  final bool syncing;
  final List<BiometricImportBatch> history;
  final bool historyLoading;
  final int historyPage;
  final int historyTotal;
  final BiometricImportBatch? lastImport;
  final BiometricImportBatch? selectedBatch;
  final List<BiometricRawRecord> batchRecords;
  final int batchOffset;
  final bool batchHasMore;
  final bool batchLoading;
  final int page;
  final String message;
  static const pageSize = 20;
  static const rawPageSize = 50;
  static const historyPageSize = 20;
  int get totalPages =>
      ((result?.records.length ?? 0) / pageSize).ceil().clamp(1, 1 << 30);
  bool get readyToImport =>
      generalStatus != GeneralStatus.loading &&
      result != null &&
      result!.totalLines > result!.ignoredLines &&
      deviceId.isNotEmpty &&
      !importing;
  List<BiometricRecord> get pageRecords {
    final records = result?.records ?? const <BiometricRecord>[];
    final start = (page - 1) * pageSize;
    return records.sublist(start.clamp(0, records.length),
        (start + pageSize).clamp(0, records.length));
  }

  BiometricImportState copyWith(
          {GeneralStatus? generalStatus,
          String? filename,
          int? size,
          DateTime? selectedAt,
          bool clearFile = false,
          BiometricParseResult? result,
          bool clearResult = false,
          BiometricColumnMapping? mapping,
          String? deviceId,
          List<String>? devices,
          bool? importing,
          bool? syncing,
          List<BiometricImportBatch>? history,
          bool? historyLoading,
          int? historyPage,
          int? historyTotal,
          BiometricImportBatch? lastImport,
          bool clearLastImport = false,
          BiometricImportBatch? selectedBatch,
          bool clearBatch = false,
          List<BiometricRawRecord>? batchRecords,
          int? batchOffset,
          bool? batchHasMore,
          bool? batchLoading,
          int? page,
          String? message}) =>
      BiometricImportState(
          generalStatus: generalStatus ?? this.generalStatus,
          filename: clearFile ? null : (filename ?? this.filename),
          size: clearFile ? null : (size ?? this.size),
          selectedAt: clearFile ? null : (selectedAt ?? this.selectedAt),
          result: clearResult ? null : (result ?? this.result),
          mapping: mapping ?? this.mapping,
          deviceId: deviceId ?? this.deviceId,
          devices: devices ?? this.devices,
          importing: importing ?? this.importing,
          syncing: syncing ?? this.syncing,
          history: history ?? this.history,
          historyLoading: historyLoading ?? this.historyLoading,
          historyPage: historyPage ?? this.historyPage,
          historyTotal: historyTotal ?? this.historyTotal,
          lastImport: clearLastImport ? null : (lastImport ?? this.lastImport),
          selectedBatch:
              clearBatch ? null : (selectedBatch ?? this.selectedBatch),
          batchRecords:
              clearBatch ? const [] : (batchRecords ?? this.batchRecords),
          batchOffset: clearBatch ? 0 : (batchOffset ?? this.batchOffset),
          batchHasMore: !clearBatch && (batchHasMore ?? this.batchHasMore),
          batchLoading: !clearBatch && (batchLoading ?? this.batchLoading),
          page: page ?? this.page,
          message: message ?? this.message);
  @override
  List<Object?> get props => [
        generalStatus,
        filename,
        size,
        selectedAt,
        result,
        mapping,
        deviceId,
        devices,
        importing,
        syncing,
        history,
        historyLoading,
        historyPage,
        historyTotal,
        lastImport,
        selectedBatch,
        batchRecords,
        batchOffset,
        batchHasMore,
        batchLoading,
        page,
        message,
      ];
}
