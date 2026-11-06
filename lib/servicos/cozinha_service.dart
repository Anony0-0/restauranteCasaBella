import 'dart:convert';

import 'package:http/http.dart' as http;

class CozinhaService {
  final String _endpoint = const String.fromEnvironment('KITCHEN_API_URL');

  bool get habilitado => _endpoint.trim().isNotEmpty;

  Future<Map<String, dynamic>> enviarPedido(
    Map<String, dynamic> pedido,
  ) async {
    if (!habilitado) {
      final salvo = Map<String, dynamic>.from(pedido);
      salvo['status'] = 'somente_local';
      return salvo;
    }

    final base = _endpoint.endsWith('/') ? _endpoint : '$_endpoint/';
    try {
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

      final atualizado = Map<String, dynamic>.from(pedido);
      atualizado['status'] = 'enviado';
      atualizado['integradoCozinha'] = true;

      if (resposta.body.trim().isNotEmpty) {
        final conteudo = jsonDecode(resposta.body);
        if (conteudo is Map<String, dynamic> && conteudo['id'] != null) {
          atualizado['idCozinha'] = conteudo['id'].toString();
        }
      }
      return atualizado;
    } catch (erro) {
      final atualizado = Map<String, dynamic>.from(pedido);
      atualizado['status'] = 'falha_no_envio';
      atualizado['erroEnvio'] = erro.toString();
      return atualizado;
    }
  }

  Future<Map<String, dynamic>> consultarStatus(
    Map<String, dynamic> pedido,
  ) async {
    if (!habilitado) return pedido;

    final statusAtual = pedido['status']?.toString();
    final finalizado = const {
      'pronto',
      'ready',
      'entregue',
      'completed',
      'cancelado',
      'cancelled',
      'canceled',
    }.contains(statusAtual?.toLowerCase());

    if (finalizado) return pedido;

    final base = _endpoint.endsWith('/') ? _endpoint : '$_endpoint/';
    final id = pedido['idCozinha'] ?? pedido['id'];

    try {
      final resposta = await http
          .get(Uri.parse('${base}orders/$id'))
          .timeout(const Duration(seconds: 10));

      if (resposta.statusCode == 200) {
        final conteudo = jsonDecode(resposta.body);
        if (conteudo is Map<String, dynamic> && conteudo['status'] != null) {
          final atualizado = Map<String, dynamic>.from(pedido);
          atualizado['status'] = conteudo['status'].toString();
          return atualizado;
        }
      }
    } catch (erro) {
      // A consulta falha silenciosamente para manter o fluxo local estável.
      // O pedido continua disponível para o atendimento.
      return pedido;
    }

    return pedido;
  }

  Future<void> atualizarPedido(
    Map<String, dynamic> pedido,
    Map<String, dynamic> alteracoes,
  ) async {
    if (!habilitado) return;

    final statusAtual = pedido['status']?.toString();
    final integracaoAtiva = pedido['integradoCozinha'] == true ||
        pedido['idCozinha'] != null;
    final podeEnviar = const {
      'enviado',
      'preparando',
      'in_progress',
      'em_preparo',
    }.contains(statusAtual?.toLowerCase());

    if (!integracaoAtiva && !podeEnviar) return;

    final base = _endpoint.endsWith('/') ? _endpoint : '$_endpoint/';
    final id = pedido['idCozinha'] ?? pedido['id'];

    final resposta = await http
        .patch(
          Uri.parse('${base}orders/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(alteracoes),
        )
        .timeout(const Duration(seconds: 12));

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw Exception('A cozinha não confirmou a alteração (HTTP ${resposta.statusCode}).');
    }
  }

  Future<void> cancelarPedido(
    Map<String, dynamic> pedido,
    Map<String, dynamic> alteracoes,
  ) async {
    if (!habilitado) return;

    final statusAtual = pedido['status']?.toString();
    final integracaoAtiva = pedido['integradoCozinha'] == true ||
        pedido['idCozinha'] != null;
    final podeEnviar = const {
      'enviado',
      'preparando',
      'in_progress',
      'em_preparo',
    }.contains(statusAtual?.toLowerCase());

    if (!integracaoAtiva && !podeEnviar) return;

    final base = _endpoint.endsWith('/') ? _endpoint : '$_endpoint/';
    final id = pedido['idCozinha'] ?? pedido['id'];

    final resposta = await http
        .patch(
          Uri.parse('${base}orders/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(alteracoes),
        )
        .timeout(const Duration(seconds: 12));

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw Exception('A cozinha não confirmou o cancelamento (HTTP ${resposta.statusCode}).');
    }
  }
}
