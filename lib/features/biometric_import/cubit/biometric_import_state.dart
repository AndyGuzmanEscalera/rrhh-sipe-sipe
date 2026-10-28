part of 'biometric_import_cubit.dart';

class BiometricImportState extends Equatable implements StatusState {
  const BiometricImportState(
      {this.generalStatus = GeneralStatus.initial,
      this.filename,
      this.size,
      this.selectedAt,
      this.result,
      this.analysis,
      this.analyzing = false,
      this.analysisMessage = '',
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
  final ImportAttendanceAnalysis? analysis;
  final bool analyzing;
  final String analysisMessage;
  final int page;
  final String message;
  static const pageSize = 20;
  int get totalPages =>
      ((result?.records.length ?? 0) / pageSize).ceil().clamp(1, 1 << 30);
  bool get readyToImport =>
      generalStatus == GeneralStatus.success &&
      (result?.records.isNotEmpty ?? false);
  List<BiometricRecord> get pageRecords {
    final records = result?.records ?? const <BiometricRecord>[];
    final start = (page - 1) * pageSize;
    return records.sublist(start.clamp(0, records.length),
        (start + pageSize).clamp(0, records.length));
  }

  BiometricImportState copyWith(
          {GeneralStatus? generalStatus,
          BiometricParseResult? result,
          ImportAttendanceAnalysis? analysis,
          bool? analyzing,
          String? analysisMessage,
          int? page,
          String? message}) =>
      BiometricImportState(
          generalStatus: generalStatus ?? this.generalStatus,
          filename: filename,
          size: size,
          selectedAt: selectedAt,
          result: result ?? this.result,
          analysis: analysis ?? this.analysis,
          analyzing: analyzing ?? this.analyzing,
          analysisMessage: analysisMessage ?? this.analysisMessage,
          page: page ?? this.page,
          message: message ?? this.message);
  @override
  List<Object?> get props => [
        generalStatus,
        filename,
        size,
        selectedAt,
        result,
        page,
        message,
        analysis,
        analyzing,
        analysisMessage
      ];
}
