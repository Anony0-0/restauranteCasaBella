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

  group('Autenticação de colaboradores por CPF', () {
    test('cadastra e autentica com CPF formatado ou sem pontuação', () async {
      final erro = await controller.cadastrar(
        nome: 'Ana Colaboradora',
        cpf: '529.982.247-25',
        senha: 'senha123',
      );

      expect(erro, isNull);
      expect(
        await controller.entrar(cpf: '52998224725', senha: 'senha123'),
        containsPair('cpf', '52998224725'),
      );
      expect(
        (await controller.entrar(
          cpf: '52998224725',
          senha: 'senha123',
        ))?['cargo'],
        'Gerente',
      );
    });

    test('rejeita CPF inválido no cadastro', () async {
      expect(
        await controller.cadastrar(
          nome: 'Ana Colaboradora',
          cpf: '111.111.111-11',
          senha: 'senha123',
        ),
        'Informe um CPF válido.',
      );
    });

    test('impede cadastro duplicado do mesmo CPF', () async {
      await controller.cadastrar(
        nome: 'Ana Colaboradora',
        cpf: '529.982.247-25',
        senha: 'senha123',
      );

      expect(
        await controller.cadastrar(
          nome: 'Outra pessoa',
          cpf: '52998224725',
          senha: 'senha123',
        ),
        'Já existe uma conta cadastrada com este CPF.',
      );
    });

    test('novos cadastros recebem perfil atendente', () async {
      await controller.cadastrar(
        nome: 'Gerente Casa Bella',
        cpf: '529.982.247-25',
        senha: 'senha123',
      );
      await controller.cadastrar(
        nome: 'Bruna Atendente',
        cpf: '111.444.777-35',
        senha: 'senha123',
      );

      expect(
        (await controller.entrar(
          cpf: '11144477735',
          senha: 'senha123',
        ))?['cargo'],
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
        expect(await controller.temColaboradores(), isTrue);
      },
    );

    test(
      'gerente remove atendente sem expor hash da senha na listagem',
      () async {
        await controller.cadastrar(
          nome: 'Gerente Casa Bella',
          cpf: '529.982.247-25',
          senha: 'senha123',
        );
        await controller.cadastrar(
          nome: 'Bruna Atendente',
          cpf: '111.444.777-35',
          senha: 'senha123',
        );

        final equipeAntes = await controller.listarColaboradores();
        expect(equipeAntes, hasLength(2));
        expect(equipeAntes.first.keys, isNot(contains('senhaHash')));

        expect(
          await controller.removerColaborador(
            cpfResponsavel: '52998224725',
            cpfColaborador: '11144477735',
          ),
          isNull,
        );
        expect(await controller.listarColaboradores(), hasLength(1));
        expect(
          await controller.entrar(cpf: '11144477735', senha: 'senha123'),
          isNull,
        );
      },
    );

    test(
      'impede remoção sem autorização, da própria conta e do último gerente',
      () async {
        await controller.cadastrar(
          nome: 'Gerente Casa Bella',
          cpf: '529.982.247-25',
          senha: 'senha123',
        );
        await controller.cadastrar(
          nome: 'Bruna Atendente',
          cpf: '111.444.777-35',
          senha: 'senha123',
        );

        expect(
          await controller.removerColaborador(
            cpfResponsavel: '11144477735',
            cpfColaborador: '52998224725',
          ),
          contains('Somente um gerente'),
        );
        expect(
          await controller.removerColaborador(
            cpfResponsavel: '52998224725',
            cpfColaborador: '52998224725',
          ),
          contains('própria conta'),
        );
        expect(
          await controller.removerColaborador(
            cpfResponsavel: '52998224725',
            cpfColaborador: '11144477735',
          ),
          isNull,
        );
        expect(
          await controller.removerColaborador(
            cpfResponsavel: '52998224725',
            cpfColaborador: '52998224725',
          ),
          contains('própria conta'),
        );
      },
    );
  });
}
