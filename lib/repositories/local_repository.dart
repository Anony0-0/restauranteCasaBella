import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mesa.dart';

/// Persistência offline do app. A API central pode substituir esta camada.
class LocalRepository {
  static const _usuariosKey = 'casa_bella_colaboradores';
  static const _pedidosKey = 'casa_bella_pedidos';
  static const _mesasKey = 'casa_bella_mesas';

  static String _hashSenha(String senha, String salt) =>
      sha256.convert(utf8.encode('$salt:$senha')).toString();

  static Future<bool> temColaboradores() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarios = await _usuariosComGerenteInicial(prefs);
    return usuarios.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> _usuariosComGerenteInicial(
    SharedPreferences prefs,
  ) async {
    final usuarios = (prefs.getStringList(_usuariosKey) ?? [])
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
    var alterado = false;
    var proximoId =
        usuarios
            .map(
              (usuario) => int.tryParse('${usuario['id_usuario'] ?? ''}') ?? 0,
            )
            .fold<int>(0, (maior, id) => id > maior ? id : maior) +
        1;
    for (final usuario in usuarios) {
      final idExistente = int.tryParse('${usuario['id_usuario'] ?? ''}');
      if (idExistente == null || idExistente <= 0) {
        // Migra cadastros offline antigos que usavam CPF como identificador.
        usuario['id_usuario'] = proximoId++;
        alterado = true;
      } else {
        usuario['id_usuario'] = idExistente;
      }
    }
    if (usuarios.isNotEmpty &&
        !usuarios.any(
          (usuario) => cargoPodeGerenciarEquipe(usuario['cargo']?.toString()),
        )) {
      // Compatibilidade: em instalações antigas, o primeiro colaborador passa
      // a administrar a equipe, pois a versão anterior não tinha perfis.
      usuarios.first['cargo'] = 'Gerente';
      alterado = true;
    }
    if (alterado) {
      await prefs.setStringList(
        _usuariosKey,
        usuarios.map((usuario) => jsonEncode(usuario)).toList(),
      );
    }
    return usuarios;
  }

  static bool cargoPodeGerenciarEquipe(String? cargo) => const {
    'gerente',
    'gerente geral',
    'administrador',
    'admin',
  }.contains(cargo?.trim().toLowerCase());

  static Future<List<Map<String, String>>> listarColaboradores() async {
    final prefs = await SharedPreferences.getInstance();
    return (await _usuariosComGerenteInicial(prefs))
        .map(
          (usuario) => {
            'id_usuario': '${usuario['id_usuario'] ?? ''}',
            'nome': usuario['nome']?.toString() ?? '',
            'cargo': usuario['cargo']?.toString() ?? 'Atendente',
            'admissao': usuario['admissao']?.toString() ?? '',
          },
        )
        .toList()
      ..sort((a, b) => a['nome']!.compareTo(b['nome']!));
  }

