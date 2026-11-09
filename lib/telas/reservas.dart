import 'package:flutter/material.dart';

import '../controllers/reserva_controller.dart';
import 'pedido_reserva.dart';

enum _AcaoReserva { atender, confirmar, alterar, cancelar }

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
  String? _reservaAbrindo;
  String? _reservaEmOperacao;

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
    if (_reservaAbrindo != null || _reservaEmOperacao != null) return;
    setState(
      () => _reservaAbrindo = reserva['id_reserva']?.toString() ?? 'inválida',
    );
    try {
      final pedido = await _controller.abrirPedido(
        reserva: reserva,
        atendente: widget.atendente,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PedidoReservaPage(reserva: reserva, pedido: pedido),
        ),
      );
      if (mounted) _pesquisar(_buscaController.text);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o atendimento: $erro')),
      );
    } finally {
      if (mounted) setState(() => _reservaAbrindo = null);
    }
  }

  int? _idDaReserva(Map<String, dynamic> reserva) {
    final id = reserva['id_reserva'];
    return id is num ? id.toInt() : int.tryParse(id?.toString() ?? '');
  }

  Future<void> _executarAcao({
    required Map<String, dynamic> reserva,
    required Future<void> Function(int id) executar,
    required String sucesso,
  }) async {
    if (_reservaEmOperacao != null || _reservaAbrindo != null) return;
    final id = _idDaReserva(reserva);
    if (id == null || id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A reserva não possui um ID válido.')),
      );
      return;
    }

    setState(() => _reservaEmOperacao = id.toString());
    try {
      await executar(id);
      if (!mounted) return;
      _pesquisar(_buscaController.text);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(sucesso)));
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $erro')));
    } finally {
      if (mounted) setState(() => _reservaEmOperacao = null);
    }
  }

  Future<void> _confirmarReserva(Map<String, dynamic> reserva) async {
    if (reserva['status']?.toString().toLowerCase() != 'pendente') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Somente reservas pendentes podem ser confirmadas.'),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar reserva?'),
        content: Text(
          'Deseja confirmar a reserva de '
          '${reserva['nome_cliente']?.toString() ?? 'Cliente'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar reserva'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    await _executarAcao(
      reserva: reserva,
      executar: _controller.confirmar,
      sucesso: 'Reserva confirmada.',
    );
  }

  Future<void> _cancelarReserva(Map<String, dynamic> reserva) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reserva?'),
        content: Text(
          'Deseja cancelar a reserva de '
          '${reserva['nome_cliente']?.toString() ?? 'Cliente'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Manter reserva'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    await _executarAcao(
      reserva: reserva,
      executar: _controller.cancelar,
      sucesso: 'Reserva cancelada.',
    );
  }

  Future<void> _alterarReserva(Map<String, dynamic> reserva) async {
    final horarioAtual = DateTime.tryParse(
      reserva['horario']?.toString() ?? '',
    );
    if (horarioAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível interpretar o horário da reserva.'),
        ),
      );
      return;
    }

    final pessoasAtual =
        (reserva['qtd_pessoas'] as num?)?.toInt() ??
        int.tryParse(reserva['qtd_pessoas']?.toString() ?? '') ??
        1;
    var quantidadePessoas = pessoasAtual;
    var dataSelecionada = horarioAtual;
    var horaSelecionada = TimeOfDay.fromDateTime(horarioAtual);

    final alteracao = await showDialog<({DateTime horario, int pessoas})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizarDialog) => AlertDialog(
          title: const Text('Alterar reserva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final selecionada = await showDatePicker(
                    context: context,
                    initialDate: dataSelecionada,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selecionada != null) {
                    atualizarDialog(() => dataSelecionada = selecionada);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  '${dataSelecionada.day.toString().padLeft(2, '0')}/'
                  '${dataSelecionada.month.toString().padLeft(2, '0')}/'
                  '${dataSelecionada.year}',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final selecionada = await showTimePicker(
                    context: context,
                    initialTime: horaSelecionada,
                  );
                  if (selecionada != null) {
                    atualizarDialog(() => horaSelecionada = selecionada);
                  }
                },
                icon: const Icon(Icons.access_time),
                label: Text(horaSelecionada.format(context)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: pessoasAtual.toString(),
                onChanged: (valor) {
                  final quantidade = int.tryParse(valor.trim());
                  atualizarDialog(() => quantidadePessoas = quantidade ?? 0);
                },
                decoration: InputDecoration(labelText: 'Quantidade de pessoas'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () {
                if (quantidadePessoas <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Informe uma quantidade de pessoas maior que zero.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, (
                  horario: DateTime(
                    dataSelecionada.year,
                    dataSelecionada.month,
                    dataSelecionada.day,
                    horaSelecionada.hour,
                    horaSelecionada.minute,
                  ),
                  pessoas: quantidadePessoas,
                ));
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (alteracao == null || !mounted) return;

    await _executarAcao(
      reserva: reserva,
      executar: (id) => _controller.alterar(
        reservaId: id,
        horario: alteracao.horario,
        quantidadePessoas: alteracao.pessoas,
      ),
      sucesso: 'Reserva atualizada.',
    );
  }

  void _selecionarAcao(_AcaoReserva acao, Map<String, dynamic> reserva) {
    switch (acao) {
      case _AcaoReserva.atender:
        _selecionarReserva(reserva);
      case _AcaoReserva.confirmar:
        _confirmarReserva(reserva);
      case _AcaoReserva.alterar:
        _alterarReserva(reserva);
      case _AcaoReserva.cancelar:
        _cancelarReserva(reserva);
    }
  }

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
                              Icons.event_available_outlined,
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
                                Text(
                                  _controller.formatarHorario(
                                    reserva['horario'],
                                  ),
                                ),
                                Text(
                                  '$pessoas ${pessoas == 1 ? 'pessoa' : 'pessoas'}',
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _controller.rotuloStatus(status),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing:
                              _reservaAbrindo ==
                                      reserva['id_reserva']?.toString() ||
                                  _reservaEmOperacao ==
                                      reserva['id_reserva']?.toString()
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : inativa
                              ? const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.black38,
                                )
                              : PopupMenuButton<_AcaoReserva>(
                                  tooltip: 'Opções da reserva',
                                  onSelected: (acao) =>
                                      _selecionarAcao(acao, reserva),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: _AcaoReserva.atender,
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(Icons.receipt_long),
                                        title: Text('Iniciar atendimento'),
                                      ),
                                    ),
                                    if (status.toLowerCase() == 'pendente')
                                      const PopupMenuItem(
                                        value: _AcaoReserva.confirmar,
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            Icons.event_available_outlined,
                                          ),
                                          title: Text('Confirmar reserva'),
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: _AcaoReserva.alterar,
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(Icons.edit_outlined),
                                        title: Text('Alterar reserva'),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: _AcaoReserva.cancelar,
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(Icons.cancel_outlined),
                                        title: Text('Cancelar reserva'),
                                      ),
                                    ),
                                  ],
                                ),
                          enabled:
                              !inativa &&
                              _reservaAbrindo == null &&
                              _reservaEmOperacao == null,
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
