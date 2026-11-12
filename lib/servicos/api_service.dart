import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  // ENDEREÇO PRINCIPAL DA API
  static const String apiRoot =
      'http://10.27.67.174:8080/CasaBellaProjeto-1.0-SNAPSHOT/api';

  // ENDEREÇOS ESPECÍFICOS
  static const String baseUrl = '$apiRoot/reservas';

  static const String loginUrl = '$apiRoot/login';

  static http.Client client = http.Client();

  // LOGIN DO FUNCIONÁRIO
  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final resposta = await _request(
      'fazer login',
      () => client.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email.trim(), 'senha': senha},
      ),
    );

    _validarResposta(resposta, 'fazer login');
    return _decodificarObjeto(resposta, 'fazer login');
  }

  // LISTAR RESERVAS
  static Future<List<Map<String, dynamic>>> listarReservas() async {
    final resposta = await _request(
      'buscar reservas',
      () => client.get(Uri.parse(baseUrl)),
    );
    _validarResposta(resposta, 'buscar reservas');
    return _decodificarLista(resposta, 'buscar reservas');
  }

  // CONFIRMAR RESERVA
  static Future<void> confirmarReserva(int reservaId) async {
    final resposta = await _request(
      'confirmar reserva',
      () => client.put(_reservaUri(reservaId, '/confirmar')),
    );

    _validarResposta(resposta, 'confirmar reserva');
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

    final resposta = await _request(
      'alterar reserva',
      () => client.put(
        _reservaUri(reservaId),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'horario': horario.toIso8601String(),
          'qtd_pessoas': quantidadePessoas,
        }),
      ),
    );

    _validarResposta(resposta, 'alterar reserva');
  }

  // CANCELAR RESERVA
  static Future<void> cancelarReserva(int reservaId) async {
    final resposta = await _request(
      'cancelar reserva',
      () => client.delete(_reservaUri(reservaId)),
    );

    _validarResposta(resposta, 'cancelar reserva');
  }

  // LISTAR PRODUTOS DO CARDÁPIO
  static Future<List<Map<String, dynamic>>> listarProdutos() async {
    final resposta = await _request(
      'buscar produtos',
      () => client.get(Uri.parse('$apiRoot/produtos')),
    );
    _validarResposta(resposta, 'buscar produtos');
    return _decodificarLista(resposta, 'buscar produtos');
  }

  // CRIAR PEDIDO A PARTIR DE UMA RESERVA
  static Future<int> criarPedido(int reservaId) async {
    if (reservaId <= 0) {
      throw ArgumentError('O identificador da reserva é inválido.');
    }

    final url = Uri.parse('$apiRoot/pedidos');

    final resposta = await _request(
      'criar pedido',
      () => client.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id_reserva': reservaId.toString()},
      ),
    );

    _validarResposta(resposta, 'criar pedido');
    final dados = _decodificarObjeto(resposta, 'criar pedido');
    final pedidoId = _lerId(dados['id_pedido']);
    if (pedidoId == null || pedidoId <= 0) {
      throw const ApiException(
        'A resposta do servidor não contém um ID de pedido válido.',
      );
    }
    return pedidoId;
  }

  // ADICIONAR ITEM AO PEDIDO
  static Future<void> adicionarItemPedido({
    required int pedidoId,
    required int produtoId,
    required int quantidade,
  }) async {
    if (pedidoId <= 0 || produtoId <= 0 || quantidade <= 0) {
      throw ArgumentError('Os dados do item do pedido são inválidos.');
    }

    final url = Uri.parse('$apiRoot/pedidos/itens');

    final resposta = await _request(
      'adicionar produto ao pedido',
      () => client.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'id_pedido': pedidoId.toString(),
          'id_produto': produtoId.toString(),
          'quantidade': quantidade.toString(),
        },
      ),
    );

    _validarResposta(resposta, 'adicionar produto ao pedido');
    final dados = _decodificarObjeto(resposta, 'adicionar produto ao pedido');

    if (dados['ok'] != true) {
      throw const ApiException('Não foi possível adicionar o produto ao pedido.');
    }
  }

  // MONTAR ENDEREÇO DA RESERVA
  static Uri _reservaUri(int reservaId, [String sufixo = '']) {
    if (reservaId <= 0) {
      throw ArgumentError('O identificador da reserva precisa ser válido.');
    }

    return Uri.parse('$baseUrl/$reservaId$sufixo');
  }

  static Future<http.Response> _request(
    String operacao,
    Future<http.Response> Function() enviar,
  ) async {
    try {
      return await enviar().timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw ApiException('A conexão expirou ao $operacao. Tente novamente.');
    } on http.ClientException {
      throw ApiException(
        'Não foi possível conectar ao servidor ao $operacao. '
        'Verifique sua conexão.',
      );
    }
  }

  static Map<String, dynamic> _decodificarObjeto(
    http.Response resposta,
    String operacao,
  ) {
    final dados = _decodificarJson(resposta, operacao);
    if (dados is! Map) {
      throw ApiException('O servidor retornou dados inválidos ao $operacao.');
    }
    return Map<String, dynamic>.from(dados);
  }

  static List<Map<String, dynamic>> _decodificarLista(
    http.Response resposta,
    String operacao,
  ) {
    final dados = _decodificarJson(resposta, operacao);
    if (dados is! List || dados.any((item) => item is! Map)) {
      throw ApiException('O servidor retornou uma lista inválida ao $operacao.');
    }
    return dados.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Object? _decodificarJson(http.Response resposta, String operacao) {
    try {
      return jsonDecode(resposta.body);
    } on FormatException {
      throw ApiException('O servidor retornou uma resposta inválida ao $operacao.');
    }
  }

  static int? _lerId(Object? valor) {
    if (valor is int) return valor;
    if (valor is num && valor.isFinite && valor == valor.toInt()) {
      return valor.toInt();
    }
    return valor is String ? int.tryParse(valor) : null;
  }

  // VALIDAR RESPOSTA DA API
  static void _validarResposta(http.Response resposta, String operacao) {
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      final erroApi = _mensagemApi(resposta);
      throw ApiException(
        erroApi ?? _mensagemHttp(resposta.statusCode, operacao),
        statusCode: resposta.statusCode,
      );
    }
  }

  static String? _mensagemApi(http.Response resposta) {
    try {
      final dados = jsonDecode(resposta.body);
      if (dados is Map) {
        for (final chave in const ['erro', 'mensagem']) {
          final mensagem = dados[chave];
          if (mensagem is String && mensagem.trim().isNotEmpty) {
            return mensagem.trim();
          }
        }
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static String _mensagemHttp(int statusCode, String operacao) {
    final detalhe = switch (statusCode) {
      400 => 'Os dados enviados são inválidos.',
      401 || 403 => 'Você não tem autorização para realizar esta operação.',
      404 => 'O registro solicitado não foi encontrado.',
      409 => 'A operação não pode ser concluída porque os dados foram alterados '
          'ou o registro já foi finalizado.',
      >= 500 => 'O servidor encontrou um erro. Tente novamente mais tarde.',
      _ => 'O servidor respondeu com erro HTTP $statusCode.',
    };
    return 'Não foi possível $operacao. $detalhe';
  }
}
