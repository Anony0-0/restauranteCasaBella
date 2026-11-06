import 'package:flutter/material.dart';

import '../controllers/reserva_controller.dart';
import 'reserva_mesas.dart';

class ReservasPage extends StatefulWidget {
  final String atendente;

  const ReservasPage({super.key, required this.atendente});

  @override
  State<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends State<ReservasPage> {
  final _controller = ReservaController();
  final _buscaController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _reservasFuture;

  @override
  void initState() {
    super.initState();
    _reservasFuture = _controller.pesquisar('');
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _pesquisar(String nome) {
    final future = _controller.pesquisar(nome);
    setState(() {
      _reservasFuture = future;
    });
  }

  Future<void> _selecionarReserva(Map<String, dynamic> reserva) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReservaMesasPage(reserva: reserva, atendente: widget.atendente),
      ),
    );
    if (mounted) _pesquisar(_buscaController.text);
  }

  String _dataHorario(dynamic valor) {
    final data = DateTime.tryParse(valor?.toString() ?? '');
    if (data == null) return 'Horário não informado';
    final local = data.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${local.year} • $hora:$minuto';
  }

  String _statusLabel(String status) => switch (status.toLowerCase()) {
    'pendente' => 'Pendente',
    'confirmada' => 'Confirmada',
    'em_andamento' || 'aberto' => 'Em atendimento',
    'concluida' => 'Concluída',
    'cancelada' => 'Cancelada',
    _ => status.isEmpty ? 'Sem status' : status,
  };

  Color _statusColor(String status) => switch (status.toLowerCase()) {
    'confirmada' || 'em_andamento' || 'aberto' => const Color(0xFF47634A),
    'concluida' || 'cancelada' => Colors.black45,
    _ => const Color(0xFFB17B36),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reservas')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _buscaController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Buscar pelo nome do cliente',
                  hintText: 'Digite o nome ou parte dele',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Limpar busca',
                    onPressed: () {
                      _buscaController.clear();
                      _pesquisar('');
                    },
                    icon: const Icon(Icons.close),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: _pesquisar,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _reservasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Não foi possível carregar as reservas.'),
                    );
                  }
                  final reservas = snapshot.data ?? const [];
                  if (reservas.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma reserva encontrada.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: reservas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final reserva = reservas[index];
                      final nome =
                          reserva['nome_cliente']?.toString() ??
                          'Cliente sem nome';
                      final status = reserva['status']?.toString() ?? '';
                      final pessoas =
                          (reserva['qtd_pessoas'] as num?)?.toInt() ?? 0;
                      final inativa = const {
                        'concluida',
                        'cancelada',
                      }.contains(status.toLowerCase());
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFF5E8E8),
                            child: Icon(
                              Icons.event_seat_outlined,
                              color: Color(0xFF7B1E2B),
                            ),
                          ),
                          title: Text(
                            nome,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_dataHorario(reserva['horario'])),
                                Text(
                                  '$pessoas ${pessoas == 1 ? 'pessoa' : 'pessoas'}',
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Icon(
                            inativa
                                ? Icons.check_circle_outline
                                : Icons.chevron_right,
                            color: inativa
                                ? Colors.black38
                                : const Color(0xFF7B1E2B),
                          ),
                          enabled: !inativa,
                          onTap: inativa
                              ? null
                              : () => _selecionarReserva(reserva),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
