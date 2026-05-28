import 'package:sqflite/sqflite.dart';
import 'package:zoomview/core/database/database_helper.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper;

  SettingsRepository(this._dbHelper);

  Future<SettingsModel> loadAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('settings');
    final map = <String, String>{};
    for (final row in rows) {
      map[row['key'] as String] = row['value'] as String;
    }
    return SettingsModel.fromMap(map);
  }

  Future<void> set(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