  static Future<String?> removerColaborador({
    required String idResponsavel,
    required String idColaborador,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarios = await _usuariosComGerenteInicial(prefs);
    final responsavelId = int.tryParse(idResponsavel);
    final colaboradorId = int.tryParse(idColaborador);
    Map<String, dynamic>? responsavel;
    for (final usuario in usuarios) {
      if (usuario['id_usuario'] == responsavelId) {
        responsavel = usuario;
        break;
      }
    }

    if (responsavel == null ||
        !cargoPodeGerenciarEquipe(responsavel['cargo']?.toString())) {
      return 'Somente um gerente ou administrador pode remover colaboradores.';
    }
    if (responsavelId == colaboradorId) {
      return 'Não é possível remover a própria conta durante a sessão.';
    }

    final indice = usuarios.indexWhere(
      (usuario) => usuario['id_usuario'] == colaboradorId,
    );
    if (indice < 0) return 'Colaborador não encontrado.';

    final colaborador = usuarios[indice];
    if (cargoPodeGerenciarEquipe(colaborador['cargo']?.toString())) {
      final quantidadeGestores = usuarios
          .where(
            (usuario) => cargoPodeGerenciarEquipe(usuario['cargo']?.toString()),
          )
          .length;
      if (quantidadeGestores <= 1) {
        return 'Não é possível remover o último gerente ou administrador.';
      }
    }

    usuarios.removeAt(indice);
    await prefs.setStringList(
      _usuariosKey,
      usuarios.map((usuario) => jsonEncode(usuario)).toList(),
    );
    return null;
  }

  static Future<({int? idUsuario, String? erro})> cadastrar({
    required String nome,
    required String senha,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarios = await _usuariosComGerenteInicial(prefs);
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltTexto = base64UrlEncode(salt);
    final idUsuario =
        usuarios
            .map(
              (usuario) => int.tryParse('${usuario['id_usuario'] ?? ''}') ?? 0,
            )
            .fold<int>(0, (maior, id) => id > maior ? id : maior) +
        1;
    usuarios.add({
      'id_usuario': idUsuario,
      'nome': nome.trim(),
      // O primeiro cadastro inicializa o perfil gerente; novos cadastros são atendentes.
      'cargo': usuarios.isEmpty ? 'Gerente' : 'Atendente',
      'admissao': DateTime.now().toIso8601String().substring(0, 10),
      'salt': saltTexto,
      'senhaHash': _hashSenha(senha, saltTexto),
    });
    await prefs.setStringList(
      _usuariosKey,
      usuarios.map((usuario) => jsonEncode(usuario)).toList(),
    );
    return (idUsuario: idUsuario, erro: null);
  }

  static Future<Map<String, String>?> entrar({
    required String idUsuario,
    required String senha,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarios = await _usuariosComGerenteInicial(prefs);
    final id = int.tryParse(idUsuario.trim());
    if (id == null || id <= 0) return null;
    for (final usuario in usuarios) {
      if (usuario['id_usuario'] == id &&
          usuario['senhaHash'] ==
              _hashSenha(senha, usuario['salt'] as String)) {
        return {
          'nome': usuario['nome'] as String,
          'id_usuario': id.toString(),
          'cargo': usuario['cargo'] as String? ?? 'Atendente',
        };
      }
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
    return mesasJson
        .map((item) => Map<String, dynamic>.from(jsonDecode(item) as Map))
        .toList()
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

    const endpoint = String.fromEnvironment('KITCHEN_API_URL');
    if (endpoint.isEmpty) {
      pedido['status'] = 'somente_local';
      await _salvarPedidos(pedidos);
      return pedido;
    }

    try {
      final base = endpoint.endsWith('/') ? endpoint : '$endpoint/';
      final resposta = await http
          .post(
            Uri.parse('${base}orders'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(pedido),
          )
          .timeout(const Duration(seconds: 12));
      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw Exception('HTTP ${resposta.statusCode}');
      }
      pedido['status'] = 'enviado';
      pedido['integradoCozinha'] = true;
      if (resposta.body.trim().isNotEmpty) {
        final conteudo = jsonDecode(resposta.body);
        if (conteudo is Map<String, dynamic> && conteudo['id'] != null) {
          pedido['idCozinha'] = conteudo['id'].toString();
        }
      }
    } catch (erro) {
      pedido['status'] = 'falha_no_envio';
      pedido['erroEnvio'] = erro.toString();
    }
    await _salvarPedidos(pedidos);
    return pedido;
  }

  static Future<Map<String, dynamic>> atualizarStatus(
    Map<String, dynamic> pedido,
  ) async {
    const endpoint = String.fromEnvironment('KITCHEN_API_URL');
    if (endpoint.isEmpty ||
        _statusFinal(pedido['status']?.toString()) ||
        (pedido['integradoCozinha'] != true &&
            pedido['idCozinha'] == null &&
            !_statusConsultavel(pedido['status']?.toString()))) {
      return pedido;
    }
    try {
      final base = endpoint.endsWith('/') ? endpoint : '$endpoint/';
      final id = pedido['idCozinha'] ?? pedido['id'];
      final resposta = await http
          .get(Uri.parse('${base}orders/$id'))
          .timeout(const Duration(seconds: 10));
      if (resposta.statusCode == 200) {
        final conteudo = jsonDecode(resposta.body);
        if (conteudo is Map<String, dynamic> && conteudo['status'] != null) {
          pedido['status'] = conteudo['status'].toString();
          final pedidos = await listarPedidos();
          final indice = pedidos.indexWhere(
            (item) => item['id'] == pedido['id'],
          );
          if (indice >= 0) {
            pedidos[indice] = pedido;
            await _salvarPedidos(pedidos);
          }
        }
      }
    } catch (erro) {
      debugPrint('Não foi possível consultar o status do pedido: $erro');
    }
    return pedido;
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

  static bool _statusConsultavel(String? status) => const {
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

  static bool _statusFinal(String? status) => const {
    'pronto',
    'ready',
    'entregue',
    'completed',
    'cancelado',
    'cancelled',
    'canceled',
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
    if (itens.isEmpty) {
      throw ArgumentError('O pedido precisa conter ao menos um item.');
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

    await _enviarAtualizacaoCozinha(pedido, {
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

    await _enviarAtualizacaoCozinha(pedido, {
      'status': 'cancelado',
      if (motivo?.trim().isNotEmpty == true) 'motivo': motivo!.trim(),
    });
    await _salvarPedidoAtualizado(atualizado);
    return atualizado;
  }

  static Future<void> _enviarAtualizacaoCozinha(
    Map<String, dynamic> pedido,
    Map<String, dynamic> alteracoes,
  ) async {
    const endpoint = String.fromEnvironment('KITCHEN_API_URL');
    if (endpoint.isEmpty ||
        (pedido['integradoCozinha'] != true &&
            pedido['idCozinha'] == null &&
            !const {
              'enviado',
              'preparando',
              'in_progress',
              'em_preparo',
            }.contains(pedido['status']?.toString().toLowerCase()))) {
      return;
    }
    final base = endpoint.endsWith('/') ? endpoint : '$endpoint/';
    final id = pedido['idCozinha'] ?? pedido['id'];
    final resposta = await http
        .patch(
          Uri.parse('${base}orders/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(alteracoes),
        )
        .timeout(const Duration(seconds: 12));
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw Exception(
        'A cozinha não confirmou a alteração (HTTP ${resposta.statusCode}).',
      );
    }
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

  static Future<void> _salvarPedidos(List<Map<String, dynamic>> pedidos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _pedidosKey,
      pedidos.map((pedido) => jsonEncode(pedido)).toList(),
    );
  }
}
