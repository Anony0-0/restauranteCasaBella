import 'dart:convert';

import 'package:casa_bella/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = AuthController();
  });

  group('Autenticação de colaboradores por ID de usuário', () {
    test('gera um ID no cadastro e autentica com ID e senha', () async {
      final resultado = await controller.cadastrar(
        nome: 'Ana Colaboradora',
        senha: 'senha123',
      );

      expect(resultado.erro, isNull);
      expect(resultado.idUsuario, 1);
      expect(
        await controller.entrar(idUsuario: '1', senha: 'senha123'),
        containsPair('id_usuario', '1'),
      );
      expect(
        (await controller.entrar(idUsuario: '1', senha: 'senha123'))?['cargo'],
        'Gerente',
      );
    });

    test('rejeita ID inválido no login', () async {
      expect(
        await controller.entrar(idUsuario: 'abc', senha: 'senha123'),
        isNull,
      );
      expect(
        await controller.entrar(idUsuario: '0', senha: 'senha123'),
        isNull,
      );
    });

    test('gera IDs diferentes para colaboradores cadastrados', () async {
      final primeiro = await controller.cadastrar(
        nome: 'Ana Colaboradora',
        senha: 'senha123',
      );
      final segundo = await controller.cadastrar(
        nome: 'Outra pessoa',
        senha: 'senha123',
      );

      expect(primeiro.idUsuario, 1);
      expect(segundo.idUsuario, 2);
    });

    test('novos cadastros recebem perfil atendente', () async {
      await controller.cadastrar(nome: 'Gerente Casa Bella', senha: 'senha123');
      await controller.cadastrar(nome: 'Bruna Atendente', senha: 'senha123');

      expect(
        (await controller.entrar(idUsuario: '2', senha: 'senha123'))?['cargo'],
        'Atendente',
      );
    });

    test(
      'migra equipe antiga atribuindo gestão ao primeiro cadastro',
      () async {
        SharedPreferences.setMockInitialValues({
          'casa_bella_colaboradores': [
            jsonEncode({
              'nome': 'Ana Colaboradora',
              'cpf': '52998224725',
              'cargo': 'Atendente',
              'salt': 'salt-legado',
              'senhaHash': 'hash-legado',
            }),
          ],
        });
        controller = AuthController();

        final colaboradores = await controller.listarColaboradores();

        expect(colaboradores.single['cargo'], 'Gerente');
        expect(colaboradores.single['id_usuario'], '1');
        expect(await controller.temColaboradores(), isTrue);
      },
    );

    test(
      'gerente remove atendente sem expor hash da senha na listagem',
      () async {
        await controller.cadastrar(
          nome: 'Gerente Casa Bella',
          senha: 'senha123',
        );
        await controller.cadastrar(nome: 'Bruna Atendente', senha: 'senha123');

        final equipeAntes = await controller.listarColaboradores();
        expect(equipeAntes, hasLength(2));
        expect(equipeAntes.first.keys, isNot(contains('senhaHash')));
        expect(equipeAntes.first.keys, contains('id_usuario'));

        expect(
          await controller.removerColaborador(
            idResponsavel: '1',
            idColaborador: '2',
          ),
          isNull,
        );
        expect(await controller.listarColaboradores(), hasLength(1));
        expect(
          await controller.entrar(idUsuario: '2', senha: 'senha123'),
          isNull,
        );
      },
    );

    test(
      'impede remoção sem autorização, da própria conta e do último gerente',
      () async {
        await controller.cadastrar(
          nome: 'Gerente Casa Bella',
          senha: 'senha123',
        );
        await controller.cadastrar(nome: 'Bruna Atendente', senha: 'senha123');

        expect(
          await controller.removerColaborador(
            idResponsavel: '2',
            idColaborador: '1',
          ),
          contains('Somente um gerente'),
        );
        expect(
          await controller.removerColaborador(
            idResponsavel: '1',
            idColaborador: '1',
          ),
          contains('própria conta'),
        );
        expect(
          await controller.removerColaborador(
            idResponsavel: '1',
            idColaborador: '2',
          ),
          isNull,
        );
        expect(
          await controller.removerColaborador(
            idResponsavel: '1',
            idColaborador: '1',
          ),
          contains('própria conta'),
        );
      },
    );
  });
}
