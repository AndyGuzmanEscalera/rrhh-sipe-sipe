import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:failures/failures.dart';
import 'package:rrhh_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:rrhh_sipe_sipe/core/helpers/status_state.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';
import '../data/biometric_file_picker.dart';

part 'biometric_import_state.dart';

/// Importación biométrica.
///
/// Recibe marcaciones y las guarda en bruto. No decide entradas, salidas,
/// atrasos, ausencias ni anomalías: eso corresponde al módulo de Asistencia.
class BiometricImportCubit extends Cubit<BiometricImportState> {
  BiometricImportCubit(
      {required BiometricImportRepository repository,
      required BiometricFilePicker picker,
      this.pollInterval = const Duration(seconds: 3)})
      : _repository = repository,
        _picker = picker,
        super(const BiometricImportState());
  final BiometricImportRepository _repository;
  final BiometricFilePicker _picker;
  final Duration pollInterval;
  Timer? _syncTimer;
  int _historyRequest = 0;
  int _detailRequest = 0;

  Future<void> initialize() async {
    await Future.wait([loadDevices(), refreshHistory()]);
  }

  // --- Dispositivos ---------------------------------------------------------
  Future<void> loadDevices() async {
    final result = await _repository.devices();
    if (isClosed) return;
    result.when(
        ok: (items) => emit(state.copyWith(
            devices: items,
            deviceId: items.contains(state.deviceId)
                ? state.deviceId
                : (items.isEmpty ? '' : items.first))),
        err: (failure) => emit(state.copyWith(message: failure.message)));
  }

  void setDevice(String deviceId) => emit(state.copyWith(deviceId: deviceId));

