import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://SEU_ID:8080/CasaBellaProjeto-1.0-SNAPSHOT/api/reservas';

  static const String loginUrl =
      'http://SEU_ID:8080/CasaBellaProjeto-1.0-SNAPSHOT/api/login';

  static http.Client client = http.Client();

  // LISTAR RESERVAS
  static Future<List<dynamic>> listarReservas() async {
    final url = Uri.parse(baseUrl);

    final resposta = await client.get(url);

    if (resposta.statusCode == 200) {
      return jsonDecode(resposta.body) as List<dynamic>;
    } else {
      throw Exception('Erro ao buscar reservas: ${resposta.statusCode}');
    }
  }

  // REALIZAR LOGIN DO FUNCIONÁRIO
  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final url = Uri.parse(loginUrl);

    final resposta = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode == 200) {
      return dados;
    } else {
      throw Exception(dados['mensagem'] ?? 'Erro ao realizar login.');
    }
  }

  // CONFIRMAR RESERVA
  static Future<void> confirmarReserva(int reservaId) async {
    final resposta = await client.put(_reservaUri(reservaId, '/confirmar'));

    _validarResposta(resposta, 'confirmar');
  }

  // ALTERAR RESERVA
  static Future<void> alterarReserva({
    required int reservaId,
    required DateTime horario,
    required int quantidadePessoas,
  }) async {
    if (quantidadePessoas <= 0) {
      throw ArgumentError(
        'A quantidade de pessoas precisa ser maior que zero.',
      );
    }

    final resposta = await client.put(
      _reservaUri(reservaId),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'horario': horario.toIso8601String(),
        'qtd_pessoas': quantidadePessoas,
      }),
    );

    _validarResposta(resposta, 'alterar');
  }

  // CANCELAR RESERVA
  static Future<void> cancelarReserva(int reservaId) async {
    final resposta = await client.delete(_reservaUri(reservaId));

    _validarResposta(resposta, 'cancelar');
  }

  // MONTAR ENDEREÇO DA RESERVA
  static Uri _reservaUri(int reservaId, [String sufixo = '']) {
    if (reservaId <= 0) {
      throw ArgumentError('O identificador da reserva precisa ser válido.');
    }

    return Uri.parse('$baseUrl/$reservaId$sufixo');
  }

  // VALIDAR RESPOSTA DAS OPERAÇÕES DE RESERVA
  static void _validarResposta(http.Response resposta, String operacao) {
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      final detalhe = resposta.body.trim();

      throw Exception(
        'Não foi possível $operacao a reserva '
        '(HTTP ${resposta.statusCode})'
        '${detalhe.isEmpty ? '.' : ': $detalhe'}',
      );
    }
  }
}
