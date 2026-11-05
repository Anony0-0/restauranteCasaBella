import 'package:casa_bella/repositories/local_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alteração e cancelamento de pedidos', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('altera itens e recalcula o total do pedido', () async {
      final pedido = await LocalRepository.enviarPedido(
        mesa: 'Mesa 1',
        mesaId: 1,
        garcom: 'Ana',
        itens: [
          {'id_produto': 10, 'nome': 'Lasanha', 'preco': 25.0, 'quantidade': 1},
        ],
      );

      final atualizado = await LocalRepository.alterarPedido(
        pedido,
        itens: [
          {'id_produto': 10, 'nome': 'Lasanha', 'preco': 25.0, 'quantidade': 2},
        ],
      );

      expect(atualizado['valor_total'], 50.0);
      expect((atualizado['itens'] as List).single['quantidade'], 2);
      expect(
        (await LocalRepository.listarPedidos()).single['valor_total'],
        50.0,
      );
    });

    test('registra cancelamento e bloqueia pedidos prontos', () async {
      final pedido = await LocalRepository.enviarPedido(
        mesa: 'Mesa 2',
        mesaId: 2,
        garcom: 'Ana',
        itens: [
          {'id_produto': 11, 'nome': 'Ravioli', 'preco': 30.0, 'quantidade': 1},
        ],
      );
      expect(
        LocalRepository.podeAlterarPedido({'status': 'preparando'}),
        isTrue,
      );
      expect(
        LocalRepository.podeAlterarPedido({'status': 'in_progress'}),
        isTrue,
      );
      expect(
        LocalRepository.podeAlterarPedido({'status': 'status_desconhecido'}),
        isFalse,
      );

      final cancelado = await LocalRepository.cancelarPedido(
        pedido,
        motivo: 'Solicitação do consumidor',
      );

      expect(cancelado['status'], 'cancelado');
      expect(cancelado['motivoCancelamento'], 'Solicitação do consumidor');
      expect(LocalRepository.podeAlterarPedido(cancelado), isFalse);
      expect(LocalRepository.podeAlterarPedido({'status': 'ready'}), isFalse);
      expect(
        LocalRepository.podeAlterarPedido({'status': 'entregue'}),
        isFalse,
      );
    });
  });
}
