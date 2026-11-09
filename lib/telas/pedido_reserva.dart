import 'package:flutter/material.dart';

import '../controllers/pedido_controller.dart';
import '../controllers/reserva_controller.dart';
import 'cardapio.dart';

class PedidoReservaPage extends StatefulWidget {
  final Map<String, dynamic> reserva;
  final Map<String, dynamic> pedido;

  const PedidoReservaPage({
    super.key,
    required this.reserva,
    required this.pedido,
  });

  @override
  State<PedidoReservaPage> createState() => _PedidoReservaPageState();
}

class _PedidoReservaPageState extends State<PedidoReservaPage> {
  final _controller = PedidoController();
  final _reservaController = ReservaController();
  late Map<String, dynamic> _pedido = Map<String, dynamic>.from(widget.pedido);
  bool _processando = false;

  int get _pedidoId => (_pedido['id_pedido'] as num).toInt();
  int get _reservaId =>
      (widget.reserva['id_reserva'] as num?)?.toInt() ??
      int.parse(widget.reserva['id_reserva'].toString());
  List<Map<String, dynamic>> get _itens =>
      (_pedido['itens'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
  double get _total => (_pedido['valor_total'] as num?)?.toDouble() ?? 0;

  String _dinheiro(num valor) =>
      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  String _statusLegivel(String? status) => switch (status?.toLowerCase()) {
    'aberto' => 'Pedido aberto',
    'pendente' || 'aguardando_envio' => 'Aguardando envio',
    'enviado' || 'somente_local' => 'Enviado para acompanhamento',
    'preparando' || 'em_preparo' || 'in_progress' => 'Em preparo',
    'pronto' || 'ready' => 'Pronto para servir',
    'entregue' || 'completed' => 'Entregue',
    'concluido' => 'Conta fechada',
    'cancelado' || 'cancelled' || 'canceled' => 'Cancelado',
    _ => status ?? 'Status não informado',
  };

  Future<void> _atualizarStatus() async {
    if (_processando) return;
    setState(() => _processando = true);
    try {
      await _controller.atualizarStatus(_pedido);
      final atualizado = await _controller.atualizarPedidoDoArmazenamento(
        _pedidoId,
      );
      if (mounted && atualizado != null) setState(() => _pedido = atualizado);
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível atualizar o status: $erro')),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _adicionarRodada() async {
    if (_processando) return;
    final itens = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => const CardapioPage(),
      ),
    );
    if (!mounted || itens == null || itens.isEmpty) return;
    setState(() => _processando = true);
    try {
      final atualizado = await _controller.adicionarItensAoPedido(
        pedidoId: _pedidoId,
        itens: itens,
      );
      if (mounted) setState(() => _pedido = atualizado);
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível adicionar a rodada: $erro')),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _salvarItens(List<Map<String, dynamic>> itens) async {
    if (_processando) return;
    setState(() => _processando = true);
    try {
      final atualizado = await _controller.alterar(_pedido, itens: itens);
      if (mounted) setState(() => _pedido = atualizado);
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível atualizar o pedido: $erro')),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _alterarQuantidade(int index, int delta) async {
    final itens = _itens;
    final atual = (itens[index]['quantidade'] as num?)?.toInt() ?? 1;
    if (atual + delta <= 0) {
      itens.removeAt(index);
    } else {
      itens[index]['quantidade'] = atual + delta;
    }
    await _salvarItens(itens);
  }

  Future<void> _removerItem(int index) async {
    final itens = _itens..removeAt(index);
    await _salvarItens(itens);
  }

  Future<void> _fecharConta() async {
    if (_processando || _itens.isEmpty) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fechar conta?'),
        content: Text(
          'Total da reserva: ${_dinheiro(_total)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar atendimento'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fechar pedido'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _processando = true);
    try {
      await _controller.fecharPedido(
        pedidoId: _pedidoId,
        reservaId: _reservaId,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível fechar a conta: $erro')),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itens = _itens;
    final status = _pedido['status']?.toString();
    final fechado = const {
      'concluido',
      'cancelado',
    }.contains(status?.toLowerCase());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimento da reserva'),
        actions: [
          IconButton(
            tooltip: 'Atualizar status',
            onPressed: _processando ? null : _atualizarStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF5E8E8),
                      child: Icon(Icons.receipt_long, color: Color(0xFF7B1E2B)),
                    ),
                    title: Text(
                      widget.reserva['nome_cliente']?.toString() ?? 'Cliente',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${_reservaController.formatarHorario(widget.reserva['horario'])} • ${(widget.reserva['qtd_pessoas'] as num?)?.toInt() ?? 0} pessoas\nReserva: ${_reservaController.rotuloStatus(widget.reserva['status']?.toString() ?? '')} • Pedido #$_pedidoId\n${_statusLegivel(status)}',
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),
              Expanded(
                child: itens.isEmpty
                    ? const Center(
                        child: Text(
                          'Pedido sem itens. Adicione a primeira rodada.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: itens.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = itens[index];
                          final quantidade =
                              (item['quantidade'] as num?)?.toInt() ?? 1;
                          final preco =
                              (item['preco_unitario'] as num?)?.toDouble() ??
                              (item['preco'] as num?)?.toDouble() ??
                              0;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.restaurant,
                                    color: Color(0xFF7B1E2B),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['nome']?.toString() ?? 'Produto',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${_dinheiro(preco)} cada • ${_dinheiro(preco * quantidade)}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Diminuir quantidade',
                                    onPressed: _processando || fechado
                                        ? null
                                        : () => _alterarQuantidade(index, -1),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text(
                                    '$quantidade',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Aumentar quantidade',
                                    onPressed: _processando || fechado
                                        ? null
                                        : () => _alterarQuantidade(index, 1),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  IconButton(
                                    tooltip: 'Remover item',
                                    onPressed: _processando || fechado
                                        ? null
                                        : () => _removerItem(index),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x16000000),
                        blurRadius: 12,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${itens.length} item(ns)',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          Text(
                            'Total  ${_dinheiro(_total)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7B1E2B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _processando || fechado
                                  ? null
                                  : _adicionarRodada,
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Nova rodada'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  _processando || fechado || itens.isEmpty
                                  ? null
                                  : _fecharConta,
                              icon: _processando
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.point_of_sale),
                              label: const Text('Fechar conta'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: const Color(0xFF7B1E2B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
