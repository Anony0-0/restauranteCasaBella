import 'package:casa_bella/controllers/catalogo_controller.dart';
import 'package:casa_bella/servicos/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() {
    ApiService.client.close();
    ApiService.client = http.Client();
  });

  test('carrega produtos da API preservando o ID do banco', () async {
    http.Request? requisicao;
    ApiService.client = MockClient((request) async {
      requisicao = request;
      return http.Response(
        '[{"id_produto":42,"categoria":"Massas","nome":"Carbonara",'
        '"descricao":"Massa italiana","preco":32.5,'
        '"disponibilidade":"disponivel"}]',
        200,
      );
    });

    final produtos = await CatalogoController().listar();

    expect(requisicao!.method, 'GET');
    expect(
      requisicao!.url.path,
      '${Uri.parse(ApiService.apiRoot).path}/produtos',
    );
    expect(produtos, hasLength(1));
    expect(produtos.single.idProduto, 42);
    expect(produtos.single.nome, 'Carbonara');
    expect(produtos.single.disponivel, isTrue);
  });

  test('rejeita produto sem ID real do banco', () async {
    ApiService.client = MockClient(
      (_) async => http.Response(
        '[{"categoria":"Massas","nome":"Carbonara","preco":32.5}]',
        200,
      ),
    );

    await expectLater(
      CatalogoController().listar(),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'rejeita produto com preço inválido ou disponibilidade ausente',
    () async {
      ApiService.client = MockClient(
        (_) async => http.Response(
          '[{"id_produto":42,"categoria":"Massas","nome":"Carbonara",'
          '"preco":"inválido","disponibilidade":"disponivel"}]',
          200,
        ),
      );

      await expectLater(
        CatalogoController().listar(),
        throwsA(isA<FormatException>()),
      );

      ApiService.client.close();
      ApiService.client = MockClient(
        (_) async => http.Response(
          '[{"id_produto":42,"categoria":"Massas","nome":"Carbonara",'
          '"preco":32.5}]',
          200,
        ),
      );

      await expectLater(
        CatalogoController().listar(),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('preserva produtos indisponíveis para informar a tela', () async {
    ApiService.client = MockClient(
      (_) async => http.Response(
        '[{"id_produto":42,"categoria":"Massas","nome":"Carbonara",'
        '"descricao":"Massa italiana","preco":32.5,'
        '"disponibilidade":"indisponivel"}]',
        200,
      ),
    );

    final produtos = await CatalogoController().listar();

    expect(produtos.single.disponivel, isFalse);
  });
}
