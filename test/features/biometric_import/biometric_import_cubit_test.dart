import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/cubit/biometric_import_cubit.dart';
import 'package:rrhh_sipe_sipe/features/biometric_import/data/biometric_file_picker.dart';

class FakeBiometricPicker extends BiometricFilePicker {
  SelectedBiometricFile? file;
  Object? error;
  Completer<SelectedBiometricFile?>? pending;
  int calls = 0;
  @override
  Future<SelectedBiometricFile?> selectFile() async {
    calls++;
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return file;
  }
}

SelectedBiometricFile fixture(String text, {String name = 'marcaciones.dat'}) {
  final bytes = Uint8List.fromList(utf8.encode(text));
  return SelectedBiometricFile(
      name: name,
      size: bytes.length,
      selectedAt: DateTime(2026, 10, 7, 10, 30),
      bytes: bytes);
}

void main() {
  late FakeBiometricPicker picker;
  late BiometricImportCubit cubit;
  setUp(() {
    picker = FakeBiometricPicker();
    cubit = BiometricImportCubit(
        repository: const BiometricImportRepository(), picker: picker);
  });
  tearDown(() => cubit.close());

  test('Selección, lectura, resumen, paginación y sustitución del archivo',
      () async {
    picker.file = fixture(
        List.generate(45, (i) => 'id-$i\t2026-09-01 06:53\t1\t0\t1\t0')
            .join('\n'));
    final statuses = <GeneralStatus>[];
    final subscription =
        cubit.stream.listen((s) => statuses.add(s.generalStatus));
    await cubit.selectFile();
    expect(cubit.state.filename, 'marcaciones.dat');
    expect(cubit.state.selectedAt, DateTime(2026, 10, 7, 10, 30));
    expect(cubit.state.result!.records.length, 45);
    expect(cubit.state.totalPages, 3);
    expect(cubit.state.pageRecords.length, 20);
    expect(cubit.state.readyToImport, isTrue);
    cubit.changePage(3);
    expect(
        cubit.state.pageRecords.map((r) => r.lineNumber), [41, 42, 43, 44, 45]);
    cubit.changePage(4);
    expect(cubit.state.page, 3);
    picker.file = fixture('b\t2026-09-02 07:00\t1\t0\t1\t0', name: 'otro.txt');
    await cubit.selectFile();
    expect(cubit.state.page, 1);
    expect(cubit.state.result!.records.length, 1);
    expect(cubit.state.filename, 'otro.txt');
    await subscription.cancel();
    expect(statuses, contains(GeneralStatus.loading));
  });

  test('Cancelar conserva el archivo previo y no deja estado cargando',
      () async {
    await cubit.selectFile();
    expect(cubit.state.generalStatus, GeneralStatus.initial);
    picker.file = fixture('a\t2026-09-01 06:53\t1\t0\t1\t0');
    await cubit.selectFile();
    final previous = cubit.state;
    picker.file = null;
    await cubit.selectFile();
    expect(cubit.state, previous);
  });

  test('Advertencias y archivo vacío no bloquean el siguiente archivo',
      () async {
    picker.file = fixture('mala\na\t2026-09-01 06:53\t1\t0\t1\t0');
    await cubit.selectFile();
    expect(cubit.state.message, contains('advertencias'));
    expect(cubit.state.result!.errors.length, 1);
    expect(cubit.state.readyToImport, isTrue);
    picker.file = fixture('');
    await cubit.selectFile();
    expect(cubit.state.readyToImport, isFalse);
    expect(cubit.state.result!.records, isEmpty);
  });

  test('Error de selección y UTF-8 inválido producen estados de error',
      () async {
    picker.error = const FormatException('Seleccione un archivo .dat o .txt.');
    await cubit.selectFile();
    expect(cubit.state.generalStatus, GeneralStatus.error);
    expect(cubit.state.result, isNull);
    picker.error = null;
    picker.file = SelectedBiometricFile(
        name: 'x.txt',
        size: 1,
        selectedAt: DateTime(2026),
        bytes: Uint8List.fromList([0xff]));
    await cubit.selectFile();
    expect(cubit.state.message, contains('UTF-8'));
    expect(cubit.state.filename, 'x.txt');
    expect(cubit.state.readyToImport, isFalse);
  });

  test('Selección concurrente y cierre de página durante la lectura', () async {
    picker.pending = Completer();
    final pending = cubit.selectFile();
    await cubit.selectFile();
    expect(picker.calls, 1);
    await cubit.close();
    picker.pending!.complete(fixture(''));
    await pending;
    expect(cubit.isClosed, isTrue);
  });

  test('Reanalizar no sustituye originales y otro archivo reinicia el resumen',
      () async {
    picker.file = fixture('123\t2026-09-01 08:12\t1\tE\tX\t0\n'
        '123\t2026-09-01 18:00\t1\tS\tX\t0');
    await cubit.selectFile();
    final parsed = cubit.state.result!;
    final first = parsed.records.first;
    expect(cubit.state.analysis!.employees.single.identifier, '123');
    await cubit.reanalyze(
        configuration: AttendanceConfiguration(expectedMarks: const [
      ExpectedMark(minuteOfDay: 480, direction: MarkDirection.entry),
      ExpectedMark(minuteOfDay: 1080, direction: MarkDirection.exit)
    ], typeCodes: const {
      'E': MarkDirection.entry,
      'S': MarkDirection.exit
    }));
    expect(cubit.state.result, same(parsed));
    final analyzed = cubit.state.analysis!.employees.single.days.single;
    expect(analyzed.records.first, same(first));
    expect(analyzed.incidents.single.duration, const Duration(minutes: 7));
    picker.file = fixture('456\t2026-09-02 08:00\t1\tE\tX\t0');
    await cubit.selectFile();
    expect(cubit.state.analysis!.employees.single.identifier, '456');
    expect(cubit.state.analysis!.start, DateTime(2026, 9, 2));
  });
}
