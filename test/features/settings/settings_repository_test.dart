import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/features/settings/models/settings_model.dart';
import 'package:zoomview/features/settings/repositories/settings_repository.dart';

void main() {
  late DatabaseHelper dbHelper;
  late SettingsRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting();
    repo = SettingsRepository(dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('loadAll returns defaults when DB is empty', () async {
    final settings = await repo.loadAll();
    expect(settings.uaMode, UaMode.desktop);
    expect(settings.searchEngine, 'Google');
    expect(settings.homeUrl, 'https://www.google.com');
    expect(settings.viewportWidth, 1920);
    expect(settings.defaultZoom, 1.0);
    expect(settings.darkMode, true);
  });

  test('save and load round-trips correctly', () async {
    await repo.set('ua_mode', 'mobile');
    await repo.set('search_engine', 'Bing');
    final settings = await repo.loadAll();
    expect(settings.uaMode, UaMode.mobile);
    expect(settings.searchEngine, 'Bing');
  });

  test('set overwrites existing key', () async {
    await repo.set('home_url', 'https://example.com');
    await repo.set('home_url', 'https://changed.com');
    final settings = await repo.loadAll();
    expect(settings.homeUrl, 'https://changed.com');
  });
}
