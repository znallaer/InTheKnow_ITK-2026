import 'package:flutter_test/flutter_test.dart';
import 'package:in_the_know/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    await tester.pumpWidget(const InTheKnowApp());
    expect(find.byType(InTheKnowApp), findsOneWidget);
  });
}
