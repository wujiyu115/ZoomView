import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zoomview/core/database/database_helper.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting();
    await dbHelper.database;
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('database creates all tables', () async {
    final db = await dbHelper.database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    final tableNames = tables.map((t) => t['name'] as String).toSet();

    expect(tableNames, contains('bookmarks'));
    expect(tableNames, contains('bookmark_folders'));
    expect(tableNames, contains('downloads'));
    expect(tableNames, contains('history'));
    expect(tableNames, contains('settings'));
  });

  test('settings table supports key-value insert and query', () async {
    final db = await dbHelper.database;
    await db.insert('settings', {'key': 'test_key', 'value': 'test_value'});
    final result = await db.query('settings', where: 'key = ?', whereArgs: ['test_key']);
    expect(result.length, 1);
    expect(result.first['value'], 'test_value');
  });
}
