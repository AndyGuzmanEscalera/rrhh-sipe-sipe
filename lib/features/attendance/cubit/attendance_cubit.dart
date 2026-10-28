import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:rrhh_sipe_sipe/core/helpers/status_state.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';

part 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit(this._repository,
      {DateTime? now, this.pollInterval = const Duration(seconds: 3)})
      : super(AttendanceState(
            year: (now ?? DateTime.now()).year,
            month: (now ?? DateTime.now()).month));
  final AttendanceRepository _repository;
  final Duration pollInterval;
  Timer? _poll;
  bool _initialized = false;
  bool _polling = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    emit(state.copyWith(loading: true));
    await Future.wait(
        [loadParameters(), loadContracts(), refreshDevice(), refreshSync()]);
    if (!isClosed) emit(state.copyWith(loading: false));
  }

  Future<void> loadContracts() async {
    if (state.generating) return;
    final result = await _repository.contracts();
    if (isClosed || state.generating) return;
    result.when(
        ok: (value) {
          final removed = state.contractId != null &&
              !value.items.any((item) => item.id == state.contractId);
          emit(state.copyWith(
              contracts: value,
              contractError: '',
              clearContract: removed,
              clearGeneration: removed));
        },
        err: (failure) => emit(state.copyWith(contractError: failure.message)));
  }

  Future<void> loadParameters() async {
    if (state.saving) return;
    final result = await _repository.parameters();
    if (isClosed) return;
    result.when(
        ok: (value) => emit(state.copyWith(
            parameters: value, parameterError: '', dirty: false)),
        err: (failure) =>
            emit(state.copyWith(parameterError: failure.message)));
  }

  Future<void> refreshDevice() async {
    if (state.checkingDevice) return;
    emit(state.copyWith(checkingDevice: true, deviceError: ''));
    final result = await _repository.deviceStatus();
    if (isClosed) return;
    result.when(
        ok: (value) =>
            emit(state.copyWith(device: value, checkingDevice: false)),
        err: (failure) => emit(state.copyWith(
            deviceError: failure.message,
            checkingDevice: false,
            clearDevice: true)));
  }

  void selectFilter({String? contractId, int? month, int? year}) {
    if (state.generating) return;
    emit(state.copyWith(
        contractId: contractId,
        month: month,
        year: year,
        clearGeneration: true,
        query: '',
        resultError: '',
        page: 1));
  }

  void search(String query) => emit(state.copyWith(query: query, page: 1));
  void changePage(int page) => emit(state.copyWith(page: page));
  void parametersDirty(bool value) =>
      emit(state.copyWith(dirty: value, parameterNotice: ''));

  Future<void> saveParameters(Map<String, int> seconds) async {
    if (state.saving || state.generating) return;
    emit(state.copyWith(saving: true, parameterError: '', parameterNotice: ''));
    final result = await _repository.saveParameters(seconds);
    if (isClosed) return;
    result.when(
        ok: (value) => emit(state.copyWith(
            parameters: value,
            saving: false,
            dirty: false,
            needsRefresh: state.generation != null,
            parameterNotice: 'Parámetros guardados.')),
        err: (failure) => emit(
            state.copyWith(saving: false, parameterError: failure.message)));
  }

  Future<void> generate() async {
    final filter = state.filter;
    if (state.generating || state.saving || state.dirty || filter == null) {
      return;
    }
    emit(state.copyWith(
        generating: true, resultError: '', clearGeneration: true));
    final result = await _repository.generate(filter);
    if (isClosed) return;
    result.when(
        ok: (value) => emit(state.copyWith(
            generation: value,
            generating: false,
            needsRefresh: false,
            page: 1)),
        err: (failure) => emit(
            state.copyWith(generating: false, resultError: failure.message)));
  }

  Future<void> synchronize(DateTime start, DateTime end) async {
    if (state.startingSync || state.sync?.isActive == true) return;
    if (start.isAfter(end) || end.difference(start).inDays > 366) {
      emit(state.copyWith(
          syncError: 'Seleccione un rango válido de hasta 367 días.'));
      return;
    }
    emit(state.copyWith(startingSync: true, syncError: ''));
    final result =
        await _repository.synchronize(start: _date(start), end: _date(end));
    if (isClosed) return;
    await result.when(ok: (job) async {
      emit(state.copyWith(sync: job, startingSync: false));
      _schedulePoll();
    }, err: (failure) async {
      emit(state.copyWith(startingSync: false, syncError: failure.message));
      // Another user may already own the job. The server is the authority.
      await refreshSync();
    });
  }

  Future<void> refreshSync() async {
    if (_polling) return;
    _polling = true;
    final result = await _repository.latestSync();
    _polling = false;
    if (isClosed) return;
    result.when(ok: (job) {
      final finished =
          state.sync?.isActive == true && job?.status == 'completed';
      emit(state.copyWith(
          sync: job,
          syncLoaded: true,
          clearSync: job == null,
          syncError: '',
          needsRefresh: state.needsRefresh || finished));
      _schedulePoll();
    }, err: (failure) {
      _poll?.cancel();
      emit(state.copyWith(syncError: failure.message));
    });
  }

  void _schedulePoll() {
    _poll?.cancel();
    if (!isClosed && state.sync?.isActive == true) {
      _poll = Timer(pollInterval, _pollJob);
    }
  }

  Future<void> _pollJob() async {
    final job = state.sync;
    if (job == null || !job.isActive || _polling || isClosed) return;
    _polling = true;
    final result = await _repository.syncStatus(job.id);
    _polling = false;
    if (isClosed) return;
    result.when(
        ok: (value) {
          emit(state.copyWith(
              sync: value,
              syncError: '',
              needsRefresh: state.needsRefresh || value.status == 'completed'));
          _schedulePoll();
        },
        err: (failure) => emit(state.copyWith(syncError: failure.message)));
  }

  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
