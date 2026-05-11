import 'package:flutter_test/flutter_test.dart';
import 'package:counter_app/models/record.dart';

// ---------------------------------------------------------------------------
// Mock Record Db — mirrors RecordRepository method signatures
// ---------------------------------------------------------------------------
class MockRecordDb {
  final List<Map<String, dynamic>> _records = [];
  int _nextId = 1;

  Future<int> insert(String table, Map<String, dynamic> map) async {
    final record = Map<String, dynamic>.from(map);
    record['id'] = _nextId++;
    _records.add(record);
    return record['id'] as int;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    var results = List<Map<String, dynamic>>.from(_records);

    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      results = _applyWhere(results, where, whereArgs);
    }
    if (orderBy != null) {
      results = _applyOrderBy(results, orderBy);
    }
    return results;
  }

  Future<int> rawQuery(String sql, List<Object?> args) async {
    if (sql.contains('SUM(delta)')) {
      final pid = args[0] as int;
      int sum = 0;
      for (final r in _records) {
        if (r['project_id'] == pid) {
          sum += (r['delta'] as int?) ?? 0;
        }
      }
      return sum;
    }
    return 0;
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    if (where == null || whereArgs == null) return 0;
    final before = _records.length;
    _records.removeWhere((r) {
      final idVal = r['id'];
      return idVal == whereArgs[0];
    });
    return before - _records.length;
  }

  List<Map<String, dynamic>> _applyWhere(
    List<Map<String, dynamic>> rows,
    String where,
    List<Object?>? args,
  ) {
    if (where.contains('project_id = ?') && !where.contains('created_at')) {
      final pid = args?.first as int?;
      return rows.where((r) => r['project_id'] == pid).toList();
    }
    if (where.contains('project_id = ? AND created_at')) {
      final pid = args?[0] as int?;
      final start = args?[1] as String?;
      final end = args?[2] as String?;
      return rows.where((r) {
        if (r['project_id'] != pid) return false;
        final createdAt = (r['created_at'] as String);
        return createdAt.compareTo(start!) >= 0 && createdAt.compareTo(end!) <= 0;
      }).toList();
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
      } else {
        cmp = av.toString().compareTo(bv.toString());
      }
      return desc ? -cmp : cmp;
    });
  }

  void reset() {
    _records.clear();
    _nextId = 1;
  }
}

// ---------------------------------------------------------------------------
// RecordRepository API — same interface, implemented against MockRecordDb
// ---------------------------------------------------------------------------
abstract class RecordRepositoryInterface {
  Future<int> create(CounterRecord record);
  Future<List<CounterRecord>> getByProjectId(int projectId);
  Future<List<CounterRecord>> getByProjectIdAndDateRange(
    int projectId,
    DateTime start,
    DateTime end,
  );
  Future<int> getTotalByProjectId(int projectId);
  Future<int> delete(int id);
  Future<int> deleteByProjectId(int projectId);
}

class _TestRecordRepository implements RecordRepositoryInterface {
  final MockRecordDb _mock;

  _TestRecordRepository(this._mock);

  @override
  Future<int> create(CounterRecord record) async {
    final map = record.toMap();
    map.remove('id');
    return await _mock.insert('records', map);
  }

  @override
  Future<List<CounterRecord>> getByProjectId(int projectId) async {
    final results = await _mock.query(
      'records',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => CounterRecord.fromMap(_fixMap(m))).toList();
  }

  @override
  Future<List<CounterRecord>> getByProjectIdAndDateRange(
    int projectId,
    DateTime start,
    DateTime end,
  ) async {
    final results = await _mock.query(
      'records',
      where: 'project_id = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [
        projectId,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'created_at ASC',
    );
    return results.map((m) => CounterRecord.fromMap(_fixMap(m))).toList();
  }

  @override
  Future<int> getTotalByProjectId(int projectId) async {
    int sum = 0;
    for (final r in _mock._records) {
      if (r['project_id'] == projectId) {
        sum += (r['delta'] as int?) ?? 0;
      }
    }
    return sum;
  }

