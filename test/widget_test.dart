import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:counter_app/app.dart';

void main() {
  testWidgets('App smoke test - verify home page loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CounterApp(),
      ),
    );

    // App should be loading (sqflite not available in test, but widget renders)
    // Verify app title is shown in AppBar
    expect(find.text('计数统计'), findsOneWidget);

    // Verify FAB is present
    expect(find.text('新建项目'), findsOneWidget);
  });
}
