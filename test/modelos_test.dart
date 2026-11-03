import 'package:casa_bella/models/cliente.dart';
import 'package:casa_bella/models/item_pedido.dart';
import 'package:casa_bella/models/mesa.dart';
import 'package:casa_bella/models/pedido.dart';
import 'package:casa_bella/models/produto.dart';
import 'package:casa_bella/models/reserva.dart';
import 'package:casa_bella/models/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mapeamento dos modelos para o banco', () {
    test('produto respeita as colunas da tabela produtos', () {
      const produto = Produto(
        idProduto: 12,
        categoria: 'Massas',
        nome: 'Ravioli',
        descricao: 'Ricota e sálvia',
        preco: 41.9,
        imagem: 'ravioli.png',
        disponivel: false,
      );

      expect(produto.toMap(), {
        'id_produto': 12,
        'categoria': 'Massas',
        'nome': 'Ravioli',
        'descricao': 'Ricota e sálvia',
        'preco': 41.9,
        'imagem': 'ravioli.png',
        'disponibilidade': 0,
      });
      expect(Produto.fromMap(produto.toMap()).disponivel, isFalse);
    });

    test('produto aceita ENUM MySQL e disponibilidade BIT/boolean', () {
      final disponivel = Produto.fromMap({
        'id_produto': '7',
        'categoria': 'Massas',
        'nome': 'Carbonara',
        'descricao': 'Massa italiana',
        'preco': '56.00',
        'disponibilidade': 'disponivel',
      });
      final indisponivel = Produto.fromMap({
        'id_produto': 8,
        'disponibilidade': 'indisponivel',
      });

      expect(disponivel.idProduto, 7);
      expect(disponivel.preco, 56.0);
      expect(disponivel.disponivel, isTrue);
      expect(disponivel.toMySqlMap()['disponibilidade'], 'disponivel');
      expect(indisponivel.disponivel, isFalse);
      expect(Produto.fromMap({'disponibilidade': true}).disponivel, isTrue);
    });

    test('reserva mantém as chaves estrangeiras e horário', () {
      final reserva = Reserva(
        idReserva: 3,
        clienteId: 7,
        telefone: '11999990000',
        email: 'cliente@example.com',
        horario: DateTime.utc(2026, 10, 26, 19),
        quantidadePessoas: 4,
        mesaId: 2,
      );

      expect(reserva.toMap()['id_cliente'], 7);
      expect(reserva.toMap()['id_mesa'], 2);
      expect(Reserva.fromMap(reserva.toMap()).horario, reserva.horario);
    });

    test('item de pedido calcula subtotal e converte colunas', () {
      const item = ItemPedido(
        pedidoId: 9,
        produtoId: 12,
        quantidade: 3,
        precoUnitario: 21.5,
      );

      expect(item.subtotal, 64.5);
      expect(ItemPedido.fromMap(item.toMap()).produtoId, 12);
    });

    test('item reconhece preco_uni e emite chave MySQL', () {
      final item = ItemPedido.fromMap({
        'id_pedido': '9',
        'id_produto': '12',
        'quantidade': '3',
        'preco_uni': '21.50',
      });

      expect(item.subtotal, 64.5);
      expect(item.toMySqlMap()['preco_uni'], 21.5);
      expect(item.toMySqlMap(), isNot(contains('preco_unitario')));
    });

    test('mesa aceita boolean MySQL e inteiros serializados', () {
      final mesa = Mesa.fromMap({
        'id_mesa': '2',
        'capacidade': '4',
        'reservado': true,
      });

      expect(mesa.idMesa, 2);
      expect(mesa.capacidade, 4);
      expect(mesa.reservado, isTrue);
    });

    test('pedido calcula total a partir dos itens e preserva FKs', () {
      final pedido = Pedido(
        idPedido: 9,
        clienteId: 7,
        mesaId: 2,
        dataPedido: DateTime.utc(2026, 10, 26),
        status: 'aberto',
        valorTotal: 64.5,
        itens: const [
          ItemPedido(
            pedidoId: 9,
            produtoId: 12,
            quantidade: 3,
            precoUnitario: 21.5,
          ),
        ],
      );

      expect(pedido.toMap()['id_cliente'], 7);
      expect(pedido.toMap()['id_mesa'], 2);
      expect(Pedido.fromMap(pedido.toMap()).itens.single.subtotal, 64.5);
    });

    test('cliente, usuário e mesa usam nomes de coluna do esquema', () {
      expect(
        const Cliente(
          nome: 'Ana',
          email: 'ana@example.com',
          telefone: '11',
        ).toMap().keys,
        containsAll(['id_cliente', 'nome', 'email', 'senha', 'telefone']),
      );
      expect(
        const Usuario(
          cpf: '52998224725',
          nome: 'Equipe',
          senhaHash: 'hash',
          cargo: 'Atendente',
        ).toMap()..remove('admissao'),
        {
          'id_usuario': null,
          'cpf': '52998224725',
          'email': null,
          'nome': 'Equipe',
          'senha': 'hash',
          'cargo': 'Atendente',
        },
      );
      expect(const Mesa(idMesa: 4, capacidade: 4).toMap()['id_mesa'], 4);
    });
  });
}
