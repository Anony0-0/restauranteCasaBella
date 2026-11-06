import 'package:casa_bella/repositories/local_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:casa_bella/telas/reservas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalRepository.limparDadosTestes();
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
    'reutiliza o mesmo pedido aberto para a reserva e acumula novas rodadas',
    () async {
      final mesa = await LocalRepository.criarMesaTeste(capacidade: 6);
      final reserva = await LocalRepository.criarReserva(
        nomeCliente: 'Carlos Mendes',
        telefone: '11977776666',
        email: 'carlos@example.com',
        qtdPessoas: 4,
        horario: DateTime.utc(2026, 11, 8, 19, 30),
      );

      await LocalRepository.confirmarReserva(
        reservaId: reserva['id_reserva'] as int,
        mesaId: mesa['id_mesa'] as int,
      );

      final primeiroPedido = await LocalRepository.abrirPedidoParaReserva(
        reservaId: reserva['id_reserva'] as int,
        mesaId: mesa['id_mesa'] as int,
        atendente: 'Atendente A',
      );

      final pedidoComEntrada = await LocalRepository.adicionarItensAoPedido(
        pedidoId: primeiroPedido['id_pedido'] as int,
        itens: [
          {'id_produto': 1, 'quantidade': 2, 'preco_unitario': 56.0},
        ],
      );

      final segundoPedido = await LocalRepository.abrirPedidoParaReserva(
        reservaId: reserva['id_reserva'] as int,
        mesaId: mesa['id_mesa'] as int,
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

    await tester.pumpWidget(
      const MaterialApp(home: ReservasPage(atendente: 'Atendente Teste')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana Ribeiro'), findsOneWidget);

    await tester.tap(find.text('Ana Ribeiro'));
    await tester.pumpAndSettle();
    expect(find.text('Selecionar mesa'), findsOneWidget);

    await tester.tap(find.text('Mesa 1'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Confirmar mesa e acessar pedido'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirmar mesa e acessar pedido'), findsOneWidget);
    await tester.tap(find.text('Confirmar mesa e acessar pedido'));
    await tester.pumpAndSettle();
    expect(find.text('Atendimento da reserva'), findsOneWidget);
    expect(
      find.text('Pedido sem itens. Adicione a primeira rodada.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Nova rodada'));
    await tester.pumpAndSettle();
    expect(find.text('Cardápio'), findsOneWidget);
    await tester.ensureVisible(find.text('Bruschetta al Pomodoro'));
    await tester.ensureVisible(find.text('Adicionar nesta rodada').first);
    await tester.tap(find.text('Adicionar nesta rodada').first);
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

    final reservas = await LocalRepository.listarReservas();
    expect(reservas.single['status'], 'concluida');
    final mesas = await LocalRepository.listarMesas();
    expect(
      mesas.firstWhere((mesa) => mesa['id_mesa'] == 1)['reservado'],
      false,
    );
  });
}
