import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:failures/failures.dart';
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

class FakeBiometricImportRepository extends Fake
    implements BiometricImportRepository {
  final List<Map<String, Object?>> imported = [];
  int historyCalls = 0;
  int syncCalls = 0;
  List<BiometricImportBatch> batches = [];
  List<BiometricRawRecord> records = [];
  List<String> deviceIds = const ['test-clock'];
  BiometricImportResult? importResult;
  Failure? failure;

  @override
  bool get supportsImport => true;

  @override
  Future<Result<BiometricParseResult, Failure>> readFile(
      List<int> bytes) async {
    if (failure != null) return err(failure!);
    final text = utf8.decode(bytes);
    final records = <BiometricRecord>[];
    var line = 0;
    for (final raw in const LineSplitter().convert(text)) {
      line++;
      if (raw.trim().isEmpty) continue;
      final fields = raw.split('\t');
      if (fields.length != 6) continue;
      records.add(BiometricRecord(
        employeeIdentifier: fields[0].trim(),
        timestamp: DateTime(2026, 11, 18, 7, 54, 13),
        field3: fields[2],
        field4: fields[3],
        field5: fields[4],
        field6: fields[5],
        rawLine: raw,
        lineNumber: line,
      ));
    }
    return ok(BiometricParseResult(
      totalLines: line,
      ignoredLines: 0,
      records: records,
      errors: const [],
      uniqueIdentifiers:
          records.map((r) => r.employeeIdentifier).toSet().length,
      minTimestamp: records.isEmpty ? null : DateTime(2026, 11, 18),
      maxTimestamp: records.isEmpty ? null : DateTime(2026, 11, 18),
    ));
  }

  @override
  Future<Result<BiometricImportResult, Failure>> importRecords({
    required String deviceId,
    required List<BiometricRecord> records,
    required BiometricColumnMapping mapping,
    String? sourceFileName,
    int? receivedRecords,
    int errorRecords = 0,
  }) async {
    if (failure != null) return err(failure!);
    imported.add({'device_id': deviceId, 'file': sourceFileName});
    return ok(importResult ??
        BiometricImportResult.fromJson({
          'batch_id': 'batch-1',
          'device_id': deviceId,
          'origin': 'SOURCE_FILE',
          'source_file_name': sourceFileName,
          'status': 'completed',
          'received_records': receivedRecords ?? records.length,
          'new_records': records.length,
          'duplicate_records': 0,
          'error_records': errorRecords,
        }));
  }

  @override
  Future<Result<BiometricBatchPage, Failure>> history({
    int page = 1,
    int pageSize = 20,
    String? origin,
  }) async {
    historyCalls++;
    if (failure != null) return err(failure!);
    return ok((items: batches, total: batches.length));
  }

  @override
  Future<Result<List<BiometricRawRecord>, Failure>> rawRecords({
    String? fromDate,
    String? toDate,
    String? userId,
    String? deviceId,
    String? source,
    String? batchId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (failure != null) return err(failure!);
    return ok(records);
  }

  @override
  Future<Result<List<String>, Failure>> devices() async {
    if (failure != null) return err(failure!);
    return ok(deviceIds);
  }

  @override
  Future<Result<BiometricImportBatch, Failure>> synchronize({
    required String start,
    required String end,
  }) async {
    syncCalls++;
    if (failure != null) return err(failure!);
    return ok(BiometricImportBatch.fromJson({
      'id': 'sync-1',
      'status': 'queued',
    }));
  }

  @override
  Future<Result<BiometricImportBatch, Failure>> syncStatus(String id) async =>
      ok(BiometricImportBatch.fromJson({
        'id': id,
        'status': 'completed',
        'downloaded_records': 1,
        'duplicate_records': 1,
      }));
}

SelectedBiometricFile fixture(String text, {String name = 'marcaciones.dat'}) {
  final bytes = Uint8List.fromList(utf8.encode(text));
  return SelectedBiometricFile(
      name: name,
      size: bytes.length,
      selectedAt: DateTime(2026, 10, 7, 10, 30),
      bytes: bytes);
}

BiometricImportBatch batchJson({
  String id = 'batch-1',
  String origin = 'SOURCE_FILE',
  int received = 10,
  int nuevos = 8,
  int duplicados = 2,
  int errores = 0,
  String status = 'completed',
}) =>
    BiometricImportBatch.fromJson({
      'id': id,
      'device_id': 'test-clock',
      'origin': origin,
      'source_file_name': origin == 'SOURCE_FILE' ? 'marcaciones.dat' : null,
      'status': status,
      'downloaded_records': received,
      'new_records': nuevos,
      'duplicate_records': duplicados,
      'error_records': errores,
      'created_at': '2026-11-18T09:00:00Z',
      'requested_start_date': '2026-11-18',
      'requested_end_date': '2026-11-18',
    });

void main() {
  late FakeBiometricPicker picker;
  late FakeBiometricImportRepository repository;
  late BiometricImportCubit cubit;
  setUp(() {
    picker = FakeBiometricPicker();
    repository = FakeBiometricImportRepository();
    cubit = BiometricImportCubit(repository: repository, picker: picker);
  });
  tearDown(() => cubit.close());

  test('Seleccionar archivo previsualiza sin guardar nada', () async {
    picker.file = fixture(
        List.generate(45, (i) => 'id-$i\t2026-11-18 07:54\t15\t255\t1\t0')
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
    cubit.changePage(3);
    expect(
        cubit.state.pageRecords.map((r) => r.lineNumber), [41, 42, 43, 44, 45]);
    cubit.changePage(4);
    expect(cubit.state.page, 3);
    // La previsualización no persiste nada.
    expect(repository.imported, isEmpty);

    await subscription.cancel();
    expect(statuses, contains(GeneralStatus.loading));
  });

  test('Cancelar conserva el archivo previo y no deja estado cargando',
      () async {
    await cubit.selectFile();
    expect(cubit.state.generalStatus, GeneralStatus.initial);
    picker.file = fixture('a\t2026-11-18 07:54\t15\t255\t1\t0');
    await cubit.selectFile();
    final previous = cubit.state;
    picker.file = null;
    await cubit.selectFile();
    expect(cubit.state, previous);
  });

  test('Importar envía los registros y muestra el resumen del lote', () async {
    await cubit.initialize();
    picker.file = fixture('0000007\t2026-11-18 07:54:13\t15\t255\t1\t0\n'
        '0000007\t2026-11-18 12:04:59\t25\t255\t1\t0');
    await cubit.selectFile();
    await cubit.importFile();
    expect(repository.imported.single['device_id'], 'test-clock');
    expect(repository.imported.single['file'], 'marcaciones.dat');
    expect(cubit.state.message, contains('Importación completada'));
    expect(cubit.state.message, contains('Nuevos: 2'));

    // Tras importar, el archivo se libera.
    expect(cubit.state.result, isNull);
    expect(cubit.state.filename, isNull);
  });

  test('Todos duplicados es un resultado correcto, no un error', () async {
    await cubit.initialize();
    repository.importResult = BiometricImportResult.fromJson({
      'batch_id': 'batch-2',
      'device_id': 'test-clock',
      'origin': 'SOURCE_FILE',
      'status': 'completed',
      'received_records': 1000,
      'new_records': 0,
      'duplicate_records': 1000,
      'error_records': 0,
    });
    picker.file = fixture('0000007\t2026-11-18 07:54:13\t15\t255\t1\t0');
    await cubit.selectFile();
    await cubit.importFile();
    expect(cubit.state.generalStatus, isNot(GeneralStatus.error));
    expect(
        cubit.state.message, contains('No se encontraron nuevas marcaciones'));
    expect(cubit.state.message, contains('1000 registros ya existían'));
  });

  test('El mapeo de columnas se puede corregir antes de importar', () async {
    await cubit.initialize();
    picker.file = fixture('0000007\t2026-11-18 07:54:13\t15\t255\t1\t0');
    await cubit.selectFile();
    cubit.setMapping(const BiometricColumnMapping(
      status: BiometricColumn.field4,
      punch: BiometricColumn.field3,
      uid: BiometricColumn.none,
    ));
    expect(cubit.state.mapping.status, BiometricColumn.field4);
    expect(cubit.state.mapping.punch, BiometricColumn.field3);
  });

  test('El historial se carga y el detalle del lote muestra la evidencia',
      () async {
    repository.batches = [
      batchJson(),
      batchJson(
          id: 'batch-0',
          origin: 'SOURCE_API',
          received: 5,
          nuevos: 5,
          duplicados: 0),
    ];
    repository.records = [
      BiometricRawRecord.fromJson({
        'record_id': 'hash',
        'device_id': 'test-clock',
        'user_id': '0000007',
        'timestamp': '2026-11-18T07:54:13',
        'status': 15,
        'punch': 255,
        'uid': 7,
        'source': 'SOURCE_FILE',
      }),
    ];
    await cubit.initialize();
    expect(repository.historyCalls, 1);
    expect(cubit.state.history.length, 2);
    expect(cubit.state.lastImport!.originLabel, 'TXT');
    await cubit.openBatch(cubit.state.history.first);
    expect(cubit.state.batchRecords.single.userId, '0000007');
    expect(cubit.state.batchRecords.single.status, 15);
    expect(cubit.state.batchRecords.single.punch, 255);
    cubit.closeBatch();
    expect(cubit.state.selectedBatch, isNull);
  });

  test('Sincronizar con el dispositivo encola el trabajo', () async {
    await cubit.synchronize(DateTime(2026, 11, 1), DateTime(2026, 11, 18));
    expect(repository.syncCalls, 1);
  });

  test('La sincronización publica el resumen al completarse', () async {
    final polling = BiometricImportCubit(
        repository: repository, picker: picker, pollInterval: Duration.zero);
    addTearDown(polling.close);
    final finished = polling.stream.firstWhere(
        (state) => state.message.contains('1 registros ya existían'));
    await polling.synchronize(DateTime(2026, 11, 1), DateTime(2026, 11, 18));
    expect((await finished).syncing, isFalse);
    expect(repository.historyCalls, 2);
  });

  test('Un rango inválido no se envía', () async {
    await cubit.synchronize(DateTime(2026, 11, 18), DateTime(2026, 11, 1));
    expect(repository.syncCalls, 0);
    expect(cubit.state.message, contains('rango válido'));
  });

  test('Error del servidor se informa sin dejar la importación en curso',
      () async {
    repository.failure =
        const GenericFailure('No fue posible completar la importación.');

    await cubit.initialize();
    expect(cubit.state.message, contains('No fue posible completar'));
    expect(cubit.state.importing, isFalse);
    expect(cubit.state.syncing, isFalse);
  });
}
