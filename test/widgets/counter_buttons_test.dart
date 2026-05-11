import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:counter_app/widgets/counter_buttons.dart';

void main() {
  group('CounterButtons Widget', () {
    testWidgets('renders +1 and -1 buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (_) {},
              currentTotal: 0,
            ),
          ),
        ),
      );

      expect(find.text('+1'), findsOneWidget);
      expect(find.text('-1'), findsOneWidget);
    });

    testWidgets('renders 自定义 button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (_) {},
              currentTotal: 0,
            ),
          ),
        ),
      );

      expect(find.text('自定义'), findsOneWidget);
    });

    testWidgets('renders 撤销 button when canUndo is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (_) {},
              currentTotal: 0,
              canUndo: true,
              onUndo: () {},
            ),
          ),
        ),
      );

      expect(find.text('撤销'), findsOneWidget);
    });

    testWidgets('does not render 撤销 button when canUndo is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (_) {},
              currentTotal: 0,
              canUndo: false,
            ),
          ),
        ),
      );

      expect(find.text('撤销'), findsNothing);
    });

    testWidgets('tapping +1 calls onDelta(1)', (tester) async {
      int? receivedDelta;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (delta) => receivedDelta = delta,
              currentTotal: 0,
            ),
          ),
        ),
      );

      await tester.tap(find.text('+1'));
      await tester.pump();

      expect(receivedDelta, 1);
    });

    testWidgets('tapping -1 calls onDelta(-1)', (tester) async {
      int? receivedDelta;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (delta) => receivedDelta = delta,
              currentTotal: 0,
            ),
          ),
        ),
      );

      await tester.tap(find.text('-1'));
      await tester.pump();

      expect(receivedDelta, -1);
    });

    testWidgets('tapping 自定义 opens bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (_) {},
              currentTotal: 0,
            ),
          ),
        ),
      );

      await tester.tap(find.text('自定义'));
      await tester.pumpAndSettle();

      expect(find.text('自定义增减'), findsOneWidget);
      expect(find.text('数值（正数增加，负数减少）'), findsOneWidget);
    });

    testWidgets('custom delta bottom sheet has cancel and confirm buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (_) {},
              currentTotal: 0,
            ),
          ),
        ),
      );

      await tester.tap(find.text('自定义'));
      await tester.pumpAndSettle();

      expect(find.text('取消'), findsOneWidget);
      expect(find.text('确定'), findsOneWidget);
    });

    testWidgets('custom delta bottom sheet cancel closes sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (_) {},
              currentTotal: 0,
            ),
          ),
        ),
      );

      await tester.tap(find.text('自定义'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(find.text('自定义增减'), findsNothing);
    });

    testWidgets('custom delta form submits valid integer', (tester) async {
      int? receivedDelta;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (delta) => receivedDelta = delta,
              currentTotal: 0,
            ),
          ),
        ),
      );

      await tester.tap(find.text('自定义'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '7');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(receivedDelta, 7);
      expect(find.text('自定义增减'), findsNothing); // sheet closed
    });

    testWidgets('custom delta form rejects empty input', (tester) async {
      int? receivedDelta;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (delta) => receivedDelta = delta,
              currentTotal: 0,
            ),
          ),
        ),
      );

      await tester.tap(find.text('自定义'));
      await tester.pumpAndSettle();

      // Don't enter any text, tap confirm directly
      await tester.tap(find.text('确定'));
      await tester.pump();

      // Sheet should still be open showing validation error
      expect(find.text('自定义增减'), findsOneWidget);
      expect(receivedDelta, isNull);
    });

    testWidgets('custom delta form rejects non-integer input', (tester) async {
      int? receivedDelta;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (delta) => receivedDelta = delta,
              currentTotal: 0,
            ),
          ),
        ),
      );

      await tester.tap(find.text('自定义'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.tap(find.text('确定'));
      await tester.pump();

      expect(find.text('请输入有效的整数'), findsOneWidget);
      expect(receivedDelta, isNull);
    });

    testWidgets('undo button triggers onUndo callback', (tester) async {
      bool undoCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (_) {},
              currentTotal: 0,
              canUndo: true,
              onUndo: () => undoCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('撤销'));
      await tester.pump();

      expect(undoCalled, isTrue);
    });

    testWidgets('+1 and -1 buttons have correct visual appearance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CounterButtons(
              onDelta: (_) {},
              currentTotal: 0,
            ),
          ),
        ),
      );

      // Find the ElevatedButtons inside SizedBoxes
      final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttons.length, greaterThanOrEqualTo(2));
    });
  });
}
