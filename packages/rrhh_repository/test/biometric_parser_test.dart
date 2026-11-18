import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_api/rrhh_api.dart';
import 'package:rrhh_repository/rrhh_repository.dart';

void main() {
  const parser = BiometricParser();
  test('Importa TXT a través del contrato HTTP y cuenta filas no vacías',
      () async {
    const raw = ' 007\t2026-11-18 07:54:13\t15\t255\tX\t0';
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final data = switch (options.path) {
        '/rrhh/biometric/devices' => {
            'items': [
              {'device_id': 'fixture-clock'}
            ],
          },
        '/rrhh/biometric/import' => {
            'batch_id': 'fixture-batch',
            'status': 'completed',
            'received_records': 2,
            'new_records': 1,
            'error_records': 1,
          },
        _ => throw StateError('Ruta inesperada'),
      };
      if (options.method == 'POST') {
        expect(options.data, {
          'device_id': 'fixture-clock',
          'source_file_name': 'fixture.txt',
          'received_records': 2,
          'error_records': 1,
          'records': [
            {
              'user_id': ' 007',
              'timestamp': '2026-11-18T07:54:13',
              'status': 15,
              'punch': 255,
              'uid': null,
              'raw_line': raw,
              'line_number': 1,
            }
          ],
        });
      }
      handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: data));
    }));
    final repo = BiometricImportRepository(
        api: BiometricImportApi(mainApi: ApiMethod(dio: dio)));
    expect((await repo.devices()).valueOrNull(), ['fixture-clock']);
    final file =
        (await repo.readFile(utf8.encode('$raw\n\ninválida'))).valueOrNull()!;
    final result = await repo.importRecords(
        deviceId: 'fixture-clock',
        sourceFileName: 'fixture.txt',
        mapping: const BiometricColumnMapping(),
        records: file.records,
        receivedRecords: file.totalLines - file.ignoredLines,
        errorRecords: file.errors.length);
    expect(result.valueOrNull()?.batchId, 'fixture-batch');
    expect(result.valueOrNull()?.errorRecords, 1);
  });
  test('CRLF/LF, BOM, duplicados, campos originales y numeración física',
      () async {
    const first = '0000007\t2026-09-01 06:53:11\t 1 \t0\tX\t';
    const last = '0000008\t2026-09-02 07:04\t1\t0\t1\t0';
    final data =
        await parser.parse('\uFEFF$first\r\n\r\n$first\n \t \n$last\n');
    expect(data.totalLines, 5);
    expect(data.ignoredLines, 2);
    expect(data.records.length, 3);
    expect(data.foundRecords, 3);
    expect(data.uniqueIdentifiers, 2);
    expect(data.errors, isEmpty);
    expect(data.records.map((r) => r.lineNumber), [1, 3, 5]);
    expect(data.records.first.rawLine, first);
    expect(data.records[1].rawLine, first);
    expect(data.records.first.field3, ' 1 ');
    expect(data.records.first.field5, 'X');
    expect(data.records.first.field6, '');
    expect(data.minTimestamp, DateTime.utc(2026, 9, 1, 6, 53, 11));
    expect(data.maxTimestamp, DateTime.utc(2026, 9, 2, 7, 4));
  });

  test('Errores por fila no interrumpen las filas posteriores', () async {
    final lines = [
      '0000007 2026-09-01 06:53 1 0 1 0',
      '\t2026-09-01 06:53\t1\t0\t1\t0',
      'a\t2026-02-30 06:53\t1\t0\t1\t0',
      'a\t2026-09-01 24:00\t1\t0\t1\t0',
      'a\t2026-09-01 06:53\t1\t0\t1\t0\textra',
      'a\t2026-09-01 06:53\t1\t0\t1\t0',
    ];
    final data = await parser.parse(lines.join('\n'));
    expect(data.errors.map((e) => e.lineNumber), [1, 2, 3, 4, 5]);
    expect(data.errors.map((e) => e.rawLine), lines.take(5));
    expect(data.errors[0].reason, contains('tabulaciones'));
    expect(data.errors[1].reason, 'Identificador vacío.');
    expect(data.errors[2].reason, contains('Fecha inválida'));
    expect(data.records.single.lineNumber, 6);
  });

  test('Fechas estrictas, bisiestos y segundos', () async {
    final dates = [
      '2024-02-29 23:59:59',
      '2026-02-29 12:00',
      '2026-00-01 12:00',
      '2026-13-01 12:00',
      '2026-09-00 12:00',
      '2026-09-01 12:60',
      '2026-09-01 12:00:60',
      '2026-9-1 12:00',
      '01/09/2026 12:00',
      '2026-09-01 12:00:00Z',
      '2026-09-01 12:00'
    ];
    final data =
        await parser.parse(dates.map((d) => 'a\t$d\t1\t0\t1\t0').join('\n'));
    expect(data.records.map((r) => r.lineNumber), [1, 11]);
    expect(data.errors.length, 9);
  });

  test('Vacío y solo espacios no producen marcaciones ni fechas ficticias',
      () async {
    final empty = await parser.parse('');
    expect(empty.totalLines, 0);
    final blank = await parser.parse('\r\n  \n\t\n');
    expect(blank.totalLines, 3);
    expect(blank.ignoredLines, 3);
    expect(blank.records, isEmpty);
    expect(blank.errors, isEmpty);
    expect(blank.minTimestamp, isNull);
    expect(blank.maxTimestamp, isNull);
  });

  test('10000 registros, duplicados y cesión del control', () async {
    var yielded = false;
    final pending = Future<void>.delayed(Duration.zero, () => yielded = true);
    final data = await parser.parse(
        List.filled(10000, 'a\t2026-09-01 06:53:11\t1\t0\t1\t0').join('\n'));
    expect(yielded, isTrue);
    await pending;
    expect(data.records.length, 10000);
    expect(data.records.last.lineNumber, 10000);
    expect(data.uniqueIdentifiers, 1);
    expect(yielded, isTrue);
  });

  test('Repositorio devuelve Result y no simula guardado', () async {
    const repository = BiometricImportRepository();
    final invalid = await repository.readFile([0xff, 0xfe, 0x00]);
    expect(invalid.isErr, isTrue);
    expect(invalid.failureOrNull()?.message, contains('UTF-8'));
    final valid = await repository
        .readFile(utf8.encode('a\t2026-09-01 06:53\t1\t0\t1\t0'));
    expect(valid.valueOrNull()?.records.length, 1);
    // Sin API configurada el envío falla de forma controlada: no simula éxito.
    final enviado = await repository.importRecords(
      deviceId: 'test-clock',
      records: valid.valueOrNull()!.records,
      mapping: const BiometricColumnMapping(),
    );
    expect(enviado.isErr, isTrue);
  });

  test('El mapeo de columnas copia los valores sin interpretarlos', () {
    const mapping = BiometricColumnMapping(
        status: BiometricColumn.field3,
        punch: BiometricColumn.field4,
        uid: BiometricColumn.none);
    final record = BiometricRecord(
      employeeIdentifier: '0000007',
      timestamp: DateTime(2026, 11, 18, 7, 54, 13),
      field3: '15',
      field4: '255',
      field5: 'X',
      field6: '0',
      rawLine: '0000007\t2026-11-18 07:54:13\t15\t255\tX\t0',
      lineNumber: 1,
    );
    final api = mapping.toApiRecord(record)!;
    expect(api['user_id'], '0000007');
    expect(api['timestamp'], '2026-11-18T07:54:13');
    expect(api['status'], 15);
    expect(api['punch'], 255);
    expect(api['uid'], isNull);
    expect(api['raw_line'], record.rawLine);
  });

  test('Un campo no numérico invalida la marcación y no se inventa un valor',
      () {
    const mapping = BiometricColumnMapping(
        status: BiometricColumn.field3,
        punch: BiometricColumn.field4,
        uid: BiometricColumn.none);
    final record = BiometricRecord(
      employeeIdentifier: '0000007',
      timestamp: DateTime(2026, 11, 18, 7, 54, 13),
      field3: 'IN',
      field4: '255',
      field5: 'X',
      field6: '0',
      rawLine: '0000007\t2026-11-18 07:54:13\tIN\t255\tX\t0',
      lineNumber: 1,
    );
    expect(mapping.toApiRecord(record), isNull);
  });
}
