import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_stack/main.dart';

void main() {
  testWidgets('App should load', (WidgetTester tester) async {
    await tester.pumpWidget(const NexusStackApp());
    expect(find.text('NexusStack'), findsOneWidget);
  });
}
