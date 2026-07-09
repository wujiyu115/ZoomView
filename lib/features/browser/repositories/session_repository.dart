import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/core/logger/app_logger.dart';
import '../models/tab_model.dart';

class SessionData {
  final List<TabModel> tabs;
  final int activeIndex;
  const SessionData(this.tabs, this.activeIndex);
}

class SessionRepository {
  final DatabaseHelper _dbHelper;
  SessionRepository(this._dbHelper);

  static const _tabsKey = 'session_tabs';
  static const _activeKey = 'session_active';

  Future<void> save(List<TabModel> tabs, int activeIndex) async {
    final db = await _dbHelper.database;
    final jsonStr = jsonEncode(tabs.map((t) => t.toJson()).toList());
    await db.insert('settings', {'key': _tabsKey, 'value': jsonStr},
        conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('settings', {'key': _activeKey, 'value': activeIndex.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<SessionData?> load() async {
    final db = await _dbHelper.database;
    final rows = await db.query('settings',
        where: 'key IN (?, ?)', whereArgs: [_tabsKey, _activeKey]);
    if (rows.isEmpty) return null;
    final map = {for (final r in rows) r['key'] as String: r['value'] as String};
    final jsonStr = map[_tabsKey];
    if (jsonStr == null) return null;
    try {
      final list = jsonDecode(jsonStr) as List;
      if (list.isEmpty) return null;
      final tabs = list
          .map((e) => TabModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final activeIndex = int.tryParse(map[_activeKey] ?? '0') ?? 0;
      return SessionData(tabs, activeIndex);
    } catch (e) {
      AppLogger.instance.d('Session', 'Failed to parse session: $e');
      return null;
    }
  }

  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('settings',
        where: 'key IN (?, ?)', whereArgs: [_tabsKey, _activeKey]);
  }
}
