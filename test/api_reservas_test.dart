import 'dart:convert';

import 'package:casa_bella/servicos/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() {
    ApiService.client.close();
    ApiService.client = http.Client();
  });

  test('confirma a reserva pelo endpoint identificado por ID', () async {
    http.Request? requisicao;
    ApiService.client = MockClient((request) async {
      requisicao = request;
      return http.Response('{"status":"Confirmada"}', 200);
    });

    await ApiService.confirmarReserva(73);

    expect(requisicao!.method, 'PUT');
    expect(
      requisicao!.url.path,
      '${Uri.parse(ApiService.baseUrl).path}/73/confirmar',
    );
  });

  test('altera horário e quantidade no endpoint da reserva', () async {
    http.Request? requisicao;
    ApiService.client = MockClient((request) async {
      requisicao = request;
      return http.Response('{}', 200);
    });
    final horario = DateTime(2026, 11, 10, 19, 30);

    await ApiService.alterarReserva(
      reservaId: 81,
      horario: horario,
      quantidadePessoas: 4,
    );

    expect(requisicao!.method, 'PUT');
    expect(requisicao!.url.path, '${Uri.parse(ApiService.baseUrl).path}/81');
    expect(jsonDecode(requisicao!.body), {
      'horario': horario.toIso8601String(),
      'qtd_pessoas': 4,
    });
    expect(requisicao!.headers['content-type'], contains('application/json'));
  });

  test('cancela a reserva no servidor pelo ID', () async {
    http.Request? requisicao;
    ApiService.client = MockClient((request) async {
      requisicao = request;
      return http.Response('{"status":"Cancelada"}', 200);
    });

    await ApiService.cancelarReserva(94);

    expect(requisicao!.method, 'DELETE');
    expect(requisicao!.url.path, '${Uri.parse(ApiService.baseUrl).path}/94');
  });

  test('reporta falha HTTP ao gerenciar reserva', () async {
    ApiService.client = MockClient(
      (_) async => http.Response('{"erro":"conflito"}', 409),
    );

    await expectLater(
      ApiService.confirmarReserva(17),
      throwsA(
        isA<Exception>().having(
          (erro) => erro.toString(),
          'status HTTP',
          contains('409'),
        ),
      ),
    );
  });

  test(
    'não considera cancelamento bem-sucedido quando a API rejeita conflito',
    () async {
      ApiService.client = MockClient(
        (_) async => http.Response('{"erro":"reserva já cancelada"}', 409),
      );

      await expectLater(
        ApiService.cancelarReserva(17),
        throwsA(
          isA<Exception>().having(
            (erro) => erro.toString(),
            'status HTTP',
            contains('409'),
          ),
        ),
      );
    },
  );
}
