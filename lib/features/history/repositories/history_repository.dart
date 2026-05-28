import 'package:zoomview/core/database/database_helper.dart';
import '../models/history_model.dart';

class HistoryRepository {
  final DatabaseHelper _dbHelper;
  HistoryRepository(this._dbHelper);

  Future<void> addEntry(String title, String url) async {
    final db = await _dbHelper.database;
    await db.insert('history', {
      'title': title,
      'url': url,
      'visited_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<HistoryModel>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('history', orderBy: 'visited_at DESC');
    return rows.map((r) => HistoryModel.fromMap(r)).toList();
  }

  Future<void> deleteEntry(int id) async {
    final db = await _dbHelper.database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('history');
  }

  Future<List<HistoryModel>> search(String query) async {
    final db = await _dbHelper.database;
    final rows = await db.query('history',
        where: 'title LIKE ? OR url LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'visited_at DESC');
    return rows.map((r) => HistoryModel.fromMap(r)).toList();
  }
}
