
import 'package:casa_bella/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('O app abre diretamente no painel de atendimento', (tester) async {
    await tester.pumpWidget(const CasaBellaApp());

    expect(find.text('Acesso rápido'), findsOneWidget);
    expect(find.text('ENTRAR'), findsNothing);
    expect(find.text('Cadastrar colaborador'), findsNothing);
  });
}
