import 'dart:convert';
import 'package:rrhh_api/rrhh_api.dart';
import 'package:dio/dio.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);
  final int status;
  final Object body;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<List<int>>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      });
}

void main() {
  for (final acceptStatus in [true, false]) {
    for (final entry in {
      'correspondencia_unavailable': 'Correspondencia no está disponible',
      'biometric_api_unavailable': 'La API biométrica no está disponible',
      'biometric_device_unreachable': 'el dispositivo está desconectado',
      'parameters_overlap': 'La vigencia se superpone',
      'unknown_private_code': 'No se pudo completar la operación',
    }.entries) {
      test('Error seguro ${entry.key}, validateStatus=$acceptStatus', () async {
        final dio = Dio(BaseOptions(
            baseUrl: 'http://localhost',
            validateStatus: acceptStatus ? (_) => true : null))
          ..httpClientAdapter = _Adapter(503, {
            'detail': {
              'code': entry.key,
              'message': 'PRIVATE SQL password=hidden'
            }
          });
        final result = await handleExceptions(
            () => ApiMethod(dio: dio).get('/rrhh/biometric/status'));
        final message =
            FailureGeneric.message(failure: result.failureOrNull()!);
        expect(message, contains(entry.value));
        expect(message, isNot(contains('PRIVATE')));
        dio.close();
      });
    }
  }
  test('Logs ocultan credenciales anidadas y Bearer de texto', () {
    final encoded = ApiLogger.encodePayload({
      'Authorization': 'Bearer PRIVATE',
      'nested': [
        {'set-cookie': 'PRIVATE', 'api_key': 'PRIVATE', 'password': 'PRIVATE'}
      ]
    });
    expect(encoded, isNot(contains('PRIVATE')));
    expect(ApiLogger.redactString('failed Bearer fixture.token-value'),
        'failed Bearer ***');
  });
  for (final acceptStatus in [true, false]) {
    test(
        '422 atraviesa API, Result y FailureGeneric (validateStatus=$acceptStatus)',
        () async {
      final dio = Dio(BaseOptions(
          baseUrl: 'http://localhost',
          validateStatus: acceptStatus ? (_) => true : null))
        ..httpClientAdapter = _Adapter(422, {
          'detail': [
            {
              'loc': ['body', 'username'],
              'type': 'missing',
              'msg': 'Field required',
              'input': 'SECRET_INPUT'
            },
            {
              'loc': ['body', 'password'],
              'type': 'string_too_short',
              'msg': 'INTERNAL_TRACE',
              'ctx': {'min_length': 12}
            },
          ]
        });
      final result =
          await handleExceptions(() => ApiMethod(dio: dio).post('/auth/login'));
      final failure = result.failureOrNull();
      expect(failure, isA<ValidationFailure>());
      expect(FailureGeneric.message(failure: failure!),
          'Usuario: Este campo es obligatorio.\nContraseña: El texto es demasiado corto.');
      dio.close();
    });
  }
  test('422 de dominio conserva mensaje útil', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = _Adapter(
          422, {'detail': 'Seleccione un funcionario destino específico.'});
    final result = await handleExceptions(
        () => ApiMethod(dio: dio).get('/institutional-mayor'));
    expect(result.failureOrNull()?.message,
        'Seleccione un funcionario destino específico.');
    dio.close();
  });
  test('respuesta cruda y errores técnicos no se muestran al usuario',
      () async {
    for (final status in [422, 500]) {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
        ..httpClientAdapter = _Adapter(status, 'TRACEBACK SQL password=secret');
      final result =
          await handleExceptions(() => ApiMethod(dio: dio).get('/admin/users'));
      expect(FailureGeneric.message(failure: result.failureOrNull()!),
          isNot(contains('secret')));
      dio.close();
    }
  });
}
