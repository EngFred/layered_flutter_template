import 'package:flutter_test/flutter_test.dart';

import 'package:layered_flutter_template/app/app.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Template ready'), findsOneWidget);
  });
}
