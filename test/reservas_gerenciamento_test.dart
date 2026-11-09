import 'dart:convert';

import 'package:casa_bella/servicos/api_service.dart';
import 'package:casa_bella/telas/reservas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requisicoes;
  late String status;
  late int pessoas;
  late DateTime horario;

  setUp(() {
    requisicoes = [];
    status = 'Pendente';
    pessoas = 2;
    horario = DateTime(2026, 12, 10, 19);
    ApiService.client = MockClient((request) async {
      requisicoes.add(request);
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode([
            {
              'id_reserva': 73,
              'id_cliente': 12,
              'cliente': 'Ana Ribeiro',
              'horario': horario.toIso8601String(),
              'qtd_pessoas': pessoas,
              'status': status,
            },
          ]),
          200,
        );
      }

      if (request.method == 'PUT' && request.url.path.endsWith('/confirmar')) {
        status = 'Confirmada';
        return http.Response('{"status":"Confirmada"}', 200);
      }

      if (request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        horario = DateTime.parse(body['horario'] as String);
        pessoas = body['qtd_pessoas'] as int;
        return http.Response('{}', 200);
      }

      if (request.method == 'DELETE') {
        status = 'Cancelada';
        return http.Response('{"status":"Cancelada"}', 200);
      }
      return http.Response('Método não suportado', 405);
    });
  });

  tearDown(() {
    ApiService.client.close();
    ApiService.client = http.Client();
  });

  Future<void> abrirOpcoes(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReservasPage(atendente: 'Atendente')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opções da reserva'));
    await tester.pumpAndSettle();
  }

  testWidgets('confirma reserva pela API e atualiza o status exibido', (
    tester,
  ) async {
    await abrirOpcoes(tester);
    await tester.tap(find.text('Confirmar reserva'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar reserva?'), findsOneWidget);
    expect(requisicoes.where((request) => request.method == 'PUT'), isEmpty);
    await tester.tap(find.text('Confirmar reserva').last);
    await tester.pumpAndSettle();

    expect(status, 'Confirmada');
    expect(find.text('Confirmada'), findsOneWidget);
    expect(
      requisicoes.any(
        (request) =>
            request.method == 'PUT' &&
            request.url.path.endsWith('/73/confirmar'),
      ),
      isTrue,
    );
  });

  testWidgets('não permite confirmar reserva cancelada', (tester) async {
    status = 'Cancelada';
    await tester.pumpWidget(
      const MaterialApp(home: ReservasPage(atendente: 'Atendente')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancelada'), findsOneWidget);
    expect(find.byTooltip('Opções da reserva'), findsNothing);
    expect(requisicoes.where((request) => request.method == 'PUT'), isEmpty);
  });

  testWidgets('altera horário e pessoas pela API e atualiza a lista', (
    tester,
  ) async {
    await abrirOpcoes(tester);
    await tester.tap(find.text('Alterar reserva'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '4');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(pessoas, 4);
    expect(find.text('4 pessoas'), findsOneWidget);
    final requisicao = requisicoes.firstWhere(
      (request) =>
          request.method == 'PUT' && !request.url.path.endsWith('/confirmar'),
    );
    expect(requisicao.url.path.endsWith('/73'), isTrue);
    expect(
      (jsonDecode(requisicao.body) as Map<String, dynamic>)['qtd_pessoas'],
      4,
    );
  });

  testWidgets('confirma antes de cancelar e persiste o cancelamento', (
    tester,
  ) async {
    await abrirOpcoes(tester);
    await tester.tap(find.text('Cancelar reserva'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar reserva?'), findsOneWidget);

    await tester.tap(find.text('Cancelar reserva').last);
    await tester.pumpAndSettle();

    expect(status, 'Cancelada');
    expect(find.text('Cancelada'), findsOneWidget);
    expect(
      requisicoes.any(
        (request) =>
            request.method == 'DELETE' && request.url.path.endsWith('/73'),
      ),
      isTrue,
    );
  });

  testWidgets('não envia cancelamento sem confirmação do atendente', (
    tester,
  ) async {
    await abrirOpcoes(tester);
    await tester.tap(find.text('Cancelar reserva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter reserva'));
    await tester.pumpAndSettle();

    expect(status, 'Pendente');
    expect(requisicoes.where((request) => request.method == 'DELETE'), isEmpty);
  });

  testWidgets('reserva cancelada não pode ser cancelada novamente', (
    tester,
  ) async {
    status = 'Cancelada';
    await tester.pumpWidget(
      const MaterialApp(home: ReservasPage(atendente: 'Atendente')),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Opções da reserva'), findsNothing);
    expect(requisicoes.where((request) => request.method == 'DELETE'), isEmpty);
  });
}
