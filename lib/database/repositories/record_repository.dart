import '../database_helper.dart';
import '../../models/record.dart';

class RecordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> create(CounterRecord record) async {
    final db = await _dbHelper.database;
    return await db.insert('records', record.toMap());
  }

  Future<List<CounterRecord>> getByProjectId(int projectId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'records',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => CounterRecord.fromMap(map)).toList();
  }

  Future<List<CounterRecord>> getByProjectIdAndDateRange(
    int projectId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'records',
      where: 'project_id = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [
        projectId,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'created_at ASC',
    );
    return result.map((map) => CounterRecord.fromMap(map)).toList();
  }

  Future<int> getTotalByProjectId(int projectId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(delta) as total FROM records WHERE project_id = ?',
      [projectId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteByProjectId(int projectId) async {
    final db = await _dbHelper.database;
    return await db.delete('records', where: 'project_id = ?', whereArgs: [projectId]);
  }
}
