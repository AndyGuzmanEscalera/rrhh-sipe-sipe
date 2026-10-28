import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:rrhh_sipe_sipe/core/helpers/status_state.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';

class AttendanceReportState extends Equatable implements StatusState {
  const AttendanceReportState(
      {this.loading = true, this.report, this.error = '', this.selectedDate});
  final bool loading;
  final AttendanceReport? report;
  final String error;
  final DateTime? selectedDate;
  @override
  GeneralStatus get generalStatus => loading
      ? GeneralStatus.loading
      : error.isEmpty
          ? GeneralStatus.success
          : GeneralStatus.error;
  @override
  DialogMessage get dialogMessage => const DialogMessage.empty();
  ServerAttendanceDay? get selectedDay {
    for (final day in report?.days ?? const <ServerAttendanceDay>[]) {
      if (day.date == selectedDate) return day;
    }
    return null;
  }

  @override
  List<Object?> get props => [loading, report, error, selectedDate];
}

class AttendanceReportCubit extends Cubit<AttendanceReportState> {
  AttendanceReportCubit(this._repository)
      : super(const AttendanceReportState());
  final AttendanceRepository _repository;
  bool _busy = false;
  Future<void> load(String id, AttendanceFilter filter) async {
    if (_busy) return;
    _busy = true;
    emit(const AttendanceReportState());
    final result = await _repository.report(id, filter);
    _busy = false;
    if (isClosed) return;
    result.when(
        ok: (value) =>
            emit(AttendanceReportState(loading: false, report: value)),
        err: (failure) => emit(
            AttendanceReportState(loading: false, error: failure.message)));
  }

  void selectDay(DateTime date) => emit(AttendanceReportState(
      loading: state.loading,
      report: state.report,
      error: state.error,
      selectedDate: date));
}
