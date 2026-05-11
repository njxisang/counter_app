import 'package:flutter_test/flutter_test.dart';
import 'package:counter_app/models/record.dart';

void main() {
  group('CounterRecord', () {
    final tNow = DateTime(2026, 5, 11, 14, 30, 0);

    group('constructor', () {
      test('creates with all required fields', () {
        final record = CounterRecord(
          projectId: 1,
          delta: 5,
          totalAfter: 10,
          createdAt: tNow,
        );

        expect(record.id, isNull);
        expect(record.projectId, 1);
        expect(record.delta, 5);
        expect(record.totalAfter, 10);
        expect(record.createdAt, tNow);
      });

      test('creates with optional id', () {
        final record = CounterRecord(
          id: 42,
          projectId: 3,
          delta: -2,
          totalAfter: 8,
          createdAt: tNow,
        );

        expect(record.id, 42);
        expect(record.projectId, 3);
        expect(record.delta, -2);
        expect(record.totalAfter, 8);
      });
    });

    group('toMap', () {
      test('toMap without id (insert mode)', () {
        final record = CounterRecord(
          projectId: 1,
          delta: 3,
          totalAfter: 7,
          createdAt: tNow,
        );
        final map = record.toMap();

        expect(map.containsKey('id'), isFalse);
        expect(map['project_id'], 1);
        expect(map['delta'], 3);
        expect(map['total_after'], 7);
        expect(map['created_at'], tNow.toIso8601String());
      });

      test('toMap with id (update mode)', () {
        final record = CounterRecord(
          id: 99,
          projectId: 2,
          delta: -1,
          totalAfter: 5,
          createdAt: tNow,
        );
        final map = record.toMap();

        expect(map['id'], 99);
      });

      test('toMap with negative delta', () {
        final record = CounterRecord(
          projectId: 1,
          delta: -10,
          totalAfter: 0,
          createdAt: tNow,
        );
        expect(record.toMap()['delta'], -10);
      });
    });

    group('fromMap', () {
      test('fromMap with all fields', () {
        final map = {
          'id': 7,
          'project_id': 2,
          'delta': 8,
          'total_after': 108,
          'created_at': '2026-05-11T14:30:00.000',
        };
        final record = CounterRecord.fromMap(map);

        expect(record.id, 7);
        expect(record.projectId, 2);
        expect(record.delta, 8);
        expect(record.totalAfter, 108);
        expect(record.createdAt, DateTime(2026, 5, 11, 14, 30, 0));
      });

      test('fromMap with negative delta', () {
        final map = {
          'project_id': 1,
          'delta': -5,
          'total_after': 95,
          'created_at': '2026-05-11T14:30:00.000',
        };
        final record = CounterRecord.fromMap(map);
        expect(record.delta, -5);
        expect(record.totalAfter, 95);
      });

      test('fromMap with zero delta', () {
        final map = {
          'project_id': 1,
          'delta': 0,
          'total_after': 100,
          'created_at': '2026-05-11T14:30:00.000',
        };
        final record = CounterRecord.fromMap(map);
        expect(record.delta, 0);
      });
    });

    group('equatable props', () {
      test('two records with same props are equal', () {
        final a = CounterRecord(id: 1, projectId: 1, delta: 5, totalAfter: 10, createdAt: tNow);
        final b = CounterRecord(id: 1, projectId: 1, delta: 5, totalAfter: 10, createdAt: tNow);
        expect(a, equals(b));
      });

      test('two records with different delta are not equal', () {
        final a = CounterRecord(id: 1, projectId: 1, delta: 5, totalAfter: 10, createdAt: tNow);
        final b = CounterRecord(id: 1, projectId: 1, delta: 6, totalAfter: 10, createdAt: tNow);
        expect(a, isNot(equals(b)));
      });

      test('two records with different totalAfter are not equal', () {
        final a = CounterRecord(id: 1, projectId: 1, delta: 5, totalAfter: 10, createdAt: tNow);
        final b = CounterRecord(id: 1, projectId: 1, delta: 5, totalAfter: 11, createdAt: tNow);
        expect(a, isNot(equals(b)));
      });
    });

    group('round-trip (toMap -> fromMap)', () {
      test('preserves all data through toMap/fromMap', () {
        final original = CounterRecord(
          id: 12,
          projectId: 5,
          delta: -7,
          totalAfter: 93,
          createdAt: tNow,
        );
        final restored = CounterRecord.fromMap(original.toMap());

        expect(restored.id, 12);
        expect(restored.projectId, 5);
        expect(restored.delta, -7);
        expect(restored.totalAfter, 93);
        expect(restored.createdAt, tNow);
      });
    });
  });
}
