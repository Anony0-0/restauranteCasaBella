import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:casa_bella/repositories/local_repository.dart';
import 'package:casa_bella/servicos/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:casa_bella/telas/reservas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ApiService.client = MockClient((_) async => http.Response('[]', 200));
    await LocalRepository.limparDadosTestes();
  });

  tearDown(() {
    ApiService.client.close();
    ApiService.client = http.Client();
  });

  test('confirma reserva apenas quando a mesa atende a capacidade e não está ocupada', () async {
    final mesa = await LocalRepository.criarMesaTeste(capacidade: 4);
    final reserva = await LocalRepository.criarReserva(
      nomeCliente: 'Maria Souza',
      telefone: '11999990000',
      email: 'maria@example.com',
      qtdPessoas: 3,
      horario: DateTime.utc(2026, 11, 7, 20, 0),
    );

    final reservaConfirmada = await LocalRepository.confirmarReserva(
      reservaId: reserva['id_reserva'] as int,
      mesaId: mesa['id_mesa'] as int,
    );

    expect(reservaConfirmada['status'], 'confirmada');
    expect(reservaConfirmada['id_mesa'], mesa['id_mesa']);

    final outraReserva = await LocalRepository.criarReserva(
      nomeCliente: 'João Lima',
      telefone: '11988887777',
      email: 'joao@example.com',
      qtdPessoas: 2,
      horario: DateTime.utc(2026, 11, 7, 20, 30),
    );

    expect(
      () => LocalRepository.confirmarReserva(
        reservaId: outraReserva['id_reserva'] as int,
        mesaId: mesa['id_mesa'] as int,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'abre pedido direto para reserva da API sem mesa ou cópia local',
    () async {
      final pedido = await LocalRepository.abrirPedidoParaReserva(
        reserva: {
          'id_reserva': '45',
          'id_cliente': '12',
          'nome_cliente': 'Cliente da API',
          'status': 'confirmada',
        },
        atendente: 'Atendente A',
      );

      expect(pedido['id_reserva'], 45);
      expect(pedido['id_cliente'], 12);
      expect(pedido['id_mesa'], isNull);
      expect(pedido['mesa'], 'Atendimento por reserva');
      expect((await LocalRepository.listarPedidos()).single, pedido);
    },
  );

  test(
    'reutiliza o mesmo pedido aberto para a reserva e acumula novas rodadas',
    () async {
      final reserva = await LocalRepository.criarReserva(
        nomeCliente: 'Carlos Mendes',
        telefone: '11977776666',
        email: 'carlos@example.com',
        qtdPessoas: 4,
        horario: DateTime.utc(2026, 11, 8, 19, 30),
      );

      final primeiroPedido = await LocalRepository.abrirPedidoParaReserva(
        reserva: reserva,
        atendente: 'Atendente A',
      );
      expect(primeiroPedido['id_mesa'], isNull);

      final pedidoComEntrada = await LocalRepository.adicionarItensAoPedido(
        pedidoId: primeiroPedido['id_pedido'] as int,
        itens: [
          {'id_produto': 1, 'quantidade': 2, 'preco_unitario': 56.0},
        ],
      );

      final segundoPedido = await LocalRepository.abrirPedidoParaReserva(
        reserva: reserva,
        atendente: 'Atendente A',
      );

      expect(segundoPedido['id_pedido'], pedidoComEntrada['id_pedido']);
      expect(
        (await LocalRepository.listarPedidos())
            .where((pedido) => pedido['id_reserva'] == reserva['id_reserva'])
            .length,
        1,
      );

      final pedidoAtualizado = await LocalRepository.adicionarItensAoPedido(
        pedidoId: pedidoComEntrada['id_pedido'] as int,
        itens: [
          {
            'id_produto': 1,
            'nome': 'Entrada',
            'quantidade': 1,
            'preco_unitario': 56.0,
          },
          {'id_produto': 3, 'quantidade': 1, 'preco_unitario': 6.0},
        ],
      );

      expect(pedidoAtualizado['valor_total'], 174.0);
      final entrada = (pedidoAtualizado['itens'] as List).firstWhere(
        (item) => item['id_produto'] == 1,
      );
      expect(entrada['quantidade'], 3);

      final pedidoFechado = await LocalRepository.fecharPedido(
        pedidoId: pedidoComEntrada['id_pedido'] as int,
        reservaId: reserva['id_reserva'] as int,
      );

      expect(pedidoFechado['status'], 'concluido');
      final reservas = await LocalRepository.listarReservas();
      expect(
        reservas.firstWhere(
          (item) => item['id_reserva'] == reserva['id_reserva'],
        )['status'],
        'concluida',
      );
    },
  );

  testWidgets('atendente conclui o fluxo de reserva pelo aplicativo', (
    tester,
  ) async {
    final reserva = await LocalRepository.criarReserva(
      nomeCliente: 'Ana Ribeiro',
      telefone: '11999998888',
      email: 'ana@example.com',
      qtdPessoas: 2,
      horario: DateTime.utc(2026, 11, 7, 20),
    );
    ApiService.client = MockClient((request) async {
      if (request.url.path == '${Uri.parse(ApiService.apiRoot).path}/produtos') {
        return http.Response(
          jsonEncode([
            {
              'id_produto': 21,
              'categoria': 'Entradas',
              'nome': 'Bruschetta al Pomodoro',
              'descricao': 'Pão italiano, tomate, alho e manjericão.',
              'preco': 18.90,
              'disponibilidade': 'disponivel',
            },
          ]),
          200,
        );
      }

      return http.Response(
        jsonEncode([
          {
            'id_reserva': reserva['id_reserva'],
            'id_cliente': 12,
            'cliente': reserva['nome_cliente'],
            'horario': reserva['horario'],
            'qtd_pessoas': reserva['qtd_pessoas'],
            'status': reserva['status'],
          },
        ]),
        200,
      );
    });

    await tester.pumpWidget(
      const MaterialApp(home: ReservasPage(atendente: 'Atendente Teste')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana Ribeiro'), findsOneWidget);

    await tester.tap(find.text('Ana Ribeiro'));
    await tester.pumpAndSettle();
    expect(find.text('Atendimento da reserva'), findsOneWidget);
    expect(find.textContaining('2 pessoas'), findsOneWidget);
    expect(find.textContaining('Reserva: Pendente'), findsOneWidget);
    expect(
      find.text('Pedido sem itens. Adicione a primeira rodada.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Nova rodada'));
    await tester.pumpAndSettle();
    expect(find.text('Cardápio'), findsOneWidget);
    await tester.ensureVisible(find.text('Bruschetta al Pomodoro'));
    await tester.ensureVisible(find.text('Adicionar ao pedido').first);
    await tester.tap(find.text('Adicionar ao pedido').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar itens ao pedido'));
    await tester.pumpAndSettle();
    expect(find.text('Bruschetta al Pomodoro'), findsOneWidget);
    expect(find.textContaining('R\$ 18,90'), findsWidgets);

    await tester.tap(find.text('Fechar conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fechar pedido'));
    await tester.pumpAndSettle();

    final pedidos = await LocalRepository.listarPedidos();
    expect(pedidos, hasLength(1));
    expect(pedidos.single['id_reserva'], reserva['id_reserva']);
    expect(pedidos.single['status'], 'concluido');
    expect(pedidos.single['id_mesa'], isNull);

    final reservas = await LocalRepository.listarReservas();
    expect(reservas.single['status'], 'concluida');
  });
}
