import 'package:flutter_test/flutter_test.dart';
import 'package:pos_dogos_el_pa/main.dart';

void main() {
  testWidgets('App starts on Mode Selection Screen (Servidor / Cliente)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FlashPosDogosApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('INICIAR COMO SERVIDOR'), findsOneWidget);
    expect(find.textContaining('INICIAR COMO CLIENTE'), findsOneWidget);
  });
}
