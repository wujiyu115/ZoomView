import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/features/browser/models/tab_model.dart';
import 'package:zoomview/features/browser/repositories/session_repository.dart';

void main() {
  late DatabaseHelper dbHelper;
  late SessionRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    dbHelper = DatabaseHelper.forTesting();
    repo = SessionRepository(dbHelper);
  });

  tearDown(() async => dbHelper.close());

  test('load returns null when nothing stored', () async {
    expect(await repo.load(), isNull);
  });

  test('save then load round-trips tabs and active index', () async {
    final tabs = [
      TabModel(url: 'https://a.com', title: 'A', zoomLevel: 1.5, scrollPosition: 100),
      TabModel(url: 'https://b.com', title: 'B'),
    ];
    await repo.save(tabs, 1);
    final data = await repo.load();
    expect(data, isNotNull);
    expect(data!.tabs.length, 2);
    expect(data.tabs[0].url, 'https://a.com');
    expect(data.tabs[0].zoomLevel, 1.5);
    expect(data.tabs[0].scrollPosition, 100.0);
    expect(data.tabs[1].url, 'https://b.com');
    expect(data.activeIndex, 1);
  });

  test('save empty list makes load return null', () async {
    await repo.save([], 0);
    expect(await repo.load(), isNull);
  });

  test('clear removes stored session', () async {
    await repo.save([TabModel(url: 'https://a.com')], 0);
    await repo.clear();
    expect(await repo.load(), isNull);
  });

  test('load returns null on malformed json', () async {
    final db = await dbHelper.database;
    await db.insert('settings', {'key': 'session_tabs', 'value': '{not json'},
        conflictAlgorithm: ConflictAlgorithm.replace);
    expect(await repo.load(), isNull);
  });
}
