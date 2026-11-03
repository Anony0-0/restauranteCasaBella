import 'package:flutter/material.dart';

import 'acompanhamento.dart';
import '../controllers/pedido_controller.dart';

class PedidoPage extends StatefulWidget {
  final String mesa;
  final int? mesaId;
  final String garcom;
  final List<Map<String, dynamic>> itens;

  const PedidoPage({
    super.key,
    required this.mesa,
    this.mesaId,
    required this.garcom,
    required this.itens,
  });

  @override
  State<PedidoPage> createState() => _PedidoPageState();
}

class _PedidoPageState extends State<PedidoPage> {
  late List<Map<String, dynamic>> itens;
  bool enviando = false;

  @override
  void initState() {
    super.initState();

    itens = widget.itens
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  double calcularTotal() {
    double total = 0;

    for (final item in itens) {
      total += (item['preco'] as double) * (item['quantidade'] as int);
    }

    return total;
  }

  void aumentarQuantidade(int index) {
    setState(() {
      itens[index]['quantidade']++;
    });
  }

  void diminuirQuantidade(int index) {
    setState(() {
      if (itens[index]['quantidade'] > 1) {
        itens[index]['quantidade']--;
      } else {
        itens.removeAt(index);
      }
    });
  }

  Future<void> enviarPedido() async {
    setState(() => enviando = true);
    final pedido = await PedidoController().enviar(
      mesa: widget.mesa,
      mesaId: widget.mesaId,
      atendente: widget.garcom,
      itens: itens,
    );
    if (!mounted) return;
    setState(() => enviando = false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AcompanhamentoPage(pedidos: [pedido])),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = calcularTotal();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E8),

      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1E2B),
        foregroundColor: Colors.white,
        title: const Text(
          'Meu Pedido',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              widget.mesa == 'Não informada'
                  ? 'Atendimento sem mesa definida'
                  : widget.mesa,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B1E2B),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Garçom: ${widget.garcom}',
              style: const TextStyle(color: Colors.black54),
            ),

            Text(
              '${itens.length} produto(s) no pedido',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: itens.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum produto no pedido.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: itens.length,

                      itemBuilder: (context, index) {
                        final item = itens[index];

                        final nome = item['nome'] as String;
                        final quantidade = item['quantidade'] as int;
                        final preco = item['preco'] as double;

                        final subtotal = quantidade * preco;

                        return Card(
                          color: Colors.white,
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),

                          child: Padding(
                            padding: const EdgeInsets.all(12),

                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Color(0xFFF3E2D8),
                                      child: Icon(
                                        Icons.restaurant,
                                        color: Color(0xFF7B1E2B),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Text(
                                        nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),

                                    Text(
                                      'R\$ ${subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7B1E2B),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,

                                  children: [
                                    const Text(
                                      'Quantidade:',
                                      style: TextStyle(color: Colors.black54),
                                    ),

                                    const SizedBox(width: 10),

                                    IconButton(
                                      onPressed: () {
                                        diminuirQuantidade(index);
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Color(0xFF7B1E2B),
                                      ),
                                    ),

                                    Text(
                                      '$quantidade',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    IconButton(
                                      onPressed: () {
                                        aumentarQuantidade(index);
                                      },
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Color(0xFF7B1E2B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(thickness: 1.5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                Text(
                  'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1E2B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed: itens.isEmpty || enviando ? null : enviarPedido,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1E2B),
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: enviando
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ENVIAR PARA A COZINHA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