  @override
  Future<int> delete(int id) async {
    return await _mock.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> deleteByProjectId(int projectId) async {
    final before = _mock._records.length;
    _mock._records.removeWhere((r) => r['project_id'] == projectId);
    return before - _mock._records.length;
  }

  Map<String, dynamic> _fixMap(Map<String, dynamic> m) => Map<String, dynamic>.from(m);
}

void main() {
  late MockRecordDb mockDb;
  late RecordRepositoryInterface repository;

  setUp(() {
    mockDb = MockRecordDb();
    repository = _TestRecordRepository(mockDb);
  });

  tearDown(() {
    mockDb.reset();
  });

  group('RecordRepository (mock)', () {
    group('create', () {
      test('inserts record with auto-generated id', () async {
        final record = CounterRecord(
          projectId: 1,
          delta: 10,
          totalAfter: 10,
          createdAt: DateTime(2026, 5, 11),
        );

        final id = await repository.create(record);

        expect(id, greaterThan(0));
        final all = await repository.getByProjectId(1);
        expect(all.length, 1);
        expect(all.first.delta, 10);
      });

      test('inserts multiple records for same project', () async {
        await repository.create(CounterRecord(
          projectId: 1, delta: 5, totalAfter: 5, createdAt: DateTime(2026, 5, 11),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: 3, totalAfter: 8, createdAt: DateTime(2026, 5, 12),
        ));

        final all = await repository.getByProjectId(1);
        expect(all.length, 2);
      });
    });

    group('getByProjectId', () {
      test('returns records for correct project only', () async {
        await repository.create(CounterRecord(
          projectId: 1, delta: 1, totalAfter: 1, createdAt: DateTime(2026, 5, 11),
        ));
        await repository.create(CounterRecord(
          projectId: 2, delta: 100, totalAfter: 100, createdAt: DateTime(2026, 5, 11),
        ));

        final p1Records = await repository.getByProjectId(1);
        final p2Records = await repository.getByProjectId(2);

        expect(p1Records.length, 1);
        expect(p1Records.first.delta, 1);
        expect(p2Records.length, 1);
        expect(p2Records.first.delta, 100);
      });

      test('returns records ordered by created_at DESC', () async {
        await repository.create(CounterRecord(
          projectId: 1, delta: 1, totalAfter: 1, createdAt: DateTime(2026, 5, 1),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: 2, totalAfter: 3, createdAt: DateTime(2026, 5, 10),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: 3, totalAfter: 6, createdAt: DateTime(2026, 5, 5),
        ));

        final records = await repository.getByProjectId(1);
        expect(records.length, 3);
        expect(records[0].delta, 2); // newest first
        expect(records[1].delta, 3);
        expect(records[2].delta, 1);
      });

      test('returns empty list for project with no records', () async {
        final records = await repository.getByProjectId(999);
        expect(records, isEmpty);
      });
    });

    group('getTotalByProjectId', () {
      test('returns sum of all deltas', () async {
        await repository.create(CounterRecord(
          projectId: 1, delta: 5, totalAfter: 5, createdAt: DateTime(2026, 5, 1),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: -2, totalAfter: 3, createdAt: DateTime(2026, 5, 2),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: 10, totalAfter: 13, createdAt: DateTime(2026, 5, 3),
        ));

        final total = await repository.getTotalByProjectId(1);
        expect(total, 13);
      });

      test('returns 0 for project with no records', () async {
        final total = await repository.getTotalByProjectId(999);
        expect(total, 0);
      });

      test('negative deltas reduce total', () async {
        await repository.create(CounterRecord(
          projectId: 1, delta: 5, totalAfter: 5, createdAt: DateTime(2026, 5, 1),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: -3, totalAfter: 2, createdAt: DateTime(2026, 5, 2),
        ));

        final total = await repository.getTotalByProjectId(1);
        expect(total, 2);
      });
    });

    group('delete', () {
      test('removes specific record by id', () async {
        final id1 = await repository.create(CounterRecord(
          projectId: 1, delta: 1, totalAfter: 1, createdAt: DateTime(2026, 5, 1),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: 2, totalAfter: 3, createdAt: DateTime(2026, 5, 2),
        ));

        await repository.delete(id1);

        final all = await repository.getByProjectId(1);
        expect(all.length, 1);
        expect(all.first.delta, 2);
      });

      test('delete non-existent id returns 0', () async {
        final rows = await repository.delete(999);
        expect(rows, 0);
      });
    });

    group('getByProjectIdAndDateRange', () {
      test('filters records within date range', () async {
        await repository.create(CounterRecord(
          projectId: 1, delta: 1, totalAfter: 1, createdAt: DateTime(2026, 4, 30),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: 2, totalAfter: 3, createdAt: DateTime(2026, 5, 5),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: 3, totalAfter: 6, createdAt: DateTime(2026, 5, 10),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: 4, totalAfter: 10, createdAt: DateTime(2026, 5, 20),
        ));

        final records = await repository.getByProjectIdAndDateRange(
          1,
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 15),
        );
        expect(records.length, 2);
        expect(records[0].delta, 2);
        expect(records[1].delta, 3);
      });

      test('returns empty list when no records in range', () async {
        await repository.create(CounterRecord(
          projectId: 1, delta: 1, totalAfter: 1, createdAt: DateTime(2026, 1, 1),
        ));

        final records = await repository.getByProjectIdAndDateRange(
          1,
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 31),
        );
        expect(records, isEmpty);
      });
    });

    group('deleteByProjectId', () {
      test('removes all records for a project', () async {
        await repository.create(CounterRecord(
          projectId: 1, delta: 1, totalAfter: 1, createdAt: DateTime(2026, 5, 1),
        ));
        await repository.create(CounterRecord(
          projectId: 1, delta: 2, totalAfter: 3, createdAt: DateTime(2026, 5, 2),
        ));
        await repository.create(CounterRecord(
          projectId: 2, delta: 100, totalAfter: 100, createdAt: DateTime(2026, 5, 1),
        ));

        await repository.deleteByProjectId(1);

        final p1Records = await repository.getByProjectId(1);
        final p2Records = await repository.getByProjectId(2);
        expect(p1Records, isEmpty);
        expect(p2Records.length, 1);
      });
    });
  });
}
