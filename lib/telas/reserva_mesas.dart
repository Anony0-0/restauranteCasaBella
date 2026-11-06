import 'package:flutter/material.dart';

import '../controllers/reserva_controller.dart';
import '../models/mesa.dart';
import 'pedido_reserva.dart';

class ReservaMesasPage extends StatefulWidget {
  final Map<String, dynamic> reserva;
  final String atendente;

  const ReservaMesasPage({
    super.key,
    required this.reserva,
    required this.atendente,
  });

  @override
  State<ReservaMesasPage> createState() => _ReservaMesasPageState();
}

class _ReservaMesasPageState extends State<ReservaMesasPage> {
  final _controller = ReservaController();
  late final Future<List<Mesa>> _mesasFuture = _controller.listarMesas();
  int? _mesaSelecionada;
  bool _processando = false;

  int get _reservaId => (widget.reserva['id_reserva'] as num).toInt();
  int get _pessoas => (widget.reserva['qtd_pessoas'] as num?)?.toInt() ?? 0;
  String get _status =>
      widget.reserva['status']?.toString().toLowerCase() ?? '';
  int? get _mesaAssociada => (widget.reserva['id_mesa'] as num?)?.toInt();

  bool _podeUsar(Mesa mesa) {
    if (_status == 'confirmada' && mesa.idMesa == _mesaAssociada) return true;
    return !_estaConfirmada && !mesa.reservado && mesa.capacidade >= _pessoas;
  }

  bool get _estaConfirmada => _status == 'confirmada';

  Future<void> _abrirAtendimento(int mesaId) async {
    if (_processando) return;
    setState(() => _processando = true);
    try {
      if (!_estaConfirmada) {
        await _controller.confirmar(reservaId: _reservaId, mesaId: mesaId);
      }
      final pedido = await _controller.abrirPedido(
        reservaId: _reservaId,
        mesaId: mesaId,
        atendente: widget.atendente,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PedidoReservaPage(reserva: widget.reserva, pedido: pedido),
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o atendimento: $erro')),
      );
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Selecionar mesa')),
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reserva['nome_cliente']?.toString() ?? 'Cliente',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Reserva para $_pessoas ${_pessoas == 1 ? 'pessoa' : 'pessoas'}',
                    ),
                    Text(
                      _estaConfirmada
                          ? 'Reserva confirmada'
                          : 'Escolha uma mesa disponível',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...mesas.map((mesa) {
              final selecionavel = _podeUsar(mesa);
              final selecionada = _mesaSelecionada == mesa.idMesa;
              final atribuida =
                  _estaConfirmada && mesa.idMesa == _mesaAssociada;
              return Card(
                color: selecionada ? const Color(0xFFFFF5F3) : null,
                child: ListTile(
                  leading: Icon(
                    Icons.table_restaurant,
                    color: selecionavel
                        ? const Color(0xFF47634A)
                        : Colors.black38,
                  ),
                  title: Text('Mesa ${mesa.idMesa}'),
                  subtitle: Text(
                    atribuida
                        ? '${mesa.capacidade} lugares • vinculada a esta reserva'
                        : '${mesa.capacidade} lugares${mesa.capacidade < _pessoas
                              ? ' • capacidade insuficiente'
                              : mesa.reservado
                              ? ' • ocupada'
                              : ' • disponível'}',
                  ),
                  trailing: Icon(
                    selecionada
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selecionada
                        ? const Color(0xFF7B1E2B)
                        : Colors.black38,
                  ),
                  enabled: selecionavel && !_processando,
                  onTap: selecionavel
                      ? () => setState(() => _mesaSelecionada = mesa.idMesa)
                      : null,
                ),
              );
            }),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _processando || _mesaSelecionada == null
                  ? null
                  : () => _abrirAtendimento(_mesaSelecionada!),
              icon: _processando
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long),
              label: Text(
                _processando
                    ? 'Abrindo pedido…'
                    : 'Confirmar mesa e acessar pedido',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: const Color(0xFF7B1E2B),
              ),
            ),
          ],
        );
      },
    ),
  );
}
