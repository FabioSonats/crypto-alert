import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_alert/main.dart';

void main() {
  testWidgets('App should load', (WidgetTester tester) async {
    await tester.pumpWidget(const CryptoAlertApp());
    expect(find.text('Crypto Alert'), findsOneWidget);
  });
}
