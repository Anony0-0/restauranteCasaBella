import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mesa.dart';
import '../servicos/cozinha_service.dart';

/// Persistência local do app para mesas e pedidos.
class LocalRepository {
  static const _pedidosKey = 'casa_bella_pedidos';
  static const _mesasKey = 'casa_bella_mesas';
  static const _reservasKey = 'casa_bella_reservas';

  static Future<void> limparDadosTestes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pedidosKey);
    await prefs.remove(_mesasKey);
    await prefs.remove(_reservasKey);
  }

  static Future<Map<String, dynamic>> criarMesaTeste({
    required int capacidade,
  }) async {
    final mesas = await listarMesas();
    final id =
        (mesas
            .map((mesa) => (mesa['id_mesa'] as num?)?.toInt() ?? 0)
            .fold<int>(0, (maior, idMesa) => idMesa > maior ? idMesa : maior) +
        1);
    final mesa = <String, dynamic>{
      'id_mesa': id,
      'capacidade': capacidade,
      'reservado': false,
    };
    mesas.add(mesa);
    await _salvarMesas(mesas);
    return mesa;
  }

  static Future<List<Map<String, dynamic>>> listarReservas() async {
    final prefs = await SharedPreferences.getInstance();
    final reservas = (prefs.getStringList(_reservasKey) ?? [])
        .map((item) => Map<String, dynamic>.from(jsonDecode(item) as Map))
        .toList();
    reservas.sort((a, b) {
      final primeiro = a['horario']?.toString() ?? '';
      final segundo = b['horario']?.toString() ?? '';
      return segundo.compareTo(primeiro);
    });
    return reservas;
  }

  static Future<Map<String, dynamic>> criarReserva({
    required String nomeCliente,
    required String telefone,
    required String email,
    required int qtdPessoas,
    required DateTime horario,
    int? idMesa,
    String status = 'pendente',
  }) async {
    if (qtdPessoas <= 0) {
      throw ArgumentError(
        'A quantidade de pessoas precisa ser maior que zero.',
      );
    }
    final reservas = await listarReservas();
    final proximoId = reservas.isEmpty
        ? 1
        : (reservas
                  .map(
                    (reserva) => (reserva['id_reserva'] as num?)?.toInt() ?? 0,
                  )
                  .fold<int>(0, (maior, id) => id > maior ? id : maior) +
              1);
    final reserva = <String, dynamic>{
      'id_reserva': proximoId,
      'nome_cliente': nomeCliente.trim(),
      'telefone': telefone,
      'email': email,
      'horario': horario.toUtc().toIso8601String(),
      'qtd_pessoas': qtdPessoas,
      'id_mesa': idMesa,
      'status': status,
    };
    reservas.add(reserva);
    await _salvarReservas(reservas);
    return reserva;
  }

  static Future<List<Map<String, dynamic>>> pesquisarReservasPorNome(
    String nome,
  ) async {
    final filtro = nome.trim().toLowerCase();
    if (filtro.isEmpty) return listarReservas();
    final reservas = await listarReservas();
    return reservas
        .where(
          (item) => (item['nome_cliente']?.toString() ?? '')
              .toLowerCase()
              .contains(filtro),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> confirmarReserva({
    required int reservaId,
    required int mesaId,
  }) async {
    final reservas = await listarReservas();
    final index = reservas.indexWhere(
      (reserva) => (reserva['id_reserva'] as num?)?.toInt() == reservaId,
    );
    if (index < 0) {
      throw StateError('Reserva não encontrada.');
    }

    final reserva = Map<String, dynamic>.from(reservas[index]);
    final statusAtual = reserva['status']?.toString().toLowerCase();
    if (statusAtual == 'concluida' || statusAtual == 'cancelada') {
      throw StateError('A reserva já foi concluída ou cancelada.');
    }

    final mesas = await listarMesas();
    final mesaIndex = mesas.indexWhere(
      (mesa) => (mesa['id_mesa'] as num?)?.toInt() == mesaId,
    );
    if (mesaIndex < 0) {
      throw StateError('Mesa não encontrada.');
    }

    final mesa = Map<String, dynamic>.from(mesas[mesaIndex]);
    final capacidade = (mesa['capacidade'] as num?)?.toInt() ?? 0;
    final qtdPessoas = (reserva['qtd_pessoas'] as num?)?.toInt() ?? 0;
    if (capacidade < qtdPessoas) {
      throw StateError(
        'A mesa não comporta a quantidade de pessoas da reserva.',
      );
    }

    final mesaOcupada = (mesa['reservado'] as bool?) ?? false;
    if (mesaOcupada) {
      throw StateError('A mesa selecionada já está ocupada.');
    }

    reserva['id_mesa'] = mesaId;
    reserva['status'] = 'confirmada';
    mesas[mesaIndex]['reservado'] = true;
    reservas[index] = reserva;

    await _salvarReservas(reservas);
    await _salvarMesas(mesas);
    return reserva;
  }

  static Future<Map<String, dynamic>> abrirPedidoParaReserva({
    required int reservaId,
    required int mesaId,
    required String atendente,
  }) async {
    final reserva = await _buscarReserva(reservaId);
    final statusReserva = reserva['status']?.toString().toLowerCase();
    if (!const {
      'confirmada',
      'pendente',
      'em_andamento',
      'aberto',
    }.contains(statusReserva)) {
      throw StateError(
        'A reserva precisa estar confirmada antes de abrir o pedido.',
      );
    }

    final pedidos = await listarPedidos();
    final pedidoAberto = firstWhereOrNull<Map<String, dynamic>>(
      pedidos,
      (pedido) => _temPedidoAbertoParaReserva([pedido], reservaId),
    );
    if (pedidoAberto != null) {
      return Map<String, dynamic>.from(pedidoAberto);
    }

    final agora = DateTime.now().toUtc();
    final id = pedidos.isEmpty
        ? 1
        : (pedidos
                  .map((pedido) => (pedido['id_pedido'] as num?)?.toInt() ?? 0)
                  .fold<int>(
                    0,
                    (maior, valor) => valor > maior ? valor : maior,
                  ) +
              1);
    final novoPedido = <String, dynamic>{
      'id': id.toString(),
      'id_pedido': id,
      'id_cliente': reserva['id_cliente'],
      'id_mesa': mesaId,
      'mesa': 'Mesa $mesaId',
      'atendente': atendente,
      'garcom': atendente,
      'id_reserva': reservaId,
      'data_pedido': agora.toIso8601String(),
      'criadoEm': agora.toIso8601String(),
      'status': 'aberto',
      'valor_total': 0.0,
      'itens': <Map<String, dynamic>>[],
    };
    pedidos.insert(0, novoPedido);
    await _salvarPedidos(pedidos);
    return novoPedido;
  }

  static Future<Map<String, dynamic>> adicionarItensAoPedido({
    required int pedidoId,
    required List<Map<String, dynamic>> itens,
  }) async {
    if (itens.isEmpty) {
      throw ArgumentError(
        'O pedido precisa conter itens para serem adicionados.',
      );
    }

    final pedidos = await listarPedidos();
    final indice = pedidos.indexWhere(
      (pedido) => (pedido['id_pedido'] as num?)?.toInt() == pedidoId,
    );
    if (indice < 0) {
      throw StateError('Pedido não encontrado.');
    }

    final pedido = Map<String, dynamic>.from(pedidos[indice]);
    final status = pedido['status']?.toString().toLowerCase();
    if (status == 'concluido' || status == 'cancelado') {
      throw StateError('Pedido fechado não pode receber novos itens.');
    }

    final itensAtuais = (pedido['itens'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    for (final item in itens) {
      final produtoId = (item['id_produto'] as num?)?.toInt() ?? 0;
      final quantidade = (item['quantidade'] as num?)?.toInt() ?? 1;
      final preco =
          (item['preco_unitario'] as num?)?.toDouble() ??
          (item['preco'] as num?)?.toDouble() ??
          0.0;
      if (produtoId <= 0 || quantidade <= 0) {
        throw ArgumentError('Produto e quantidade são obrigatórios.');
      }
      final indiceItem = itensAtuais.indexWhere(
        (atual) => (atual['id_produto'] as num?)?.toInt() == produtoId,
      );
      if (indiceItem >= 0) {
        final atual = Map<String, dynamic>.from(itensAtuais[indiceItem]);
        atual['quantidade'] =
            ((atual['quantidade'] as num?)?.toInt() ?? 0) + quantidade;
        atual['preco_unitario'] = preco;
        if (item['nome'] != null) atual['nome'] = item['nome'];
        itensAtuais[indiceItem] = atual;
      } else {
        itensAtuais.add({
          'id_produto': produtoId,
          if (item['nome'] != null) 'nome': item['nome'],
          'quantidade': quantidade,
          'preco_unitario': preco,
        });
      }
    }

    final total = itensAtuais.fold<double>(
      0,
      (soma, item) =>
          soma +
          ((item['preco_unitario'] as num?)?.toDouble() ?? 0.0) *
              ((item['quantidade'] as num?)?.toInt() ?? 0),
    );

    pedido['itens'] = itensAtuais;
    pedido['valor_total'] = total;
    pedido['status'] = pedido['status']?.toString() ?? 'aberto';
    pedidos[indice] = pedido;
    await _salvarPedidos(pedidos);
    return pedido;
  }

  static Future<Map<String, dynamic>> fecharPedido({
    required int pedidoId,
    int? reservaId,
  }) async {
    final pedidos = await listarPedidos();
    final indice = pedidos.indexWhere(
      (pedido) => (pedido['id_pedido'] as num?)?.toInt() == pedidoId,
    );
    if (indice < 0) {
      throw StateError('Pedido não encontrado.');
    }

    final pedido = Map<String, dynamic>.from(pedidos[indice]);
    final status = pedido['status']?.toString().toLowerCase();
    if (status == 'concluido' || status == 'cancelado') {
      throw StateError('O pedido já foi fechado ou cancelado.');
    }

    final itens = (pedido['itens'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final total = itens.fold<double>(
      0,
      (soma, item) =>
          soma +
          ((item['preco_unitario'] as num?)?.toDouble() ?? 0.0) *
              ((item['quantidade'] as num?)?.toInt() ?? 0),
    );

    pedido['valor_total'] = total;
    pedido['status'] = 'concluido';
    pedidos[indice] = pedido;
    await _salvarPedidos(pedidos);

    if (reservaId != null) {
      final reservas = await listarReservas();
      final indexReserva = reservas.indexWhere(
        (reserva) => (reserva['id_reserva'] as num?)?.toInt() == reservaId,
      );
      if (indexReserva >= 0) {
        final reserva = Map<String, dynamic>.from(reservas[indexReserva]);
        reserva['status'] = 'concluida';
        reservas[indexReserva] = reserva;
        await _salvarReservas(reservas);
      }
    }

    final mesaId = pedido['id_mesa'] as int?;
    if (mesaId != null) {
      final mesas = await listarMesas();
      final indexMesa = mesas.indexWhere(
        (mesa) => (mesa['id_mesa'] as num?)?.toInt() == mesaId,
      );
      if (indexMesa >= 0) {
        mesas[indexMesa]['reservado'] = false;
        await _salvarMesas(mesas);
      }
    }

    return pedido;
  }

  static Future<Map<String, dynamic>> _buscarReserva(int reservaId) async {
    final reservas = await listarReservas();
    final reserva = reservas.firstWhere(
      (item) => (item['id_reserva'] as num?)?.toInt() == reservaId,
      orElse: () => throw StateError('Reserva não encontrada.'),
    );
    return Map<String, dynamic>.from(reserva);
  }

  static bool _temPedidoAbertoParaReserva(
    List<Map<String, dynamic>> pedidos,
    int reservaId,
  ) => pedidos.any(
    (pedido) =>
        (pedido['id_reserva'] as num?)?.toInt() == reservaId &&
        const {
          'aberto',
          'pendente',
          'em_andamento',
        }.contains(pedido['status']?.toString().toLowerCase()),
  );

  static T? firstWhereOrNull<T>(
    Iterable<T> iterable,
    bool Function(T element) test,
  ) {
    for (final item in iterable) {
      if (test(item)) return item;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> listarPedidos() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_pedidosKey) ?? [])
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList()
      ..sort(
        (a, b) => (b['criadoEm'] as String).compareTo(a['criadoEm'] as String),
      );
  }

  static Future<List<Map<String, dynamic>>> listarMesas() async {
    final prefs = await SharedPreferences.getInstance();
    var mesasJson = prefs.getStringList(_mesasKey);
    if (mesasJson == null) {
      final mesas = List.generate(
        12,
        (index) => Mesa(
          idMesa: index + 1,
          capacidade: index < 4 ? 2 : (index < 9 ? 4 : 6),
        ).toMap(),
      );
      mesasJson = mesas.map(jsonEncode).toList();
      await prefs.setStringList(_mesasKey, mesasJson);
    }

    final mesas = mesasJson
        .map((item) => Map<String, dynamic>.from(jsonDecode(item) as Map))
        .toList();
    final reservas = await listarReservas();
    for (final mesa in mesas) {
      final idMesa = (mesa['id_mesa'] as num?)?.toInt();
      if (idMesa == null) continue;
      final ocupada = reservas.any(
        (reserva) =>
            (reserva['id_mesa'] as num?)?.toInt() == idMesa &&
            const {
              'pendente',
              'confirmada',
              'em_andamento',
              'aberto',
            }.contains(reserva['status']?.toString().toLowerCase()),
      );
      mesa['reservado'] = ocupada;
    }
    await _salvarMesas(mesas);
    return mesas
      ..sort((a, b) => (a['id_mesa'] as int).compareTo(b['id_mesa'] as int));
  }

  static Future<Map<String, dynamic>> enviarPedido({
    required String mesa,
    int? mesaId,
    required String garcom,
    required List<Map<String, dynamic>> itens,
  }) async {
    final agora = DateTime.now().toUtc();
    final id = agora.millisecondsSinceEpoch;
    final itensBanco = itens.map((item) {
      final produtoId = (item['id_produto'] as num?)?.toInt() ?? 0;
      final preco =
          (item['preco_unitario'] as num? ?? item['preco'] as num? ?? 0)
              .toDouble();
      return {
        ...item,
        'id_produto': produtoId,
        'preco_unitario': preco,
        'quantidade': item['quantidade'] as int? ?? 1,
      };
    }).toList();

    final total = itensBanco.fold<double>(
      0,
      (soma, item) =>
          soma +
          (item['preco_unitario'] as double) * (item['quantidade'] as int),
    );

    final pedido = <String, dynamic>{
      'id': id.toString(),
      'id_pedido': id,
      'id_cliente': null,
      'id_mesa': mesaId,
      'mesa': mesa,
      'garcom': garcom,
      'atendente': garcom,
      'criadoEm': agora.toIso8601String(),
      'data_pedido': agora.toIso8601String(),
      'status': 'aguardando_envio',
      'valor_total': total,
      'itens': itensBanco,
    };

    final pedidos = await listarPedidos();
    pedidos.insert(0, pedido);
    await _salvarPedidos(pedidos);

    try {
      final pedidoComIntegracao = await CozinhaService().enviarPedido(pedido);
      final pedidosAtualizados = await listarPedidos();
      final indice = pedidosAtualizados.indexWhere(
        (item) => item['id'] == pedido['id'],
      );
      if (indice >= 0) {
        pedidosAtualizados[indice] = pedidoComIntegracao;
        await _salvarPedidos(pedidosAtualizados);
      }
      return pedidoComIntegracao;
    } catch (erro) {
      debugPrint('Não foi possível enviar o pedido à cozinha: $erro');
      final persistido = Map<String, dynamic>.from(pedido);
      persistido['status'] = 'falha_no_envio';
      persistido['erroEnvio'] = erro.toString();
      final pedidosAtualizados = await listarPedidos();
      final indice = pedidosAtualizados.indexWhere(
        (item) => item['id'] == pedido['id'],
      );
      if (indice >= 0) {
        pedidosAtualizados[indice] = persistido;
        await _salvarPedidos(pedidosAtualizados);
      }
      return persistido;
    }
  }

  static Future<Map<String, dynamic>> atualizarStatus(
    Map<String, dynamic> pedido,
  ) async {
    final atualizacao = await CozinhaService().consultarStatus(pedido);
    final statusAtual = atualizacao['status']?.toString();
    if (statusAtual == null || statusAtual == pedido['status']) {
      return pedido;
    }

    final pedidos = await listarPedidos();
    final indice = pedidos.indexWhere((item) => item['id'] == pedido['id']);
    if (indice >= 0) {
      pedidos[indice] = atualizacao;
      await _salvarPedidos(pedidos);
    }
    return atualizacao;
  }

  static bool podeAlterarPedido(Map<String, dynamic> pedido) =>
      _statusEmAndamento(pedido['status']?.toString());

  static bool _statusEmAndamento(String? status) => const {
    'aguardando_envio',
    'somente_local',
    'falha_no_envio',
    'enviado',
    'pendente',
    'aberto',
    'pending',
    'accepted',
    'recebido',
    'queued',
    'preparando',
    'em_preparo',
    'preparing',
    'processing',
    'in_progress',
  }.contains(status?.toLowerCase());

  static Future<Map<String, dynamic>> alterarPedido(
    Map<String, dynamic> pedido, {
    required List<Map<String, dynamic>> itens,
  }) async {
    if (!podeAlterarPedido(pedido)) {
      throw StateError(
        'Pedidos prontos, entregues ou cancelados não podem ser alterados.',
      );
    }
    final itensAtualizados = itens.map((item) {
      final preco =
          (item['preco_unitario'] as num? ?? item['preco'] as num? ?? 0)
              .toDouble();
      final quantidade = (item['quantidade'] as num? ?? 1).toInt();
      if (quantidade < 1) {
        throw ArgumentError('A quantidade dos itens deve ser maior que zero.');
      }
      return {...item, 'preco_unitario': preco, 'quantidade': quantidade};
    }).toList();

    final total = itensAtualizados.fold<double>(
      0,
      (soma, item) =>
          soma +
          (item['preco_unitario'] as double) * (item['quantidade'] as int),
    );

    final atualizado = {
      ...pedido,
      'itens': itensAtualizados,
      'valor_total': total,
      'alteradoEm': DateTime.now().toUtc().toIso8601String(),
    };

    await CozinhaService().atualizarPedido(pedido, {
      'itens': itensAtualizados,
      'valor_total': total,
    });
    await _salvarPedidoAtualizado(atualizado);
    return atualizado;
  }

  static Future<Map<String, dynamic>> cancelarPedido(
    Map<String, dynamic> pedido, {
    String? motivo,
  }) async {
    if (!podeAlterarPedido(pedido)) {
      throw StateError(
        'Pedidos prontos, entregues ou cancelados não podem ser cancelados.',
      );
    }

    final atualizado = {
      ...pedido,
      'status': 'cancelado',
      'motivoCancelamento': motivo?.trim(),
      'canceladoEm': DateTime.now().toUtc().toIso8601String(),
    };

    await CozinhaService().cancelarPedido(pedido, {
      'status': 'cancelado',
      if (motivo?.trim().isNotEmpty == true) 'motivo': motivo!.trim(),
    });
    await _salvarPedidoAtualizado(atualizado);
    return atualizado;
  }

  static Future<void> _salvarPedidoAtualizado(
    Map<String, dynamic> atualizado,
  ) async {
    final pedidos = await listarPedidos();
    final indice = pedidos.indexWhere((item) => item['id'] == atualizado['id']);
    if (indice < 0) {
      throw StateError('Pedido não encontrado no armazenamento local.');
    }
    pedidos[indice] = atualizado;
    await _salvarPedidos(pedidos);
  }

  static Future<void> _salvarReservas(
    List<Map<String, dynamic>> reservas,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _reservasKey,
      reservas.map((reserva) => jsonEncode(reserva)).toList(),
    );
  }

  static Future<void> _salvarMesas(List<Map<String, dynamic>> mesas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _mesasKey,
      mesas.map((mesa) => jsonEncode(mesa)).toList(),
    );
  }

  static Future<void> _salvarPedidos(List<Map<String, dynamic>> pedidos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _pedidosKey,
      pedidos.map((pedido) => jsonEncode(pedido)).toList(),
    );
  }
}
