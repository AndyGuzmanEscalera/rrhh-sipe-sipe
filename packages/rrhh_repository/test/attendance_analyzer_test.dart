import 'package:flutter_test/flutter_test.dart';
import 'package:rrhh_repository/rrhh_repository.dart';

BiometricRecord mark(String time, String type,
    {String ci = '123', int line = 1, int day = 1}) {
  final parts = time.split(':').map(int.parse).toList();
  return BiometricRecord(
      employeeIdentifier: ci,
      timestamp: DateTime(
          2026, 9, day, parts[0], parts[1], parts.length > 2 ? parts[2] : 0),
      field3: ' dispositivo ',
      field4: type,
      field5: 'X',
      field6: '0',
      rawLine:
          ' $ci\t2026-09-${day.toString().padLeft(2, '0')} $time\t dispositivo \t$type\tX\t0 ',
      lineNumber: line);
}

AttendanceConfiguration config({int duplicate = 5, int tolerance = 5}) =>
    AttendanceConfiguration(
        expectedMarks: const [
          ExpectedMark(minuteOfDay: 480, direction: MarkDirection.entry),
          ExpectedMark(minuteOfDay: 720, direction: MarkDirection.exit),
          ExpectedMark(minuteOfDay: 840, direction: MarkDirection.entry),
          ExpectedMark(minuteOfDay: 1080, direction: MarkDirection.exit),
        ],
        typeCodes: const {
          'E': MarkDirection.entry,
          'S': MarkDirection.exit
        },
        duplicateWindow: Duration(minutes: duplicate),
        lateTolerance: Duration(minutes: tolerance));

EmployeeAdmin employee(String ci, {String id = 'e1', bool active = true}) =>
    EmployeeAdmin(
        id: id,
        firstName: 'Ana',
        lastName: 'Pérez',
        documentNumber: ci,
        isActive: active,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));

