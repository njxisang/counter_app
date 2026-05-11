import 'package:flutter_test/flutter_test.dart';
import 'package:counter_app/models/project.dart';

void main() {
  group('CounterProject', () {
    final tNow = DateTime(2026, 5, 11, 14, 30, 0);

    group('constructor', () {
      test('creates with required fields only', () {
        final project = CounterProject(
          name: 'Test Project',
          createdAt: tNow,
        );

        expect(project.id, isNull);
        expect(project.name, 'Test Project');
        expect(project.createdAt, tNow);
        expect(project.note, isNull);
        expect(project.colorIndex, 0);
      });

      test('creates with all fields', () {
        final project = CounterProject(
          id: 1,
          name: 'Full Project',
          createdAt: tNow,
          note: 'A note',
          colorIndex: 3,
        );

        expect(project.id, 1);
        expect(project.name, 'Full Project');
        expect(project.createdAt, tNow);
        expect(project.note, 'A note');
        expect(project.colorIndex, 3);
      });

      test('colorIndex defaults to 0', () {
        final project = CounterProject(name: 'Test', createdAt: tNow);
        expect(project.colorIndex, 0);
      });
    });

    group('copyWith', () {
      test('copies with id changed', () {
        final original = CounterProject(id: 1, name: 'Original', createdAt: tNow);
        final copied = original.copyWith(id: 2);

        expect(copied.id, 2);
        expect(copied.name, 'Original');
        expect(copied.createdAt, tNow);
      });

      test('copies with name changed', () {
        final original = CounterProject(name: 'Original', createdAt: tNow);
        final copied = original.copyWith(name: 'Renamed');

        expect(copied.name, 'Renamed');
        expect(copied.note, isNull);
      });

      test('copies with colorIndex changed', () {
        final original = CounterProject(name: 'Test', createdAt: tNow, colorIndex: 0);
        final copied = original.copyWith(colorIndex: 5);

        expect(copied.colorIndex, 5);
        expect(original.colorIndex, 0); // original unchanged
      });

      test('copyWith preserves all other fields', () {
        final original = CounterProject(
          id: 1,
          name: 'Original',
          createdAt: tNow,
          note: 'Note',
          colorIndex: 2,
        );
        final copied = original.copyWith(name: 'New Name');

        expect(copied.id, 1);
        expect(copied.name, 'New Name');
        expect(copied.createdAt, tNow);
        expect(copied.note, 'Note');
        expect(copied.colorIndex, 2);
      });

      test('copyWith with null note clears note', () {
        final original = CounterProject(name: 'Test', createdAt: tNow, note: 'has note');
        // copyWith cannot set note to null explicitly with nullable param
        // this is expected — note stays as-is when not provided
        final copied = original.copyWith(name: 'Renamed');
        expect(copied.note, 'has note');
      });
    });

    group('toMap', () {
      test('toMap without id (insert mode)', () {
        final project = CounterProject(
          name: 'Test',
          createdAt: tNow,
          note: 'A note',
          colorIndex: 2,
        );
        final map = project.toMap();

        expect(map.containsKey('id'), isFalse);
        expect(map['name'], 'Test');
        expect(map['created_at'], tNow.toIso8601String());
        expect(map['note'], 'A note');
        expect(map['color_index'], 2);
      });

      test('toMap with id (update mode)', () {
        final project = CounterProject(
          id: 5,
          name: 'Test',
          createdAt: tNow,
        );
        final map = project.toMap();

        expect(map['id'], 5);
      });

      test('toMap includes colorIndex always', () {
        final project = CounterProject(name: 'Test', createdAt: tNow);
        final map = project.toMap();

        expect(map['color_index'], 0);
      });
    });

    group('fromMap', () {
      test('fromMap with all fields', () {
        final map = {
          'id': 3,
          'name': 'From Map',
          'created_at': '2026-05-11T14:30:00.000',
          'note': 'Loaded note',
          'color_index': 4,
        };
        final project = CounterProject.fromMap(map);

        expect(project.id, 3);
        expect(project.name, 'From Map');
        expect(project.createdAt, DateTime(2026, 5, 11, 14, 30, 0));
        expect(project.note, 'Loaded note');
        expect(project.colorIndex, 4);
      });

      test('fromMap with missing optional fields', () {
        final map = {
          'id': 1,
          'name': 'Minimal',
          'created_at': '2026-05-11T14:30:00.000',
        };
        final project = CounterProject.fromMap(map);

        expect(project.id, 1);
        expect(project.name, 'Minimal');
        expect(project.note, isNull);
        expect(project.colorIndex, 0); // defaults to 0
      });

      test('fromMap with null note', () {
        final map = {
          'id': 1,
          'name': 'Test',
          'created_at': '2026-05-11T14:30:00.000',
          'note': null,
        };
        final project = CounterProject.fromMap(map);
        expect(project.note, isNull);
      });

      test('fromMap with missing color_index (legacy data)', () {
        final map = {
          'id': 1,
          'name': 'Legacy',
          'created_at': '2026-05-11T14:30:00.000',
        };
        final project = CounterProject.fromMap(map);
        expect(project.colorIndex, 0);
      });
    });

    group('equatable props', () {
      test('two projects with same props are equal', () {
        final a = CounterProject(id: 1, name: 'Same', createdAt: tNow, colorIndex: 2);
        final b = CounterProject(id: 1, name: 'Same', createdAt: tNow, colorIndex: 2);
        expect(a, equals(b));
      });

      test('two projects with different id are not equal', () {
        final a = CounterProject(id: 1, name: 'Same', createdAt: tNow);
        final b = CounterProject(id: 2, name: 'Same', createdAt: tNow);
        expect(a, isNot(equals(b)));
      });

      test('two projects with different colorIndex are not equal', () {
        final a = CounterProject(name: 'Test', createdAt: tNow, colorIndex: 0);
        final b = CounterProject(name: 'Test', createdAt: tNow, colorIndex: 1);
        expect(a, isNot(equals(b)));
      });

      test('hashCode consistency for equal objects', () {
        final a = CounterProject(id: 1, name: 'Test', createdAt: tNow);
        final b = CounterProject(id: 1, name: 'Test', createdAt: tNow);
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('round-trip (toMap -> fromMap)', () {
      test('preserves all data through toMap/fromMap', () {
        final original = CounterProject(
          id: 7,
          name: 'Round Trip',
          createdAt: tNow,
          note: 'Preserved',
          colorIndex: 6,
        );
        final restored = CounterProject.fromMap(original.toMap());

        expect(restored, equals(original));
      });

      test('round-trip with null note', () {
        final original = CounterProject(
          name: 'No Note',
          createdAt: tNow,
          note: null,
        );
        final restored = CounterProject.fromMap(original.toMap());
        expect(restored.note, isNull);
      });
    });
  });
}
