import '../database_helper.dart';
import '../../models/project.dart';

class ProjectRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> create(CounterProject project) async {
    final db = await _dbHelper.database;
    return await db.insert('projects', project.toMap());
  }

  Future<List<CounterProject>> getAll() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'projects',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => CounterProject.fromMap(map)).toList();
  }

  Future<CounterProject?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return CounterProject.fromMap(result.first);
  }

  Future<int> update(CounterProject project) async {
    final db = await _dbHelper.database;
    return await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    // CASCADE constraint in DDL handles records deletion automatically
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }
}