void main() {
  const analyzer = AttendanceAnalyzer();
  final date = DateTime(2026, 9, 1);
  List<BiometricRecord> normal({String arrival = '07:58'}) => [
        mark(arrival, 'E', line: 1),
        mark('12:01', 'S', line: 2),
        mark('13:57', 'E', line: 3),
        mark('18:03', 'S', line: 4),
      ];

  test('Jornada compatible y descanso programado no generan incidencias', () {
    final day = analyzer.analyzeDay(date, normal(), config());
    expect(day.status, AttendanceStatus.normal);
    expect(day.incidents, isEmpty);
  });
  test('08:12 menos horario 08:00 y tolerancia 5 produce atraso de 7 minutos',
      () {
    final day = analyzer.analyzeDay(date, normal(arrival: '08:12'), config());
    final late = day.incidents.singleWhere((i) => i.type == IncidentType.late);
    expect(late.duration, const Duration(minutes: 7));
    expect(day.status, AttendanceStatus.observation);
    expect(analyzer.analyzeDay(date, normal(arrival: '08:05'), config()).status,
        AttendanceStatus.normal);
    expect(
        analyzer
            .analyzeDay(date, normal(arrival: '08:12'), config(tolerance: 15))
            .status,
        AttendanceStatus.normal);
  });
  test('Conserva precisión de segundos en el atraso', () {
    final day =
        analyzer.analyzeDay(date, normal(arrival: '08:05:30'), config());
    expect(day.incidents.single.duration, const Duration(seconds: 30));
  });
  for (final example in <(int, String, IncidentType?, int)>[
    (0, '07:50', null, 0),
    (0, '08:00', null, 0),
    (0, '08:05', null, 0),
    (0, '08:06', IncidentType.late, 1),
    (0, '08:10', IncidentType.late, 5),
    (1, '11:50', IncidentType.earlyExit, 10),
    (1, '12:00', null, 0),
    (1, '12:10', null, 0),
    (1, '12:30', null, 0),
    (2, '13:40', null, 0),
    (2, '14:00', null, 0),
    (2, '14:05', null, 0),
    (2, '14:10', IncidentType.lateReturn, 5),
    (3, '17:40', IncidentType.earlyExit, 20),
    (3, '18:00', null, 0),
    (3, '18:10', null, 0),
    (3, '18:30', null, 0),
  ]) {
    test('Evento ${example.$1} a ${example.$2}: ${example.$3 ?? 'NORMAL'}', () {
      final originals = normal();
      originals[example.$1] =
          mark(example.$2, example.$1.isEven ? 'E' : 'S', line: example.$1 + 1);
      final day = analyzer.analyzeDay(date, originals, config());
      if (example.$3 == null) {
        expect(day.incidents, isEmpty);
        expect(day.status, AttendanceStatus.normal);
      } else {
        expect(day.incidents.single.type, example.$3);
        expect(day.incidents.single.duration, Duration(minutes: example.$4));
        expect(
            day.incidents.single.records.single, same(originals[example.$1]));
      }
    });
  }
  test(
      'Entradas anticipadas y salidas posteriores fuera de ventana son normales',
      () {
    final originals = [
      mark('06:00', 'E'),
      mark('12:00', 'S', line: 2),
      mark('14:00', 'E', line: 3),
      mark('20:00', 'S', line: 4),
    ];
    final day = analyzer.analyzeDay(date, originals, config());
    expect(day.incidents, isEmpty);
    expect(day.records, orderedEquals(originals));
  });
  test('Horario personalizado y tolerancia solo para entradas', () {
    final custom = AttendanceConfiguration(
      expectedMarks: const [
        ExpectedMark(minuteOfDay: 540, direction: MarkDirection.entry),
        ExpectedMark(minuteOfDay: 780, direction: MarkDirection.exit),
        ExpectedMark(minuteOfDay: 900, direction: MarkDirection.entry),
        ExpectedMark(minuteOfDay: 1140, direction: MarkDirection.exit),
      ],
      lateTolerance: const Duration(minutes: 10),
      typeCodes: config().typeCodes,
    );
    final day = analyzer.analyzeDay(
        date,
        [
          mark('09:10', 'E'),
          mark('12:59:30', 'S', line: 2),
          mark('15:11', 'E', line: 3),
          mark('19:30', 'S', line: 4),
        ],
        custom);
    expect(day.incidents.map((i) => i.type),
        [IncidentType.earlyExit, IncidentType.lateReturn]);
    expect(day.incidents.first.duration, const Duration(seconds: 30));
    expect(day.incidents.last.duration, const Duration(minutes: 1));
  });
  for (final count in [0, 1, 2, 3]) {
    test('$count marcas detecta faltantes sin fabricar registros', () {
      final originals = normal().take(count).toList();
      final day = analyzer.analyzeDay(date, originals, config());
      expect(day.status, AttendanceStatus.anomaly);
      expect(
          day.incidents.where((i) => i.type == IncidentType.missingMark).length,
          4 - count);
      expect(day.records.length, count);
    });
  }
  test(
      'Seis marcas con salida y retorno son observación, no anomalía por cantidad',
      () {
    final originals = [
      ...normal(),
      mark('10:00', 'S', line: 5),
      mark('10:15', 'E', line: 6)
    ];
    final day = analyzer.analyzeDay(date, originals, config());
    expect(day.records.length, 6);
    expect(day.status, AttendanceStatus.observation);
    expect(
        day.incidents
            .where((i) => i.type == IncidentType.extraMark)
            .single
            .records
            .length,
        2);
    expect(
        day.incidents
            .where((i) => i.type == IncidentType.intermediateExit)
            .single
            .duration,
        const Duration(minutes: 15));
  });
  test('Salida 11:03 y retorno 17:05 calcula 6 h 02 min sin determinar causa',
      () {
    final day = analyzer.analyzeDay(
        date,
        [
          mark('07:55', 'E'),
          mark('11:03', 'S', line: 2),
          mark('17:05', 'E', line: 3),
          mark('18:02', 'S', line: 4)
        ],
        config());
    expect(
        day.incidents
            .singleWhere((i) => i.type == IncidentType.intermediateExit)
            .duration,
        const Duration(hours: 6, minutes: 2));
  });
  test('Posible duplicado conserva todas las originales y sugerencia pendiente',
      () {
    final originals = [
      mark('18:15', 'S', line: 3),
      mark('18:10', 'S', line: 1),
      mark('18:12', 'S', line: 2)
    ];
    final rawLines = originals.map((r) => r.rawLine).toList();
    final timestamps = originals.map((r) => r.timestamp).toList();
    final day = analyzer.analyzeDay(date, originals, config());
    final duplicate = day.incidents
        .singleWhere((i) => i.type == IncidentType.possibleDuplicate);
    expect(duplicate.records.length, 3);
    expect(duplicate.suggestion!.principal, same(originals[1]));
    expect(duplicate.suggestion!.reviewStatus, SuggestionReviewStatus.pending);
    expect(day.records.length, 3);
    expect(originals.map((r) => r.rawLine), rawLines);
    expect(originals.map((r) => r.timestamp), timestamps);
    expect(originals.first.lineNumber, 3);
    expect(() => day.records.clear(), throwsUnsupportedError);
    expect(() => duplicate.suggestion!.records.clear(), throwsUnsupportedError);
    expect(
        analyzer
            .analyzeDay(date, originals, config(duplicate: 1))
            .incidents
            .where((i) => i.type == IncidentType.possibleDuplicate),
        isEmpty);
  });
  test(
      'La ventana limita el grupo completo, no una cadena de cercanía ilimitada',
      () {
    final day = analyzer.analyzeDay(
        date,
        [
          mark('18:10', 'S'),
          mark('18:14', 'S', line: 2),
          mark('18:18', 'S', line: 3)
        ],
        config());
    expect(
        day.incidents
            .singleWhere((i) => i.type == IncidentType.possibleDuplicate)
            .records
            .length,
        2);
  });
  test('Tipos distintos cercanos no se sugieren como duplicados', () {
    final day = analyzer.analyzeDay(
        date, [mark('18:10', 'S'), mark('18:12', 'E', line: 2)], config());
    expect(day.incidents.where((i) => i.type == IncidentType.possibleDuplicate),
        isEmpty);
  });
  test('Salidas consecutivas fuera de ventana generan secuencia incoherente',
      () {
    final day = analyzer.analyzeDay(
        date, [mark('12:00', 'S'), mark('18:00', 'S', line: 2)], config());
    expect(
        day.incidents
            .where((i) => i.type == IncidentType.inconsistentSequence)
            .length,
        1);
  });
  test('No interpreta códigos desconocidos ni horarios no configurados', () {
    final day = analyzer.analyzeDay(date, normal(), AttendanceConfiguration());
    expect(day.status, AttendanceStatus.observation);
    expect(
        day.incidents.where((i) =>
            i.type == IncidentType.late ||
            i.type == IncidentType.missingMark ||
            i.type == IncidentType.intermediateExit ||
            i.type == IncidentType.inconsistentSequence),
        isEmpty);
    final unknown = analyzer.analyzeDay(date, [mark('08:00', 'X')], config());
    expect(
        unknown.incidents
            .where((i) => i.type == IncidentType.unknownMarkType)
            .length,
        1);
  });
  test('Agrupa por CI exacto y semanas recortadas, incluyendo días sin marcas',
      () async {
    final records = [
      mark('08:00', 'E', day: 2),
      mark('18:00', 'S', day: 8, line: 2),
      mark('12:00', 'S', ci: '999', day: 4, line: 3)
    ];
    final report = await analyzer.analyze(
        records: records,
        configuration: config(),
        employees: [employee('123', active: false)]);
    expect(report.start, DateTime(2026, 9, 2));
    expect(report.end, DateTime(2026, 9, 8));
    final ana = report.employees.singleWhere((e) => e.identifier == '123');
    expect(ana.employee!.isActive, isFalse);
    expect(ana.totalMarks, 2);
    expect(ana.days.length, 7);
    expect(ana.weeks.length, 2);
    expect(ana.weeks.first.start, DateTime(2026, 9, 2));
    expect(ana.weeks.first.end, DateTime(2026, 9, 6));
    expect(ana.weeks.last.end, DateTime(2026, 9, 8));
    expect(
        ana.days
            .expand((d) => d.records)
            .every((r) => r.employeeIdentifier == '123'),
        isTrue);
    expect(
        ana.days
            .singleWhere((d) => d.date.day == 3)
            .incidents
            .where((i) => i.type == IncidentType.missingMark)
            .length,
        4);
    expect(ana.days.singleWhere((d) => d.date.day == 5).status,
        AttendanceStatus.normal);
    expect(
        ana.count(AttendanceStatus.normal) +
            ana.count(AttendanceStatus.observation) +
            ana.count(AttendanceStatus.anomaly),
        7);
    expect(report.employees.singleWhere((e) => e.identifier == '999').employee,
        isNull);
  });
  test('CI repetido o CI con ceros distintos no se vincula arbitrariamente',
      () async {
    final report = await analyzer.analyze(
        records: [mark('08:00', 'E'), mark('08:01', 'E', ci: '00123')],
        configuration: config(),
        employees: [employee('123'), employee('123', id: 'e2')]);
    expect(report.employees.every((e) => e.employee == null), isTrue);
    expect(
        report.employees
            .singleWhere((e) => e.identifier == '123')
            .identityMessage,
        contains('Más de un'));
  });
  test('Archivo vacío devuelve reporte vacío sin período artificial', () async {
    final report = await analyzer.analyze(records: [], configuration: config());
    expect(report.employees, isEmpty);
    expect(report.start, isNull);
  });
  test('Configuración rechaza horarios inválidos y códigos ambiguos', () {
    AttendanceConfiguration parse(String schedule,
            {String entry = 'E', String exit = 'S'}) =>
        const AttendanceConfigurationParser().parse(
            schedule: schedule,
            weekdays: {1},
            toleranceMinutes: '5',
            duplicateMinutes: '5',
            matchingMinutes: '90',
            typeField: BiometricTypeField.field4,
            entryCodes: entry,
            exitCodes: exit);
    expect(parse('08:00 E\n18:00 S').expectedMarks.length, 2);
    expect(() => parse('25:00 E'), throwsFormatException);
    expect(() => parse('18:00 S\n08:00 E'), throwsFormatException);
    expect(() => parse('08:00 E', exit: 'E'), throwsFormatException);
  });
}
