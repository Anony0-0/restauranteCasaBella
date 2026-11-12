import 'package:casa_bella/servicos/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() {
    ApiService.client.close();
    ApiService.client = http.Client();
  });

  test('converte falha de conexão em mensagem compreensível', () async {
    ApiService.client = MockClient(
      (_) async => throw http.ClientException('connection refused'),
    );

    await expectLater(
      ApiService.listarProdutos(),
      throwsA(
        isA<ApiException>().having(
          (erro) => erro.message,
          'mensagem',
          contains('Não foi possível conectar ao servidor'),
        ),
      ),
    );
  });

  test('rejeita resposta JSON inválida da API', () async {
    ApiService.client = MockClient(
      (_) async => http.Response('<html>erro</html>', 200),
    );

    await expectLater(
      ApiService.listarProdutos(),
      throwsA(
        isA<ApiException>().having(
          (erro) => erro.message,
          'mensagem',
          contains('resposta inválida'),
        ),
      ),
    );
  });

  test('rejeita lista com registros em formato inválido', () async {
    ApiService.client = MockClient(
      (_) async => http.Response('[{"id":1},null]', 200),
    );

    await expectLater(
      ApiService.listarProdutos(),
      throwsA(
        isA<ApiException>().having(
          (erro) => erro.message,
          'mensagem',
          contains('lista inválida'),
        ),
      ),
    );
  });

  test('usa mensagem HTTP compreensível sem expor corpo técnico', () async {
    ApiService.client = MockClient(
      (_) async => http.Response('<html>internal stack trace</html>', 500),
    );

    await expectLater(
      ApiService.listarReservas(),
      throwsA(
        isA<ApiException>()
            .having((erro) => erro.statusCode, 'status', 500)
            .having(
              (erro) => erro.message,
              'mensagem',
              allOf(
                contains('servidor encontrou um erro'),
                isNot(contains('internal stack trace')),
              ),
            ),
      ),
    );
  });

  test('rejeita resposta de login fora do formato objeto', () async {
    ApiService.client = MockClient((_) async => http.Response('[]', 200));

    await expectLater(
      ApiService.login(email: 'a@example.com', senha: 'senha'),
      throwsA(isA<ApiException>()),
    );
  });

  test('não trunca ID fracionário retornado ao criar pedido', () async {
    ApiService.client = MockClient(
      (_) async => http.Response('{"id_pedido":4.5}', 201),
    );

    await expectLater(
      ApiService.criarPedido(12),
      throwsA(
        isA<ApiException>().having(
          (erro) => erro.message,
          'mensagem',
          contains('ID de pedido válido'),
        ),
      ),
    );
  });
}
