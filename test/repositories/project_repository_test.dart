import 'package:flutter_test/flutter_test.dart';
import 'package:counter_app/models/project.dart';

// ---------------------------------------------------------------------------
// Mock Database — list-based, synchronous, mirrors sqflite signatures
// ---------------------------------------------------------------------------
class MockProjectDb {
  final List<Map<String, dynamic>> _projects = [];
  int _nextId = 1;

  Future<int> insert(String table, Map<String, dynamic> map) async {
    final record = Map<String, dynamic>.from(map);
    record['id'] = _nextId++;
    _projects.add(record);
    return record['id'] as int;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    var results = List<Map<String, dynamic>>.from(_projects);

    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      results = _applyWhere(results, where, whereArgs);
    }
    if (orderBy != null) {
      results = _applyOrderBy(results, orderBy);
    }
    if (limit != null && results.length > limit) {
      results = results.sublist(0, limit);
    }
    return results;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (where == null || whereArgs == null) return 0;
    final filtered = _applyWhere(_projects.toList(), where, whereArgs);
    for (final row in filtered) {
      row.addAll(values);
    }
    return filtered.length;
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (where == null || whereArgs == null) return 0;
    final before = _projects.length;
    _projects.removeWhere((row) {
      // Simple: "id = ?"
      final idVal = row['id'];
      return idVal == whereArgs[0];
    });
    return before - _projects.length;
  }

  List<Map<String, dynamic>> _applyWhere(
    List<Map<String, dynamic>> rows,
    String where,
    List<Object?>? args,
  ) {
    if (where.contains('id = ?')) {
      final idVal = args?.first;
      return rows.where((r) => r['id'] == idVal).toList();
    }
    return rows;
  }

  List<Map<String, dynamic>> _applyOrderBy(
    List<Map<String, dynamic>> rows,
    String orderBy,
  ) {
    final parts = orderBy.split(' ');
    final field = parts[0];
    final desc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';

    return List.from(rows)..sort((a, b) {
      final av = a[field];
      final bv = b[field];
      int cmp;
      if (av is String && bv is String) {
        cmp = av.compareTo(bv);
      } else if (av is DateTime && bv is DateTime) {
        cmp = av.compareTo(bv);
      } else {
        cmp = av.toString().compareTo(bv.toString());
      }
      return desc ? -cmp : cmp;
    });
  }

  void reset() {
    _projects.clear();
    _nextId = 1;
  }
}

// ---------------------------------------------------------------------------
// ProjectRepository API — same interface, implemented against MockProjectDb
// ---------------------------------------------------------------------------
abstract class ProjectRepositoryInterface {
  Future<int> create(CounterProject project);
  Future<List<CounterProject>> getAll();
  Future<CounterProject?> getById(int id);
  Future<int> update(CounterProject project);
  Future<int> delete(int id);
}

class _TestProjectRepository implements ProjectRepositoryInterface {
  final MockProjectDb _mock;

  _TestProjectRepository(this._mock);

  @override
  Future<int> create(CounterProject project) async {
    final map = project.toMap();
    map.remove('id');
    final id = await _mock.insert('projects', map);
    return id;
  }

  @override
  Future<List<CounterProject>> getAll() async {
    final results = await _mock.query('projects', orderBy: 'created_at DESC');
    return results.map((m) => CounterProject.fromMap(_fixMap(m))).toList();
  }

