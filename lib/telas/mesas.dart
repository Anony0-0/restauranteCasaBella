import 'package:flutter/material.dart';

import '../controllers/mesa_controller.dart';
import '../models/mesa.dart';
import 'cardapio.dart';

class MesasPage extends StatefulWidget {
  final String garcom;

  const MesasPage({super.key, required this.garcom});

  @override
  State<MesasPage> createState() => _MesasPageState();
}

class _MesasPageState extends State<MesasPage> {
  final _controller = MesaController();
  late final Future<List<Mesa>> _mesasFuture = _controller.listar();
  int? _mesaSelecionada;
  bool _balcaoSelecionado = false;

  void _abrirCardapio({required String mesa, int? mesaId}) {
    if (!_balcaoSelecionado && _mesaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma mesa ou o balcão.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CardapioPage(mesa: mesa, mesaId: mesaId, garcom: widget.garcom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Escolha o atendimento')),
    body: FutureBuilder<List<Mesa>>(
      future: _mesasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('Não foi possível carregar as mesas.'),
          );
        }
        final mesas = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final colunas = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 560
                ? 3
                : 2;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B1E2B), Color(0xFF4E1420)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.table_restaurant,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Onde será servido?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Selecione uma mesa para ${widget.garcom} iniciar o pedido.',
                        style: const TextStyle(color: Color(0xFFEADADD)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MESAS DISPONÍVEIS',
                  style: TextStyle(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF726B67),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mesas.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: colunas,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth < 380 ? 1.12 : 1.28,
                  ),
                  itemBuilder: (context, index) {
                    final mesa = mesas[index];
                    final selecionada = _mesaSelecionada == mesa.idMesa;
                    return _MesaCard(
                      mesa: mesa,
                      selecionada: selecionada,
                      onTap: mesa.reservado
                          ? null
                          : () => setState(() {
                              _mesaSelecionada = mesa.idMesa;
                              _balcaoSelecionado = false;
                            }),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Card(
                  child: InkWell(
                    onTap: () => setState(() {
                      _balcaoSelecionado = true;
                      _mesaSelecionada = null;
                    }),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF5E8E8),
                          child: Icon(
                            Icons.takeout_dining,
                            color: Color(0xFF7B1E2B),
                          ),
                        ),
                        title: const Text(
                          'Balcão / retirada',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text('Pedido sem mesa vinculada'),
                        trailing: Icon(
                          _balcaoSelecionado
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _balcaoSelecionado
                              ? const Color(0xFF7B1E2B)
                              : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _balcaoSelecionado
                      ? () => _abrirCardapio(mesa: 'Balcão')
                      : _mesaSelecionada == null
                      ? null
                      : () => _abrirCardapio(
                          mesa: 'Mesa $_mesaSelecionada',
                          mesaId: _mesaSelecionada,
                        ),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('ABRIR CARDÁPIO'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFF7B1E2B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}

class _MesaCard extends StatelessWidget {
  final Mesa mesa;
  final bool selecionada;
  final VoidCallback? onTap;

  const _MesaCard({required this.mesa, required this.selecionada, this.onTap});

  @override
  Widget build(BuildContext context) {
    final indisponivel = mesa.reservado;
    final cor = indisponivel
        ? const Color(0xFF89827E)
        : selecionada
        ? const Color(0xFF7B1E2B)
        : const Color(0xFF4F6B52);
    return Card(
      color: selecionada ? const Color(0xFFFFF5F3) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selecionada
              ? const Color(0xFF7B1E2B)
              : const Color(0xFFEFEAE5),
          width: selecionada ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.table_restaurant, color: cor, size: 28),
              const SizedBox(height: 8),
              Text(
                'Mesa ${mesa.idMesa}',
                style: TextStyle(fontWeight: FontWeight.w700, color: cor),
              ),
              const SizedBox(height: 3),
              Text(
                '${mesa.capacidade} lugares',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (indisponivel)
                const Text(
                  'Reservada',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
