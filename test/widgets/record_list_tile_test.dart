import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:counter_app/widgets/record_list_tile.dart';
import 'package:counter_app/models/record.dart';

void main() {
  group('RecordListTile Widget', () {
    final tNow = DateTime(2026, 5, 11, 14, 30);

    Widget buildTile({
      required CounterRecord record,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: RecordListTile(
            record: record,
            onDelete: onDelete,
          ),
        ),
      );
    }

    group('renders', () {
      testWidgets('displays positive delta with + prefix', (tester) async {
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: 5,
          totalAfter: 10,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(record: record));

        expect(find.text('+5'), findsOneWidget);
      });

      testWidgets('displays negative delta without + prefix', (tester) async {
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: -3,
          totalAfter: 7,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(record: record));

        expect(find.text('-3'), findsOneWidget);
        expect(find.text('+'), findsNothing);
      });

      testWidgets('displays zero delta', (tester) async {
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: 0,
          totalAfter: 5,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(record: record));

        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('displays totalAfter', (tester) async {
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: 3,
          totalAfter: 42,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(record: record));

        expect(find.text('累计: 42'), findsOneWidget);
      });

      testWidgets('displays formatted date', (tester) async {
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: 1,
          totalAfter: 1,
          createdAt: DateTime(2026, 5, 11, 14, 30),
        );

        await tester.pumpWidget(buildTile(record: record));

        // Format: MM-dd HH:mm
        expect(find.text('05-11 14:30'), findsOneWidget);
      });

      testWidgets('displays up arrow icon for positive delta', (tester) async {
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: 5,
          totalAfter: 5,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(record: record));

        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
        expect(find.byIcon(Icons.arrow_downward), findsNothing);
      });

      testWidgets('displays down arrow icon for negative delta', (tester) async {
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: -5,
          totalAfter: 0,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(record: record));

        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward), findsNothing);
      });
    });

    group('delete button', () {
      testWidgets('shows delete icon when onDelete is provided', (tester) async {
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: 1,
          totalAfter: 1,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(record: record, onDelete: () {}));

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('hides delete icon when onDelete is null', (tester) async {
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: 1,
          totalAfter: 1,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(record: record, onDelete: null));

        expect(find.byIcon(Icons.delete_outline), findsNothing);
      });

      testWidgets('tapping delete icon opens confirmation bottom sheet', (tester) async {
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: 1,
          totalAfter: 1,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(record: record, onDelete: () {}));

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('删除记录'), findsOneWidget);
        expect(find.text('确定要删除这条记录吗？'), findsOneWidget);
        expect(find.text('确认删除'), findsOneWidget);
        expect(find.text('取消'), findsOneWidget);
      });

      testWidgets('cancel button closes bottom sheet without calling onDelete', (tester) async {
        bool deleteCalled = false;
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: 1,
          totalAfter: 1,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(
          record: record,
          onDelete: () => deleteCalled = true,
        ));

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();

        expect(deleteCalled, isFalse);
        expect(find.text('删除记录'), findsNothing);
      });

      testWidgets('confirm delete calls onDelete and closes sheet', (tester) async {
        bool deleteCalled = false;
        final record = CounterRecord(
          id: 1,
          projectId: 1,
          delta: 1,
          totalAfter: 1,
          createdAt: tNow,
        );

        await tester.pumpWidget(buildTile(
          record: record,
          onDelete: () => deleteCalled = true,
        ));

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        await tester.tap(find.text('确认删除'));
        await tester.pumpAndSettle();

        expect(deleteCalled, isTrue);
        expect(find.text('删除记录'), findsNothing);
      });
    });
  });
}