  @override
  Future<CounterProject?> getById(int id) async {
    final results = await _mock.query('projects', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return CounterProject.fromMap(_fixMap(results.first));
  }

  @override
  Future<int> update(CounterProject project) async {
    final map = project.toMap();
    return await _mock.update('projects', map, where: 'id = ?', whereArgs: [project.id]);
  }

  @override
  Future<int> delete(int id) async {
    return await _mock.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _fixMap(Map<String, dynamic> m) => Map<String, dynamic>.from(m);
}

void main() {
  late MockProjectDb mockDb;
  late ProjectRepositoryInterface repository;

  setUp(() {
    mockDb = MockProjectDb();
    repository = _TestProjectRepository(mockDb);
  });

  tearDown(() {
    mockDb.reset();
  });

  group('ProjectRepository (mock)', () {
    group('create', () {
      test('inserts project and returns auto-generated id', () async {
        final project = CounterProject(
          name: 'My Project',
          createdAt: DateTime(2026, 5, 11),
          note: 'Test note',
          colorIndex: 3,
        );

        final id = await repository.create(project);

        expect(id, greaterThan(0));
        final retrieved = await repository.getById(id);
        expect(retrieved, isNotNull);
        expect(retrieved!.name, 'My Project');
        expect(retrieved.note, 'Test note');
        expect(retrieved.colorIndex, 3);
      });

      test('inserts multiple projects with unique ids', () async {
        final id1 = await repository.create(CounterProject(
          name: 'Project 1',
          createdAt: DateTime(2026, 1, 1),
        ));
        final id2 = await repository.create(CounterProject(
          name: 'Project 2',
          createdAt: DateTime(2026, 2, 1),
        ));

        expect(id1, isNot(equals(id2)));
      });
    });

    group('getAll', () {
      test('returns projects ordered by created_at DESC', () async {
        await repository.create(CounterProject(
          name: 'Older',
          createdAt: DateTime(2026, 1, 1),
        ));
        await repository.create(CounterProject(
          name: 'Newer',
          createdAt: DateTime(2026, 6, 1),
        ));
        await repository.create(CounterProject(
          name: 'Middle',
          createdAt: DateTime(2026, 4, 1),
        ));

        final all = await repository.getAll();
        expect(all.length, 3);
        expect(all[0].name, 'Newer');
        expect(all[1].name, 'Middle');
        expect(all[2].name, 'Older');
      });

      test('returns empty list when no projects', () async {
        final all = await repository.getAll();
        expect(all, isEmpty);
      });
    });

    group('getById', () {
      test('returns correct project', () async {
        final id = await repository.create(CounterProject(
          name: 'Find Me',
          createdAt: DateTime(2026, 5, 1),
          colorIndex: 7,
        ));

        final project = await repository.getById(id);
        expect(project!.name, 'Find Me');
        expect(project.colorIndex, 7);
      });

      test('returns null for non-existent id', () async {
        final result = await repository.getById(999);
        expect(result, isNull);
      });
    });

    group('update', () {
      test('updates name, note, and colorIndex', () async {
        final id = await repository.create(CounterProject(
          name: 'Original',
          createdAt: DateTime(2026, 5, 1),
          colorIndex: 0,
        ));

        final updated = CounterProject(
          id: id,
          name: 'Updated',
          createdAt: DateTime(2026, 5, 1),
          note: 'New note',
          colorIndex: 6,
        );
        await repository.update(updated);

        final project = await repository.getById(id);
        expect(project!.name, 'Updated');
        expect(project.note, 'New note');
        expect(project.colorIndex, 6);
      });

      test('update non-existent returns 0', () async {
        final updated = CounterProject(
          id: 999,
          name: 'Ghost',
          createdAt: DateTime(2026, 5, 1),
        );
        final rows = await repository.update(updated);
        expect(rows, 0);
      });
    });

    group('delete', () {
      test('removes project from database', () async {
        final id = await repository.create(CounterProject(
          name: 'To Delete',
          createdAt: DateTime(2026, 5, 1),
        ));

        await repository.delete(id);

        final project = await repository.getById(id);
        expect(project, isNull);
      });

      test('delete non-existent returns 0', () async {
        final rows = await repository.delete(999);
        expect(rows, 0);
      });

      test('getAll after delete excludes removed project', () async {
        final id = await repository.create(CounterProject(
          name: 'Stay',
          createdAt: DateTime(2026, 5, 1),
        ));
        await repository.create(CounterProject(
          name: 'Go',
          createdAt: DateTime(2026, 6, 1),
        ));

      await repository.delete(id);

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all.first.name, 'Go'); // id=2 (Go) remains after deleting id=1 (Stay)
      });
    });

    group('colorIndex persistence', () {
      test('all 8 color indices stored and retrieved correctly', () async {
        for (var i = 0; i < 8; i++) {
          final id = await repository.create(CounterProject(
            name: 'Color $i',
            createdAt: DateTime(2026, 5, 1),
            colorIndex: i,
          ));
          final project = await repository.getById(id);
          expect(project!.colorIndex, i, reason: 'Color index $i failed');
        }
      });
    });
  });
}