  // --- Archivo --------------------------------------------------------------
  Future<void> selectFile() async {
    if (state.generalStatus == GeneralStatus.loading || state.importing) return;
    final previousMessage = state.message;
    final previousStatus = state.generalStatus;
    emit(state.copyWith(
        generalStatus: GeneralStatus.loading,
        message: 'Seleccionando archivo…'));
    try {
      final file = await _picker.selectFile();
      if (isClosed) return;
      if (file == null) {
        emit(state.copyWith(
            generalStatus: previousStatus, message: previousMessage));
        return;
      }
      emit(state.copyWith(
          generalStatus: GeneralStatus.loading,
          filename: file.name,
          size: file.size,
          selectedAt: file.selectedAt,
          clearResult: true,
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
    } on FormatException catch (error) {
      if (!isClosed) {
        emit(state.copyWith(clearFile: true, clearResult: true));
        _error(error.message);
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(clearFile: true, clearResult: true));
        _error('No se pudo seleccionar o leer el archivo. Intente nuevamente.');
      }
    }
  }

  void changePage(int page) {
    if (page >= 1 && page <= state.totalPages) emit(state.copyWith(page: page));
  }

  void setMapping(BiometricColumnMapping mapping) =>
      emit(state.copyWith(mapping: mapping));

  // --- Importación ----------------------------------------------------------
  Future<void> importFile() async {
    final parsed = state.result;
    if (state.importing ||
        parsed == null ||
        parsed.totalLines == parsed.ignoredLines) return;
    if (state.deviceId.isEmpty) {
      _error('Seleccione el dispositivo de origen de la importación.');
      return;
    }
    emit(state.copyWith(
        importing: true,
        generalStatus: GeneralStatus.initial,
        message: 'Importando marcaciones…'));
    final result = await _repository.importRecords(
      deviceId: state.deviceId,
      records: parsed.records,
      mapping: state.mapping,
      sourceFileName: state.filename,
      receivedRecords: parsed.totalLines - parsed.ignoredLines,
      errorRecords: parsed.errors.length,
    );
    if (isClosed) return;
    await result.when(
      ok: (summary) async {
        emit(state.copyWith(
            importing: false,
            clearFile: true,
            clearResult: true,
            generalStatus: summary.status == 'failed'
                ? GeneralStatus.error
                : GeneralStatus.success,
            message: summary.status == 'failed'
                ? '${summary.errorMessage ?? 'Importación fallida.'} Errores: ${summary.errorRecords}.'
                : _completedMessage(
                    'Importación',
                    summary.receivedRecords,
                    summary.newRecords,
                    summary.duplicateRecords,
                    summary.errorRecords)));
        await refreshHistory();
      },
      err: (failure) async {
        emit(state.copyWith(importing: false));
        _error(failure.message);
        await refreshHistory();
      },
    );
  }

  String _completedMessage(
      String operation, int received, int added, int duplicates, int errors) {
    if (added == 0 && duplicates > 0 && errors == 0) {
      return '$operation completada. No se encontraron nuevas marcaciones. '
          '$duplicates registros ya existían.';
    }
    return '$operation completada. Registros recibidos: $received. '
        'Nuevos: $added. Duplicados: $duplicates. Errores: $errors.';
  }

  // --- Sincronización con el dispositivo ------------------------------------
  Future<void> synchronize(DateTime start, DateTime end) async {
    if (state.syncing) return;
    final days = DateTime.utc(end.year, end.month, end.day)
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;
    if (days < 0 || days > 366) {
      _error('Seleccione un rango válido de hasta 367 días.');
      return;
    }
    emit(state.copyWith(
        syncing: true,
        generalStatus: GeneralStatus.initial,
        message: 'Solicitando sincronización…'));
    final result =
        await _repository.synchronize(start: _date(start), end: _date(end));
    if (isClosed) return;
    await result.when(
      ok: (batch) async {
        emit(state.copyWith(message: 'Sincronización en curso.'));
        _pollSync(batch.id);
        await refreshHistory();
      },
      err: (failure) async {
        emit(state.copyWith(syncing: false));
        _error(failure.message);
      },
    );
  }

  void _pollSync(String id) {
    _syncTimer?.cancel();
    _syncTimer = Timer(pollInterval, () async {
      final result = await _repository.syncStatus(id);
      if (isClosed) return;
      await result.when(
        ok: (batch) async {
          if (batch.isActive) {
            _pollSync(id);
            return;
          }
          final failed = batch.status == 'failed';
          emit(state.copyWith(
            syncing: false,
            generalStatus: failed ? GeneralStatus.error : GeneralStatus.success,
            message: failed
                ? batch.errorMessage ?? 'La sincronización falló.'
                : _completedMessage(
                    'Sincronización',
                    batch.receivedRecords,
                    batch.newRecords,
                    batch.duplicateRecords,
                    batch.errorRecords),
          ));
          await refreshHistory();
          if (state.selectedBatch?.id == id) await openBatch(batch);
        },
        err: (failure) async {
          emit(state.copyWith(syncing: false));
          _error(failure.message);
        },
      );
    });
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    return super.close();
  }

  // --- Historial y detalle --------------------------------------------------
  Future<void> refreshHistory({int page = 1}) async {
    final request = ++_historyRequest;
    emit(state.copyWith(historyLoading: true));
    final result = await _repository.history(
        page: page, pageSize: BiometricImportState.historyPageSize);
    if (isClosed || request != _historyRequest) return;
    result.when(
      ok: (value) => emit(state.copyWith(
          history: value.items,
          historyLoading: false,
          historyPage: page,
          historyTotal: value.total,
          lastImport:
              page == 1 && value.items.isNotEmpty ? value.items.first : null,
          clearLastImport: page == 1 && value.items.isEmpty)),
      err: (failure) =>
          emit(state.copyWith(historyLoading: false, message: failure.message)),
    );
  }

  Future<void> openBatch(BiometricImportBatch batch, {int offset = 0}) async {
    final request = ++_detailRequest;
    const pageSize = BiometricImportState.rawPageSize;
    emit(state.copyWith(
        selectedBatch: batch,
        batchRecords: const [],
        batchOffset: offset,
        batchHasMore: false,
        batchLoading: true));
    final result = await _repository.rawRecords(
        batchId: batch.id, limit: pageSize + 1, offset: offset);
    if (isClosed || request != _detailRequest) return;
    result.when(
      ok: (records) => emit(state.copyWith(
          batchLoading: false,
          batchRecords: records.take(pageSize).toList(),
          batchHasMore: records.length > pageSize)),
      err: (failure) {
        emit(state.copyWith(batchLoading: false));
        _error(failure.message);
      },
    );
  }

  void closeBatch() {
    _detailRequest++;
    emit(state.copyWith(clearBatch: true));
  }

  void _error(String message) => emit(
      state.copyWith(generalStatus: GeneralStatus.error, message: message));

  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
