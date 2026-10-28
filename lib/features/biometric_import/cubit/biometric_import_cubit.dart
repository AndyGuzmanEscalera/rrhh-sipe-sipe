import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:failures/failures.dart';
import 'package:rrhh_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:rrhh_sipe_sipe/core/helpers/status_state.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';
import '../data/biometric_file_picker.dart';
part 'biometric_import_state.dart';

class BiometricImportCubit extends Cubit<BiometricImportState> {
  BiometricImportCubit(
      {required BiometricImportRepository repository,
      required BiometricFilePicker picker,
      AttendanceAnalysisRepository? analysisRepository})
      : _repository = repository,
        _picker = picker,
        _analysisRepository =
            analysisRepository ?? AttendanceAnalysisRepository(),
        super(const BiometricImportState());
  final BiometricImportRepository _repository;
  final BiometricFilePicker _picker;
  final AttendanceAnalysisRepository _analysisRepository;
  AttendanceConfiguration _configuration = AttendanceConfiguration();
  AttendanceConfiguration get configuration => _configuration;
  int _analysisRequest = 0;
  bool get supportsImport => _repository.supportsImport;

  Future<void> selectFile() async {
    if (state.generalStatus == GeneralStatus.loading || state.analyzing) return;
    final previous = state;
    emit(state.copyWith(
        generalStatus: GeneralStatus.loading,
        message: 'Seleccionando archivo…'));
    try {
      final file = await _picker.selectFile();
      if (isClosed) return;
      if (file == null) {
        emit(previous);
        return;
      }
      // Se conservan metadatos, sin retener otra copia de los bytes en el estado.
      emit(BiometricImportState(
          generalStatus: GeneralStatus.loading,
          filename: file.name,
          size: file.size,
          selectedAt: file.selectedAt,
          message: 'Leyendo archivo…'));
      final result = await _repository.readFile(file.bytes);
      if (isClosed) return;
      result.when(
          ok: (data) => emit(state.copyWith(
              generalStatus: GeneralStatus.success,
              result: data,
              page: 1,
              message: data.errors.isNotEmpty || data.records.isEmpty
                  ? 'Archivo procesado con advertencias.'
                  : 'Archivo procesado correctamente.')),
          err: (failure) => _error(FailureGeneric.message(
              failure: failure, messageResult: 'No se pudo leer el archivo.')));
      if (state.result != null &&
          state.generalStatus == GeneralStatus.success) {
        await reanalyze();
      }
    } on FormatException catch (error) {
      if (!isClosed) {
        emit(const BiometricImportState());
        _error(error.message);
      }
    } catch (_) {
      if (!isClosed) {
        emit(const BiometricImportState());
        _error('No se pudo seleccionar o leer el archivo. Intente nuevamente.');
      }
    }
  }

  void _error(String message) => emit(
      state.copyWith(generalStatus: GeneralStatus.error, message: message));

  void changePage(int page) {
    if (page >= 1 && page <= state.totalPages) emit(state.copyWith(page: page));
  }

  Future<void> reanalyze({AttendanceConfiguration? configuration}) async {
    if (configuration != null) _configuration = configuration;
    final parsed = state.result;
    if (parsed == null) return;
    final request = ++_analysisRequest;
    emit(state.copyWith(
        analyzing: true, analysisMessage: 'Analizando marcaciones…'));
    try {
      final analysis =
          await _analysisRepository.analyze(parsed.records, _configuration);
      if (isClosed || request != _analysisRequest || state.result != parsed) {
        return;
      }
      emit(state.copyWith(
          analysis: analysis, analyzing: false, analysisMessage: ''));
    } catch (_) {
      if (!isClosed && request == _analysisRequest && state.result == parsed) {
        emit(state.copyWith(
            analyzing: false,
            analysisMessage:
                'No se pudo completar el análisis. Los originales siguen disponibles.'));
      }
    }
  }
}
