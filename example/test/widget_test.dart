import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('ExampleApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ParticleControllerScreen());
    expect(find.byType(ParticleControllerScreen), findsOneWidget);
  });
}
