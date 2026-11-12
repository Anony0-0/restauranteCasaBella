import 'package:casa_bella/servicos/api_service.dart';
import 'package:casa_bella/main.dart';
import 'package:casa_bella/telas/inicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() {
    ApiService.client.close();
    ApiService.client = http.Client();
  });

  testWidgets('O app abre na tela de login dos colaboradores', (tester) async {
    await tester.pumpWidget(const CasaBellaApp());

    expect(find.text('Acesso dos colaboradores'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Acesso rápido'), findsNothing);
    expect(find.text('Cadastrar colaborador'), findsNothing);
  });

  testWidgets('Valida os campos obrigatórios e não concede acesso', (
    tester,
  ) async {
    await tester.pumpWidget(const CasaBellaApp());

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'equipe@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha');
    ApiService.client = MockClient(
      (_) async => http.Response('{"erro":"Credenciais inválidas."}', 401),
    );
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Credenciais inválidas.'), findsOneWidget);
    expect(find.byType(InicioPage), findsNothing);
  });

  testWidgets('Rejeita formato inválido de e-mail antes de chamar a API', (
    tester,
  ) async {
    var requisicaoEnviada = false;
    ApiService.client = MockClient((_) async {
      requisicaoEnviada = true;
      return http.Response('{}', 200);
    });
    await tester.pumpWidget(const CasaBellaApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'email-invalido');
    await tester.enterText(find.byType(TextFormField).at(1), 'senha');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(requisicaoEnviada, isFalse);
  });

  testWidgets('Usa cargo retornado pela API no perfil do colaborador', (
    tester,
  ) async {
    ApiService.client = MockClient(
      (_) async => http.Response(
        '{"nome":"Ana","email":"ana@example.com","cargo":"Gerente"}',
        200,
      ),
    );
    await tester.pumpWidget(const CasaBellaApp());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'ana@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(tester.widget<InicioPage>(find.byType(InicioPage)).cargo, 'Gerente');
  });

  testWidgets('Mantém compatibilidade com o campo perfil do login', (
    tester,
  ) async {
    ApiService.client = MockClient(
      (_) async => http.Response(
        '{"nome":"Ana","email":"ana@example.com","perfil":"Atendente"}',
        200,
      ),
    );
    await tester.pumpWidget(const CasaBellaApp());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'ana@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<InicioPage>(find.byType(InicioPage)).cargo,
      'Atendente',
    );
  });

  testWidgets('Permite alternar a visibilidade da senha', (tester) async {
    await tester.pumpWidget(const CasaBellaApp());

    final campoSenha = find.descendant(
      of: find.byType(TextFormField).at(1),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(campoSenha).obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pumpAndSettle();

    expect(tester.widget<EditableText>(campoSenha).obscureText, isFalse);
  });
}
