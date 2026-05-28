import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/features/history/repositories/history_repository.dart';

void main() {
  late DatabaseHelper dbHelper;
  late HistoryRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting();
    repo = HistoryRepository(dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('addEntry and getAll', () async {
    await repo.addEntry('Google', 'https://google.com');
    await repo.addEntry('GitHub', 'https://github.com');
    final entries = await repo.getAll();
    expect(entries.length, 2);
  });

  test('getAll returns newest first', () async {
    await repo.addEntry('First', 'https://first.com');
    await Future.delayed(const Duration(milliseconds: 10));
    await repo.addEntry('Second', 'https://second.com');
    final entries = await repo.getAll();
    expect(entries.first.title, 'Second');
  });

  test('deleteEntry removes single entry', () async {
    await repo.addEntry('Test', 'https://test.com');
    final entries = await repo.getAll();
    await repo.deleteEntry(entries.first.id!);
    final after = await repo.getAll();
    expect(after, isEmpty);
  });

  test('clearAll removes everything', () async {
    await repo.addEntry('A', 'https://a.com');
    await repo.addEntry('B', 'https://b.com');
    await repo.clearAll();
    final after = await repo.getAll();
    expect(after, isEmpty);
  });

  test('search filters by title and URL', () async {
    await repo.addEntry('Flutter Dev', 'https://flutter.dev');
    await repo.addEntry('Dart Lang', 'https://dart.dev');
    await repo.addEntry('GitHub', 'https://github.com');
    final results = await repo.search('dev');
    expect(results.length, 2);
  });
}
