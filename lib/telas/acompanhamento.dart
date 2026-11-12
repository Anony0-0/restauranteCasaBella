import 'package:flutter/material.dart';

import '../controllers/pedido_controller.dart';

class AcompanhamentoPage extends StatefulWidget {
  final List<Map<String, dynamic>> pedidos;

  const AcompanhamentoPage({super.key, required this.pedidos});

  @override
  State<AcompanhamentoPage> createState() => _AcompanhamentoPageState();
}

class _AcompanhamentoPageState extends State<AcompanhamentoPage> {
  late List<Map<String, dynamic>> pedidos;
  final Set<String> consultando = {};

  @override
  void initState() {
    super.initState();
    pedidos = widget.pedidos.map(Map<String, dynamic>.from).toList();
  }

  Future<void> consultarStatus(int index) async {
    final pedido = pedidos[index];
    final id = (pedido['id'] ?? pedido['id_pedido'] ?? 'pedido').toString();
    setState(() => consultando.add(id));
    try {
      final atualizado = await PedidoController().atualizarStatus(pedido);
      if (!mounted) return;
      setState(() => pedidos[index] = atualizado);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível consultar o pedido: $erro')),
      );
    } finally {
      if (mounted) setState(() => consultando.remove(id));
    }
  }

  Future<void> editarPedido(int index) async {
    final pedido = pedidos[index];
    final itensOriginais = pedido['itens'] as List<dynamic>? ?? [];
    final resultado = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) {
        final itensEditados = itensOriginais
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        return StatefulBuilder(
          builder: (context, atualizarDialogo) => AlertDialog(
            title: const Text('Alterar pedido'),
            content: SizedBox(
              width: 420,
              child: itensEditados.isEmpty
                  ? const Text('Adicione ao menos um item ao pedido.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: itensEditados.length,
                      itemBuilder: (context, itemIndex) {
                        final item = itensEditados[itemIndex];
                        final quantidade = (item['quantidade'] as num? ?? 1)
                            .toInt();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['nome']?.toString() ?? 'Item'),
                          subtitle: Text('Quantidade: $quantidade'),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                tooltip: 'Diminuir quantidade',
                                onPressed: quantidade > 1
                                    ? () => atualizarDialogo(() {
                                        item['quantidade'] = quantidade - 1;
                                      })
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              IconButton(
                                tooltip: 'Aumentar quantidade',
                                onPressed: () => atualizarDialogo(() {
                                  item['quantidade'] = quantidade + 1;
                                }),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              IconButton(
                                tooltip: 'Remover item',
                                onPressed: () => atualizarDialogo(
                                  () => itensEditados.removeAt(itemIndex),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
              FilledButton(
                onPressed: itensEditados.isEmpty
                    ? null
                    : () => Navigator.pop(
                        context,
                        itensEditados
                            .map((item) => Map<String, dynamic>.from(item))
                            .toList(),
                      ),
                child: const Text('Salvar alteração'),
              ),
            ],
          ),
        );
      },
    );
    if (resultado == null || !mounted) return;

    final id = pedido['id'].toString();
    setState(() => consultando.add(id));
    try {
      final atualizado = await PedidoController().alterar(
        pedido,
        itens: resultado,
      );
      if (!mounted) return;
      setState(() => pedidos[index] = atualizado);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido alterado com sucesso.')),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível alterar: $erro')),
      );
    } finally {
      if (mounted) setState(() => consultando.remove(id));
    }
  }

  Future<void> cancelarPedido(int index) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: const Text(
          'O cancelamento será registrado e enviado à cozinha quando a integração estiver configurada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Manter pedido'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final pedido = pedidos[index];
    final id = pedido['id'].toString();
    setState(() => consultando.add(id));
    try {
      final atualizado = await PedidoController().cancelar(pedido);
      if (!mounted) return;
      setState(() => pedidos[index] = atualizado);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado com sucesso.')),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível cancelar: $erro')),
      );
    } finally {
      if (mounted) setState(() => consultando.remove(id));
    }
  }

  String mensagemStatus(Map<String, dynamic> pedido) {
    switch (pedido['status']) {
      case 'enviado':
        return 'Enviado à cozinha • aguardando preparo';
      case 'somente_local':
        return 'Salvo neste dispositivo • integração Web não configurada';
      case 'falha_no_envio':
        return 'Falha no envio • pedido salvo localmente';
      case 'pronto':
      case 'ready':
        return 'Pronto para servir';
      case 'preparando':
      case 'in_progress':
        return 'A cozinha está preparando';
      case 'entregue':
      case 'completed':
        return 'Pedido concluído pela equipe';
      case 'cancelado':
      case 'cancelled':
      case 'canceled':
        return 'Pedido cancelado';
      default:
        return 'Status: ${pedido['status'] ?? 'Aguardando envio'}';
    }
  }

  Color corStatus(Map<String, dynamic> pedido) {
    switch (pedido['status']) {
      case 'pronto':
      case 'ready':
      case 'entregue':
      case 'completed':
        return Colors.green.shade700;
      case 'falha_no_envio':
      case 'cancelado':
      case 'cancelled':
      case 'canceled':
        return Colors.red.shade700;
      default:
        return const Color(0xFF7B1E2B);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Acompanhamento'),
      backgroundColor: const Color(0xFF7B1E2B),
      foregroundColor: Colors.white,
    ),
    body: pedidos.isEmpty
        ? const Center(child: Text('Ainda não há pedidos para acompanhar.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              final id = pedido['id'].toString();
              final podeAlterar = PedidoController().podeAlterar(pedido);
              final processando = consultando.contains(id);
              final itens = pedido['itens'] as List<dynamic>? ?? [];
              final mesa = pedido['mesa'] == 'Não informada'
                  ? 'Sem mesa definida'
                  : pedido['mesa'].toString();
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF7B1E2B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mesa,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '#${index + 1}',
                            style: const TextStyle(color: Colors.black45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Garçom: ${pedido['garcom'] ?? '—'}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const Divider(height: 22),
                      ...itens.map((item) {
                        final linha = item as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  linha['nome']?.toString() ?? 'Item',
                                ),
                              ),
                              Text('× ${linha['quantidade'] ?? 1}'),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: R\$ ${(pedido['valor_total'] as num? ?? 0).toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: corStatus(pedido).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          mensagemStatus(pedido),
                          style: TextStyle(
                            color: corStatus(pedido),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 4,
                        children: [
                          if (podeAlterar)
                            TextButton.icon(
                              onPressed: processando
                                  ? null
                                  : () => editarPedido(index),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Alterar'),
                            ),
                          if (podeAlterar)
                            TextButton.icon(
                              onPressed: processando
                                  ? null
                                  : () => cancelarPedido(index),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar'),
                            ),
                          TextButton.icon(
                            onPressed: processando
                                ? null
                                : () => consultarStatus(index),
                            icon: processando
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: const Text('Atualizar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
