# ZoomView Browser Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter mobile browser (iOS + Android) that loads websites in desktop mode by default with a precision zoom slider.

**Architecture:** Single-project, feature-based structure. Riverpod for state management. SQLite for persistence. flutter_inappwebview for WebView rendering.

**Tech Stack:** Flutter 3.41, flutter_inappwebview 6.x, flutter_riverpod 2.x, sqflite, flutter_downloader

**Spec:** `docs/superpowers/specs/2026-05-28-zoomview-browser-design.md`

---

### Task 1: Project Scaffolding

**Files:**
- Create: Flutter project structure via `flutter create`
- Modify: `pubspec.yaml`
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1: Create Flutter project**

```bash
cd /home/ejoy/git/zoomview
flutter create . --org com.zoomview --project-name zoomview --platforms android,ios
```

- [ ] **Step 2: Add dependencies**

```bash
cd /home/ejoy/git/zoomview
flutter pub add flutter_inappwebview flutter_riverpod sqflite path_provider flutter_downloader flutter_local_notifications uuid share_plus url_launcher
flutter pub add --dev sqflite_common_ffi
```

- [ ] **Step 3: Configure Android — set minSdk and permissions**

In `android/app/build.gradle.kts`, set `minSdk` to 21 (required by flutter_inappwebview):

```kotlin
android {
    defaultConfig {
        minSdk = 21
    }
}
```

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>` before `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

Inside `<application>`, add the flutter_downloader provider:

```xml
<provider
    android:name="vn.hunghd.flutterdownloader.FlutterDownloaderFileProvider"
    android:authorities="${applicationId}.flutter_downloader.provider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/provider_paths"/>
</provider>
```

Create `android/app/src/main/res/xml/provider_paths.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external" path="."/>
    <external-files-path name="external_files" path="."/>
</paths>
```

- [ ] **Step 4: Configure iOS — add transport security and permissions**

In `ios/Runner/Info.plist`, add inside `<dict>`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to save downloaded files</string>
```

- [ ] **Step 5: Verify project compiles**

```bash
cd /home/ejoy/git/zoomview
flutter pub get
flutter analyze --no-fatal-infos
```

- [ ] **Step 6: Commit**

```bash
git init
git add -A
git commit -m "feat: scaffold Flutter project with dependencies"
```

---

### Task 2: Core — Theme & Constants

**Files:**
- Create: `lib/core/constants.dart`
- Create: `lib/core/theme.dart`
- Test: `test/core/constants_test.dart`

- [ ] **Step 1: Write constants test**

```dart
// test/core/constants_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zoomview/core/constants.dart';

void main() {
  test('desktop UA contains Windows and Chrome', () {
    expect(AppConstants.desktopUserAgent, contains('Windows NT'));
    expect(AppConstants.desktopUserAgent, contains('Chrome'));
  });

  test('zoom range is valid', () {
    expect(AppConstants.minZoom, lessThan(AppConstants.maxZoom));
    expect(AppConstants.defaultZoom, greaterThanOrEqualTo(AppConstants.minZoom));
    expect(AppConstants.defaultZoom, lessThanOrEqualTo(AppConstants.maxZoom));
  });

  test('default viewport width is 1920', () {
    expect(AppConstants.defaultViewportWidth, 1920);
  });

  test('search engine URLs contain query placeholder', () {
    for (final entry in AppConstants.searchEngines.entries) {
      expect(entry.value, contains('%s'), reason: '${entry.key} missing %s');
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/constants_test.dart
```

Expected: FAIL — `constants.dart` not found.

- [ ] **Step 3: Implement constants**

```dart
// lib/core/constants.dart
class AppConstants {
  AppConstants._();

  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  static const String mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36';

  static const double minZoom = 1.0;
  static const double maxZoom = 3.0;
  static const double defaultZoom = 1.0;
  static const double zoomStep = 0.1;
  static const int defaultViewportWidth = 1920;

  static const String defaultHomeUrl = 'https://www.google.com';

  static const Map<String, String> searchEngines = {
    'Google': 'https://www.google.com/search?q=%s',
    'Bing': 'https://www.bing.com/search?q=%s',
    'DuckDuckGo': 'https://duckduckgo.com/?q=%s',
  };

  static const int maxConcurrentDownloads = 3;
}
```

- [ ] **Step 4: Implement dark theme**

```dart
// lib/core/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Colors.blue,
        thumbColor: Colors.white,
        inactiveTrackColor: Colors.grey,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: Colors.white),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blue,
    );
  }
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/core/constants_test.dart
```

Expected: ALL PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/constants.dart lib/core/theme.dart test/core/constants_test.dart
git commit -m "feat: add theme and constants"
```

---

### Task 3: Core — Database Layer

**Files:**
- Create: `lib/core/database/tables.dart`
- Create: `lib/core/database/database_helper.dart`
- Test: `test/core/database/database_helper_test.dart`

- [ ] **Step 1: Write database test**

```dart
// test/core/database/database_helper_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/database/database_helper_test.dart
```

Expected: FAIL — files not found.

- [ ] **Step 3: Implement table definitions**

```dart
// lib/core/database/tables.dart
class Tables {
  Tables._();

  static const String bookmarkFolders = '''
    CREATE TABLE bookmark_folders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      parent_id INTEGER,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (parent_id) REFERENCES bookmark_folders(id) ON DELETE CASCADE
    )
  ''';

  static const String bookmarks = '''
    CREATE TABLE bookmarks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      url TEXT NOT NULL,
      favicon BLOB,
      folder_id INTEGER,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (folder_id) REFERENCES bookmark_folders(id) ON DELETE SET NULL
    )
  ''';

  static const String downloads = '''
    CREATE TABLE downloads (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      url TEXT NOT NULL,
      file_name TEXT NOT NULL,
      file_path TEXT NOT NULL,
      mime_type TEXT,
      total_bytes INTEGER NOT NULL DEFAULT 0,
      downloaded_bytes INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL
    )
  ''';

  static const String history = '''
    CREATE TABLE history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      url TEXT NOT NULL,
      favicon BLOB,
      visited_at TEXT NOT NULL
    )
  ''';

  static const String settings = '''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''';
}
```

- [ ] **Step 4: Implement database helper**

```dart
// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tables.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  Database? _database;
  final bool _isTesting;

  DatabaseHelper._() : _isTesting = false;
  DatabaseHelper.forTesting() : _isTesting = true;

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (_isTesting) {
      return openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _onCreate,
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'zoomview.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(Tables.bookmarkFolders);
    await db.execute(Tables.bookmarks);
    await db.execute(Tables.downloads);
    await db.execute(Tables.history);
    await db.execute(Tables.settings);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/core/database/database_helper_test.dart
```

Expected: ALL PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/ test/core/database/
git commit -m "feat: add SQLite database layer with table definitions"
```

---

### Task 4: Settings Feature

**Files:**
- Create: `lib/features/settings/models/settings_model.dart`
- Create: `lib/features/settings/repositories/settings_repository.dart`
- Create: `lib/features/settings/providers/settings_provider.dart`
- Create: `lib/features/settings/widgets/settings_screen.dart`
- Test: `test/features/settings/settings_repository_test.dart`
- Test: `test/features/settings/settings_provider_test.dart`

- [ ] **Step 1: Write repository test**

```dart
// test/features/settings/settings_repository_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/settings/settings_repository_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Implement settings model**

```dart
// lib/features/settings/models/settings_model.dart
enum UaMode { desktop, mobile }

class SettingsModel {
  final UaMode uaMode;
  final String searchEngine;
  final String homeUrl;
  final int viewportWidth;
  final double defaultZoom;
  final double minZoom;
  final double maxZoom;
  final bool darkMode;

  const SettingsModel({
    this.uaMode = UaMode.desktop,
    this.searchEngine = 'Google',
    this.homeUrl = 'https://www.google.com',
    this.viewportWidth = 1920,
    this.defaultZoom = 1.0,
    this.minZoom = 1.0,
    this.maxZoom = 3.0,
    this.darkMode = true,
  });

  SettingsModel copyWith({
    UaMode? uaMode,
    String? searchEngine,
    String? homeUrl,
    int? viewportWidth,
    double? defaultZoom,
    double? minZoom,
    double? maxZoom,
    bool? darkMode,
  }) {
    return SettingsModel(
      uaMode: uaMode ?? this.uaMode,
      searchEngine: searchEngine ?? this.searchEngine,
      homeUrl: homeUrl ?? this.homeUrl,
      viewportWidth: viewportWidth ?? this.viewportWidth,
      defaultZoom: defaultZoom ?? this.defaultZoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  static SettingsModel fromMap(Map<String, String> map) {
    return SettingsModel(
      uaMode: map['ua_mode'] == 'mobile' ? UaMode.mobile : UaMode.desktop,
      searchEngine: map['search_engine'] ?? 'Google',
      homeUrl: map['home_url'] ?? 'https://www.google.com',
      viewportWidth: int.tryParse(map['viewport_width'] ?? '') ?? 1920,
      defaultZoom: double.tryParse(map['default_zoom'] ?? '') ?? 1.0,
      minZoom: double.tryParse(map['min_zoom'] ?? '') ?? 1.0,
      maxZoom: double.tryParse(map['max_zoom'] ?? '') ?? 3.0,
      darkMode: map['dark_mode'] != 'false',
    );
  }
}
```

- [ ] **Step 4: Implement settings repository**

```dart
// lib/features/settings/repositories/settings_repository.dart
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
```

- [ ] **Step 5: Run repository tests**

```bash
flutter test test/features/settings/settings_repository_test.dart
```

Expected: ALL PASS.

- [ ] **Step 6: Implement settings provider**

```dart
// lib/features/settings/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/database/database_helper.dart';
import '../models/settings_model.dart';
import '../repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(DatabaseHelper.instance);
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(const SettingsModel());

  Future<void> load() async {
    state = await _repo.loadAll();
  }

  Future<void> setUaMode(UaMode mode) async {
    await _repo.set('ua_mode', mode == UaMode.mobile ? 'mobile' : 'desktop');
    state = state.copyWith(uaMode: mode);
  }

  Future<void> setSearchEngine(String engine) async {
    await _repo.set('search_engine', engine);
    state = state.copyWith(searchEngine: engine);
  }

  Future<void> setHomeUrl(String url) async {
    await _repo.set('home_url', url);
    state = state.copyWith(homeUrl: url);
  }

  Future<void> setViewportWidth(int width) async {
    await _repo.set('viewport_width', width.toString());
    state = state.copyWith(viewportWidth: width);
  }

  Future<void> setDefaultZoom(double zoom) async {
    await _repo.set('default_zoom', zoom.toString());
    state = state.copyWith(defaultZoom: zoom);
  }

  Future<void> setMinZoom(double zoom) async {
    await _repo.set('min_zoom', zoom.toString());
    state = state.copyWith(minZoom: zoom);
  }

  Future<void> setMaxZoom(double zoom) async {
    await _repo.set('max_zoom', zoom.toString());
    state = state.copyWith(maxZoom: zoom);
  }

  Future<void> setDarkMode(bool enabled) async {
    await _repo.set('dark_mode', enabled.toString());
    state = state.copyWith(darkMode: enabled);
  }
}
```

- [ ] **Step 7: Implement settings screen**

```dart
// lib/features/settings/widgets/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _sectionHeader('Browsing'),
          SwitchListTile(
            title: const Text('Desktop Mode'),
            subtitle: const Text('Load websites in desktop layout'),
            value: settings.uaMode == UaMode.desktop,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .setUaMode(v ? UaMode.desktop : UaMode.mobile),
          ),
          ListTile(
            title: const Text('Search Engine'),
            subtitle: Text(settings.searchEngine),
            onTap: () => _showSearchEnginePicker(context, ref, settings),
          ),
          ListTile(
            title: const Text('Home Page'),
            subtitle: Text(settings.homeUrl),
            onTap: () => _showHomeUrlEditor(context, ref, settings),
          ),
          ListTile(
            title: const Text('Viewport Width'),
            subtitle: Text('${settings.viewportWidth}px'),
            onTap: () => _showViewportPicker(context, ref, settings),
          ),
          _sectionHeader('Zoom'),
          ListTile(
            title: const Text('Default Zoom'),
            subtitle: Text('${(settings.defaultZoom * 100).round()}%'),
          ),
          _sectionHeader('Privacy'),
          ListTile(
            title: const Text('Clear Cookies'),
            leading: const Icon(Icons.cookie_outlined),
            onTap: () async {
              await CookieManager.instance().deleteAllCookies();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cookies cleared')),
                );
              }
            },
          ),
          ListTile(
            title: const Text('Clear Cache'),
            leading: const Icon(Icons.cached),
            onTap: () async {
              await InAppWebViewController.clearAllCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            },
          ),
          _sectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.darkMode,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setDarkMode(v),
          ),
          _sectionHeader('About'),
          const ListTile(
            title: Text('ZoomView Browser'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showSearchEnginePicker(
      BuildContext context, WidgetRef ref, SettingsModel settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Search Engine'),
        children: ['Google', 'Bing', 'DuckDuckGo']
            .map((e) => RadioListTile<String>(
                  title: Text(e),
                  value: e,
                  groupValue: settings.searchEngine,
                  onChanged: (v) {
                    ref.read(settingsProvider.notifier).setSearchEngine(v!);
                    Navigator.pop(ctx);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _showHomeUrlEditor(
      BuildContext context, WidgetRef ref, SettingsModel settings) {
    final controller = TextEditingController(text: settings.homeUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Home Page URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://...'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setHomeUrl(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showViewportPicker(
      BuildContext context, WidgetRef ref, SettingsModel settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Viewport Width'),
        children: [1280, 1920, 2560]
            .map((w) => RadioListTile<int>(
                  title: Text('${w}px'),
                  value: w,
                  groupValue: settings.viewportWidth,
                  onChanged: (v) {
                    ref.read(settingsProvider.notifier).setViewportWidth(v!);
                    Navigator.pop(ctx);
                  },
                ))
            .toList(),
      ),
    );
  }
}
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/settings/ test/features/settings/
git commit -m "feat: add settings feature with SQLite persistence"
```

---

### Task 5: Browser — Tab Model & Provider

**Files:**
- Create: `lib/features/browser/models/tab_model.dart`
- Create: `lib/features/browser/providers/browser_provider.dart`
- Test: `test/features/browser/browser_provider_test.dart`

- [ ] **Step 1: Write provider test**

```dart
// test/features/browser/browser_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoomview/features/browser/models/tab_model.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';

void main() {
  late ProviderContainer container;
  late BrowserNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(browserProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('initial state has one tab', () {
    final state = container.read(browserProvider);
    expect(state.tabs.length, 1);
    expect(state.activeTabIndex, 0);
  });

  test('addTab creates new tab and switches to it', () {
    notifier.addTab('https://example.com');
    final state = container.read(browserProvider);
    expect(state.tabs.length, 2);
    expect(state.activeTabIndex, 1);
    expect(state.tabs[1].url, 'https://example.com');
  });

  test('closeTab removes tab and adjusts index', () {
    notifier.addTab('https://example.com');
    notifier.closeTab(0);
    final state = container.read(browserProvider);
    expect(state.tabs.length, 1);
    expect(state.activeTabIndex, 0);
    expect(state.tabs[0].url, 'https://example.com');
  });

  test('closeTab on last tab creates new empty tab', () {
    notifier.closeTab(0);
    final state = container.read(browserProvider);
    expect(state.tabs.length, 1);
  });

  test('switchTab updates activeTabIndex', () {
    notifier.addTab('https://example.com');
    notifier.switchTab(0);
    expect(container.read(browserProvider).activeTabIndex, 0);
  });

  test('updateZoom clamps to range', () {
    notifier.updateZoom(0, 5.0);
    expect(container.read(browserProvider).tabs[0].zoomLevel, 3.0);
    notifier.updateZoom(0, 0.1);
    expect(container.read(browserProvider).tabs[0].zoomLevel, 1.0);
  });

  test('updateUrl changes tab URL', () {
    notifier.updateUrl(0, 'https://changed.com');
    expect(container.read(browserProvider).tabs[0].url, 'https://changed.com');
  });

  test('updateTitle changes tab title', () {
    notifier.updateTitle(0, 'New Title');
    expect(container.read(browserProvider).tabs[0].title, 'New Title');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/browser/browser_provider_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Implement tab model**

```dart
// lib/features/browser/models/tab_model.dart
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

class TabModel {
  final String id;
  final String url;
  final String title;
  final Uint8List? favicon;
  final double zoomLevel;
  final double scrollPosition;
  final bool isActive;
  final DateTime createdAt;

  TabModel({
    String? id,
    required this.url,
    this.title = '',
    this.favicon,
    this.zoomLevel = 1.0,
    this.scrollPosition = 0,
    this.isActive = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  TabModel copyWith({
    String? url,
    String? title,
    Uint8List? favicon,
    double? zoomLevel,
    double? scrollPosition,
    bool? isActive,
  }) {
    return TabModel(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      favicon: favicon ?? this.favicon,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
```

- [ ] **Step 4: Implement browser provider**

```dart
// lib/features/browser/providers/browser_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/constants.dart';
import '../models/tab_model.dart';

class BrowserState {
  final List<TabModel> tabs;
  final int activeTabIndex;
  final bool isLoading;
  final double progress;

  const BrowserState({
    required this.tabs,
    this.activeTabIndex = 0,
    this.isLoading = false,
    this.progress = 0,
  });

  TabModel get activeTab => tabs[activeTabIndex];

  BrowserState copyWith({
    List<TabModel>? tabs,
    int? activeTabIndex,
    bool? isLoading,
    double? progress,
  }) {
    return BrowserState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
    );
  }
}

final browserProvider =
    StateNotifierProvider<BrowserNotifier, BrowserState>((ref) {
  return BrowserNotifier();
});

class BrowserNotifier extends StateNotifier<BrowserState> {
  BrowserNotifier()
      : super(BrowserState(
          tabs: [TabModel(url: AppConstants.defaultHomeUrl)],
        ));

  void addTab(String url) {
    final newTab = TabModel(url: url);
    final newTabs = [...state.tabs, newTab];
    state = state.copyWith(tabs: newTabs, activeTabIndex: newTabs.length - 1);
  }

  void closeTab(int index) {
    if (state.tabs.length <= 1) {
      state = BrowserState(tabs: [TabModel(url: AppConstants.defaultHomeUrl)]);
      return;
    }
    final newTabs = [...state.tabs]..removeAt(index);
    var newIndex = state.activeTabIndex;
    if (index <= newIndex) {
      newIndex = (newIndex - 1).clamp(0, newTabs.length - 1);
    }
    state = state.copyWith(tabs: newTabs, activeTabIndex: newIndex);
  }

  void switchTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = state.copyWith(activeTabIndex: index);
    }
  }

  void updateZoom(int index, double zoom) {
    final clamped = zoom.clamp(AppConstants.minZoom, AppConstants.maxZoom);
    final newTabs = [...state.tabs];
    newTabs[index] = newTabs[index].copyWith(zoomLevel: clamped);
    state = state.copyWith(tabs: newTabs);
  }

  void updateUrl(int index, String url) {
    final newTabs = [...state.tabs];
    newTabs[index] = newTabs[index].copyWith(url: url);
    state = state.copyWith(tabs: newTabs);
  }

  void updateTitle(int index, String title) {
    final newTabs = [...state.tabs];
    newTabs[index] = newTabs[index].copyWith(title: title);
    state = state.copyWith(tabs: newTabs);
  }

  void updateFavicon(int index, dynamic favicon) {
    final newTabs = [...state.tabs];
    newTabs[index] = newTabs[index].copyWith(favicon: favicon);
    state = state.copyWith(tabs: newTabs);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setProgress(double progress) {
    state = state.copyWith(progress: progress);
  }
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/features/browser/browser_provider_test.dart
```

Expected: ALL PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/browser/models/ lib/features/browser/providers/ test/features/browser/
git commit -m "feat: add tab model and browser state provider"
```

---

### Task 6: Browser — WebView Container

**Files:**
- Create: `lib/features/browser/widgets/webview_container.dart`

> WebView is a platform view — cannot be widget tested. Manual verification on device required.

- [ ] **Step 1: Implement WebView container**

```dart
// lib/features/browser/widgets/webview_container.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/constants.dart';
import 'package:zoomview/features/settings/models/settings_model.dart';
import 'package:zoomview/features/settings/providers/settings_provider.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';
import 'package:zoomview/features/history/providers/history_provider.dart';

class WebViewContainer extends ConsumerStatefulWidget {
  final int tabIndex;
  final String initialUrl;
  final void Function(InAppWebViewController) onControllerCreated;

  const WebViewContainer({
    super.key,
    required this.tabIndex,
    required this.initialUrl,
    required this.onControllerCreated,
  });

  @override
  ConsumerState<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends ConsumerState<WebViewContainer> {
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final ua = settings.uaMode == UaMode.desktop
        ? AppConstants.desktopUserAgent
        : AppConstants.mobileUserAgent;

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      initialSettings: InAppWebViewSettings(
        userAgent: ua,
        builtInZoomControls: false,
        displayZoomControls: false,
        useWideViewPort: true,
        loadWithOverviewMode: true,
        supportZoom: true,
        javaScriptEnabled: true,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        widget.onControllerCreated(controller);
      },
      onLoadStart: (controller, url) {
        ref.read(browserProvider.notifier).setLoading(true);
        if (url != null) {
          ref
              .read(browserProvider.notifier)
              .updateUrl(widget.tabIndex, url.toString());
        }
      },
      onLoadStop: (controller, url) async {
        ref.read(browserProvider.notifier).setLoading(false);
        final title = await controller.getTitle() ?? '';
        ref.read(browserProvider.notifier).updateTitle(widget.tabIndex, title);

        if (url != null && title.isNotEmpty) {
          ref.read(historyProvider.notifier).addEntry(title, url.toString());
        }

        // Force enable zoom on pages that disable it
        await controller.evaluateJavascript(source: '''
          var meta = document.querySelector('meta[name="viewport"]');
          if (meta) {
            meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=10.0, user-scalable=yes');
          }
        ''');
      },
      onProgressChanged: (controller, progress) {
        ref.read(browserProvider.notifier).setProgress(progress / 100.0);
      },
      onDownloadStartRequest: (controller, request) {
        ref.read(downloadTriggerProvider.notifier).state = request;
      },
    );
  }
}

// Provider to broadcast download requests from WebView to download manager
final downloadTriggerProvider = StateProvider<DownloadStartRequest?>((ref) => null);
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/browser/widgets/webview_container.dart
git commit -m "feat: add WebView container with desktop mode config"
```

---

### Task 7: Browser — Zoom Slider

**Files:**
- Create: `lib/features/browser/widgets/zoom_slider.dart`
- Test: `test/features/browser/widgets/zoom_slider_test.dart`

- [ ] **Step 1: Write zoom slider test**

```dart
// test/features/browser/widgets/zoom_slider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoomview/features/browser/widgets/zoom_slider.dart';

void main() {
  testWidgets('displays current zoom percentage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomSlider(
            zoomLevel: 1.5,
            minZoom: 1.0,
            maxZoom: 3.0,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('150%'), findsOneWidget);
  });

  testWidgets('zoom out button decreases value', (tester) async {
    double zoom = 1.5;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomSlider(
            zoomLevel: zoom,
            minZoom: 1.0,
            maxZoom: 3.0,
            onChanged: (v) => zoom = v,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.zoom_out));
    expect(zoom, 1.4);
  });

  testWidgets('zoom in button increases value', (tester) async {
    double zoom = 1.5;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomSlider(
            zoomLevel: zoom,
            minZoom: 1.0,
            maxZoom: 3.0,
            onChanged: (v) => zoom = v,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.zoom_in));
    expect(zoom, 1.6);
  });

  testWidgets('zoom out clamps at min', (tester) async {
    double zoom = 1.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomSlider(
            zoomLevel: zoom,
            minZoom: 1.0,
            maxZoom: 3.0,
            onChanged: (v) => zoom = v,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.zoom_out));
    expect(zoom, 1.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/browser/widgets/zoom_slider_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Implement zoom slider**

```dart
// lib/features/browser/widgets/zoom_slider.dart
import 'package:flutter/material.dart';
import 'package:zoomview/core/constants.dart';

class ZoomSlider extends StatelessWidget {
  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onChanged;

  const ZoomSlider({
    super.key,
    required this.zoomLevel,
    required this.minZoom,
    required this.maxZoom,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              final newZoom =
                  (zoomLevel - AppConstants.zoomStep).clamp(minZoom, maxZoom);
              onChanged(double.parse(newZoom.toStringAsFixed(1)));
            },
          ),
          Expanded(
            child: Slider(
              value: zoomLevel,
              min: minZoom,
              max: maxZoom,
              divisions: ((maxZoom - minZoom) / AppConstants.zoomStep).round(),
              onChanged: (v) =>
                  onChanged(double.parse(v.toStringAsFixed(1))),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              final newZoom =
                  (zoomLevel + AppConstants.zoomStep).clamp(minZoom, maxZoom);
              onChanged(double.parse(newZoom.toStringAsFixed(1)));
            },
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${(zoomLevel * 100).round()}%',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/browser/widgets/zoom_slider_test.dart
```

Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/browser/widgets/zoom_slider.dart test/features/browser/widgets/
git commit -m "feat: add zoom slider widget"
```

---

### Task 8: Browser — URL Bar & Toolbar

**Files:**
- Create: `lib/features/browser/widgets/url_bar.dart`
- Create: `lib/features/browser/widgets/toolbar.dart`

- [ ] **Step 1: Implement URL bar**

```dart
// lib/features/browser/widgets/url_bar.dart
import 'package:flutter/material.dart';

class UrlBar extends StatefulWidget {
  final String url;
  final double progress;
  final bool isLoading;
  final ValueChanged<String> onSubmitted;

  const UrlBar({
    super.key,
    required this.url,
    required this.progress,
    required this.isLoading,
    required this.onSubmitted,
  });

  @override
  State<UrlBar> createState() => _UrlBarState();
}

class _UrlBarState extends State<UrlBar> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.url);
  }

  @override
  void didUpdateWidget(UrlBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.url != oldWidget.url) {
      _controller.text = widget.url;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onTap: () => setState(() => _isEditing = true),
                  onSubmitted: (value) {
                    setState(() => _isEditing = false);
                    var url = value.trim();
                    if (!url.startsWith('http://') &&
                        !url.startsWith('https://')) {
                      if (url.contains('.') && !url.contains(' ')) {
                        url = 'https://$url';
                      } else {
                        url =
                            'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
                      }
                    }
                    widget.onSubmitted(url);
                  },
                ),
              ),
              if (widget.isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        if (widget.isLoading)
          LinearProgressIndicator(
            value: widget.progress,
            minHeight: 2,
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: Implement toolbar**

```dart
// lib/features/browser/widgets/toolbar.dart
import 'package:flutter/material.dart';

class BrowserToolbar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onBookmarks;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onMore;
  final VoidCallback onSettings;
  final VoidCallback onTabs;
  final VoidCallback onDownloads;

  const BrowserToolbar({
    super.key,
    required this.onHome,
    required this.onBookmarks,
    required this.onRefresh,
    required this.onBack,
    required this.onForward,
    required this.onMore,
    required this.onSettings,
    required this.onTabs,
    required this.onDownloads,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolbarButton(icon: Icons.home_outlined, onTap: onHome),
            _ToolbarButton(icon: Icons.bookmark_outline, onTap: onBookmarks),
            _ToolbarButton(icon: Icons.refresh, onTap: onRefresh),
            _ToolbarButton(icon: Icons.arrow_back_ios_new, onTap: onBack, size: 20),
            _ToolbarButton(icon: Icons.arrow_forward_ios, onTap: onForward, size: 20),
            _ToolbarButton(icon: Icons.more_horiz, onTap: onMore),
            _ToolbarButton(icon: Icons.settings_outlined, onTap: onSettings),
            _ToolbarButton(icon: Icons.grid_view_rounded, onTap: onTabs),
            _ToolbarButton(icon: Icons.download_outlined, onTap: onDownloads),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size),
      onPressed: onTap,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/browser/widgets/url_bar.dart lib/features/browser/widgets/toolbar.dart
git commit -m "feat: add URL bar and toolbar widgets"
```

---

### Task 9: Browser — Main Screen Assembly

**Files:**
- Create: `lib/features/browser/widgets/browser_screen.dart`
- Modify: `lib/main.dart`
- Create: `lib/app.dart`

- [ ] **Step 1: Implement browser screen**

```dart
// lib/features/browser/widgets/browser_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';
import 'package:zoomview/features/settings/providers/settings_provider.dart';
import 'package:zoomview/features/bookmarks/widgets/bookmark_screen.dart';
import 'package:zoomview/features/downloads/widgets/download_screen.dart';
import 'package:zoomview/features/settings/widgets/settings_screen.dart';
import 'toolbar.dart';
import 'url_bar.dart';
import 'zoom_slider.dart';
import 'webview_container.dart';
import 'tab_manager.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  final Map<String, InAppWebViewController> _controllers = {};

  InAppWebViewController? get _activeController {
    final state = ref.read(browserProvider);
    return _controllers[state.activeTab.id];
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(browserProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: Column(
        children: [
          BrowserToolbar(
            onHome: () => _activeController?.loadUrl(
              urlRequest: URLRequest(
                url: WebUri(settings.homeUrl),
              ),
            ),
            onBookmarks: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BookmarkScreen(),
              ),
            ),
            onRefresh: () => _activeController?.reload(),
            onBack: () => _activeController?.goBack(),
            onForward: () => _activeController?.goForward(),
            onMore: () => _showMoreMenu(context),
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            onTabs: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TabManager()),
            ),
            onDownloads: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadScreen()),
            ),
          ),
          UrlBar(
            url: browserState.activeTab.url,
            progress: browserState.progress,
            isLoading: browserState.isLoading,
            onSubmitted: (url) {
              _activeController?.loadUrl(
                urlRequest: URLRequest(url: WebUri(url)),
              );
            },
          ),
          Expanded(
            child: IndexedStack(
              index: browserState.activeTabIndex,
              children: List.generate(browserState.tabs.length, (i) {
                final tab = browserState.tabs[i];
                return WebViewContainer(
                  key: ValueKey(tab.id),
                  tabIndex: i,
                  initialUrl: tab.url,
                  onControllerCreated: (controller) {
                    _controllers[tab.id] = controller;
                  },
                );
              }),
            ),
          ),
          ZoomSlider(
            zoomLevel: browserState.activeTab.zoomLevel,
            minZoom: settings.minZoom,
            maxZoom: settings.maxZoom,
            onChanged: (zoom) {
              ref
                  .read(browserProvider.notifier)
                  .updateZoom(browserState.activeTabIndex, zoom);
              _activeController?.zoomBy(
                zoomFactor: zoom,
                animated: false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                _sharePage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Find in Page'),
              onTap: () {
                Navigator.pop(ctx);
                _showFindInPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.desktop_mac),
              title: Text(
                ref.read(settingsProvider).uaMode == UaMode.desktop
                    ? 'Switch to Mobile Mode'
                    : 'Switch to Desktop Mode',
              ),
              onTap: () {
                Navigator.pop(ctx);
                final current = ref.read(settingsProvider).uaMode;
                ref.read(settingsProvider.notifier).setUaMode(
                      current == UaMode.desktop
                          ? UaMode.mobile
                          : UaMode.desktop,
                    );
                _activeController?.reload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add),
              title: const Text('Add Bookmark'),
              onTap: () {
                Navigator.pop(ctx);
                _addBookmark();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistoryScreenPlaceholder(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sharePage() async {
    final url = ref.read(browserProvider).activeTab.url;
    // share_plus usage deferred to integration task
    await Share.share(url);
  }

  void _showFindInPage() {
    // Find-in-page implemented in Task 15
  }

  void _addBookmark() {
    final tab = ref.read(browserProvider).activeTab;
    ref.read(bookmarkAddProvider.notifier).state = (
      title: tab.title,
      url: tab.url,
    );
  }
}

// Temporary placeholder until history screen is built
class HistoryScreenPlaceholder extends StatelessWidget {
  const HistoryScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}

// Provider to trigger add-bookmark from browser screen
final bookmarkAddProvider = StateProvider<({String title, String url})?>(
  (ref) => null,
);
```

Note: The above file references `Share` from `share_plus` and providers from features not yet built. These will be connected in later tasks. For now, wrap unresolved calls in try-catch or add temporary stubs.

- [ ] **Step 2: Implement app.dart**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/browser/widgets/browser_screen.dart';

class ZoomViewApp extends ConsumerWidget {
  const ZoomViewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'ZoomView',
      debugShowCheckedModeBanner: false,
      theme: settings.darkMode ? AppTheme.dark() : AppTheme.light(),
      home: const BrowserScreen(),
    );
  }
}
```

- [ ] **Step 3: Implement main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'app.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: false);

  final container = ProviderContainer();
  await container.read(settingsProvider.notifier).load();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ZoomViewApp(),
    ),
  );
}
```

- [ ] **Step 4: Verify compilation**

```bash
flutter analyze --no-fatal-infos
```

Note: Some imports will show warnings for features not yet implemented (history, downloads, bookmarks). These will resolve as later tasks are completed. Stub the missing imports if analyze fails — create empty placeholder files with minimal classes.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/app.dart lib/features/browser/widgets/browser_screen.dart
git commit -m "feat: assemble main browser screen with toolbar, URL bar, zoom slider"
```

---

### Task 10: Browser — Tab Manager

**Files:**
- Create: `lib/features/browser/widgets/tab_manager.dart`

- [ ] **Step 1: Implement tab manager**

```dart
// lib/features/browser/widgets/tab_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';
import 'package:zoomview/core/constants.dart';

class TabManager extends ConsumerWidget {
  const TabManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserState = ref.watch(browserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tabs (${browserState.tabs.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ref
                  .read(browserProvider.notifier)
                  .addTab(AppConstants.defaultHomeUrl);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: browserState.tabs.length,
        itemBuilder: (context, index) {
          final tab = browserState.tabs[index];
          final isActive = index == browserState.activeTabIndex;

          return GestureDetector(
            onTap: () {
              ref.read(browserProvider.notifier).switchTab(index);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive ? Colors.blue : Colors.grey[700]!,
                  width: isActive ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tab.title.isEmpty ? 'New Tab' : tab.title,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(browserProvider.notifier).closeTab(index);
                          },
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          tab.url,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/browser/widgets/tab_manager.dart
git commit -m "feat: add tab manager grid view"
```

---

### Task 11: Bookmarks Feature

**Files:**
- Create: `lib/features/bookmarks/models/bookmark_model.dart`
- Create: `lib/features/bookmarks/models/folder_model.dart`
- Create: `lib/features/bookmarks/repositories/bookmark_repository.dart`
- Create: `lib/features/bookmarks/providers/bookmark_provider.dart`
- Create: `lib/features/bookmarks/widgets/bookmark_screen.dart`
- Create: `lib/features/bookmarks/widgets/folder_tree.dart`
- Test: `test/features/bookmarks/bookmark_repository_test.dart`

- [ ] **Step 1: Write bookmark repository test**

```dart
// test/features/bookmarks/bookmark_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/features/bookmarks/models/bookmark_model.dart';
import 'package:zoomview/features/bookmarks/models/folder_model.dart';
import 'package:zoomview/features/bookmarks/repositories/bookmark_repository.dart';

void main() {
  late DatabaseHelper dbHelper;
  late BookmarkRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting();
    repo = BookmarkRepository(dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('folders', () {
    test('createFolder and getFolders', () async {
      await repo.createFolder('News');
      await repo.createFolder('Tech');
      final folders = await repo.getFolders();
      expect(folders.length, 2);
      expect(folders.map((f) => f.name), containsAll(['News', 'Tech']));
    });

    test('createFolder with parent', () async {
      final parentId = await repo.createFolder('Parent');
      await repo.createFolder('Child', parentId: parentId);
      final folders = await repo.getFolders(parentId: parentId);
      expect(folders.length, 1);
      expect(folders.first.name, 'Child');
    });

    test('deleteFolder', () async {
      final id = await repo.createFolder('ToDelete');
      await repo.deleteFolder(id);
      final folders = await repo.getFolders();
      expect(folders, isEmpty);
    });
  });

  group('bookmarks', () {
    test('addBookmark and getBookmarks', () async {
      await repo.addBookmark('Google', 'https://google.com');
      await repo.addBookmark('GitHub', 'https://github.com');
      final bookmarks = await repo.getBookmarks();
      expect(bookmarks.length, 2);
    });

    test('addBookmark to folder', () async {
      final folderId = await repo.createFolder('Dev');
      await repo.addBookmark('GitHub', 'https://github.com',
          folderId: folderId);
      final bookmarks = await repo.getBookmarks(folderId: folderId);
      expect(bookmarks.length, 1);
      expect(bookmarks.first.folderId, folderId);
    });

    test('deleteBookmark', () async {
      await repo.addBookmark('Test', 'https://test.com');
      final bookmarks = await repo.getBookmarks();
      await repo.deleteBookmark(bookmarks.first.id!);
      final after = await repo.getBookmarks();
      expect(after, isEmpty);
    });

    test('searchBookmarks', () async {
      await repo.addBookmark('Flutter Docs', 'https://flutter.dev');
      await repo.addBookmark('Dart Docs', 'https://dart.dev');
      await repo.addBookmark('GitHub', 'https://github.com');
      final results = await repo.searchBookmarks('docs');
      expect(results.length, 2);
    });

    test('moveBookmark to folder', () async {
      await repo.addBookmark('Test', 'https://test.com');
      final bookmarks = await repo.getBookmarks();
      final folderId = await repo.createFolder('Target');
      await repo.moveBookmark(bookmarks.first.id!, folderId);
      final moved = await repo.getBookmarks(folderId: folderId);
      expect(moved.length, 1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/bookmarks/bookmark_repository_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Implement models**

```dart
// lib/features/bookmarks/models/folder_model.dart
class BookmarkFolder {
  final int? id;
  final String name;
  final int? parentId;
  final int sortOrder;
  final DateTime createdAt;

  BookmarkFolder({
    this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BookmarkFolder.fromMap(Map<String, dynamic> map) {
    return BookmarkFolder(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

```dart
// lib/features/bookmarks/models/bookmark_model.dart
import 'dart:typed_data';

class Bookmark {
  final int? id;
  final String title;
  final String url;
  final Uint8List? favicon;
  final int? folderId;
  final int sortOrder;
  final DateTime createdAt;

  Bookmark({
    this.id,
    required this.title,
    required this.url,
    this.favicon,
    this.folderId,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      title: map['title'] as String,
      url: map['url'] as String,
      favicon: map['favicon'] as Uint8List?,
      folderId: map['folder_id'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'url': url,
      'favicon': favicon,
      'folder_id': folderId,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

- [ ] **Step 4: Implement bookmark repository**

```dart
// lib/features/bookmarks/repositories/bookmark_repository.dart
import 'package:sqflite/sqflite.dart';
import 'package:zoomview/core/database/database_helper.dart';
import '../models/bookmark_model.dart';
import '../models/folder_model.dart';

class BookmarkRepository {
  final DatabaseHelper _dbHelper;

  BookmarkRepository(this._dbHelper);

  // Folders
  Future<int> createFolder(String name, {int? parentId}) async {
    final db = await _dbHelper.database;
    return db.insert('bookmark_folders', {
      'name': name,
      'parent_id': parentId,
      'sort_order': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<BookmarkFolder>> getFolders({int? parentId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'bookmark_folders',
      where: parentId == null ? 'parent_id IS NULL' : 'parent_id = ?',
      whereArgs: parentId == null ? null : [parentId],
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map((r) => BookmarkFolder.fromMap(r)).toList();
  }

  Future<void> deleteFolder(int id) async {
    final db = await _dbHelper.database;
    await db.delete('bookmark_folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renameFolder(int id, String name) async {
    final db = await _dbHelper.database;
    await db.update('bookmark_folders', {'name': name},
        where: 'id = ?', whereArgs: [id]);
  }

  // Bookmarks
  Future<int> addBookmark(String title, String url, {int? folderId}) async {
    final db = await _dbHelper.database;
    return db.insert('bookmarks', {
      'title': title,
      'url': url,
      'folder_id': folderId,
      'sort_order': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Bookmark>> getBookmarks({int? folderId}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> rows;
    if (folderId == null) {
      rows = await db.query('bookmarks', orderBy: 'sort_order ASC, created_at DESC');
    } else {
      rows = await db.query('bookmarks',
          where: 'folder_id = ?',
          whereArgs: [folderId],
          orderBy: 'sort_order ASC, created_at DESC');
    }
    return rows.map((r) => Bookmark.fromMap(r)).toList();
  }

  Future<void> deleteBookmark(int id) async {
    final db = await _dbHelper.database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> moveBookmark(int bookmarkId, int? folderId) async {
    final db = await _dbHelper.database;
    await db.update('bookmarks', {'folder_id': folderId},
        where: 'id = ?', whereArgs: [bookmarkId]);
  }

  Future<void> updateBookmark(int id, {String? title, String? url}) async {
    final db = await _dbHelper.database;
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (url != null) map['url'] = url;
    if (map.isNotEmpty) {
      await db.update('bookmarks', map, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<Bookmark>> searchBookmarks(String query) async {
    final db = await _dbHelper.database;
    final rows = await db.query('bookmarks',
        where: 'title LIKE ? OR url LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'created_at DESC');
    return rows.map((r) => Bookmark.fromMap(r)).toList();
  }
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/features/bookmarks/bookmark_repository_test.dart
```

Expected: ALL PASS.

- [ ] **Step 6: Implement bookmark provider**

```dart
// lib/features/bookmarks/providers/bookmark_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/database/database_helper.dart';
import '../models/bookmark_model.dart';
import '../models/folder_model.dart';
import '../repositories/bookmark_repository.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(DatabaseHelper.instance);
});

class BookmarkState {
  final List<BookmarkFolder> folders;
  final List<Bookmark> bookmarks;
  final int? currentFolderId;
  final String searchQuery;

  const BookmarkState({
    this.folders = const [],
    this.bookmarks = const [],
    this.currentFolderId,
    this.searchQuery = '',
  });

  BookmarkState copyWith({
    List<BookmarkFolder>? folders,
    List<Bookmark>? bookmarks,
    int? Function()? currentFolderId,
    String? searchQuery,
  }) {
    return BookmarkState(
      folders: folders ?? this.folders,
      bookmarks: bookmarks ?? this.bookmarks,
      currentFolderId:
          currentFolderId != null ? currentFolderId() : this.currentFolderId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final bookmarkProvider =
    StateNotifierProvider<BookmarkNotifier, BookmarkState>((ref) {
  return BookmarkNotifier(ref.watch(bookmarkRepositoryProvider));
});

class BookmarkNotifier extends StateNotifier<BookmarkState> {
  final BookmarkRepository _repo;

  BookmarkNotifier(this._repo) : super(const BookmarkState());

  Future<void> load({int? folderId}) async {
    final folders = await _repo.getFolders(parentId: folderId);
    final bookmarks = await _repo.getBookmarks(folderId: folderId);
    state = state.copyWith(
      folders: folders,
      bookmarks: bookmarks,
      currentFolderId: () => folderId,
    );
  }

  Future<void> addBookmark(String title, String url, {int? folderId}) async {
    await _repo.addBookmark(title, url, folderId: folderId);
    await load(folderId: state.currentFolderId);
  }

  Future<void> deleteBookmark(int id) async {
    await _repo.deleteBookmark(id);
    await load(folderId: state.currentFolderId);
  }

  Future<void> moveBookmark(int bookmarkId, int? folderId) async {
    await _repo.moveBookmark(bookmarkId, folderId);
    await load(folderId: state.currentFolderId);
  }

  Future<void> createFolder(String name) async {
    await _repo.createFolder(name, parentId: state.currentFolderId);
    await load(folderId: state.currentFolderId);
  }

  Future<void> deleteFolder(int id) async {
    await _repo.deleteFolder(id);
    await load(folderId: state.currentFolderId);
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      await load(folderId: state.currentFolderId);
      return;
    }
    final results = await _repo.searchBookmarks(query);
    state = state.copyWith(bookmarks: results, searchQuery: query);
  }
}
```

- [ ] **Step 7: Implement bookmark screen**

```dart
// lib/features/bookmarks/widgets/bookmark_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookmark_provider.dart';
import 'folder_tree.dart';

class BookmarkScreen extends ConsumerStatefulWidget {
  const BookmarkScreen({super.key});

  @override
  ConsumerState<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends ConsumerState<BookmarkScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(bookmarkProvider.notifier).load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarkProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () => _showCreateFolderDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search bookmarks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (q) =>
                  ref.read(bookmarkProvider.notifier).search(q),
            ),
          ),
          if (state.currentFolderId != null)
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Back'),
              onTap: () => ref.read(bookmarkProvider.notifier).load(),
            ),
          Expanded(
            child: FolderTree(
              folders: state.folders,
              bookmarks: state.bookmarks,
              onFolderTap: (folderId) =>
                  ref.read(bookmarkProvider.notifier).load(folderId: folderId),
              onBookmarkTap: (url) {
                Navigator.pop(context, url);
              },
              onBookmarkDelete: (id) =>
                  ref.read(bookmarkProvider.notifier).deleteBookmark(id),
              onFolderDelete: (id) =>
                  ref.read(bookmarkProvider.notifier).deleteFolder(id),
              onBookmarkMove: (bookmarkId) =>
                  _showMoveFolderPicker(context, bookmarkId),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(bookmarkProvider.notifier)
                    .createFolder(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showMoveFolderPicker(BuildContext context, int bookmarkId) {
    // Simple dialog to move bookmark to root or existing folder
    showDialog(
      context: context,
      builder: (ctx) {
        final folders = ref.read(bookmarkProvider).folders;
        return SimpleDialog(
          title: const Text('Move to Folder'),
          children: [
            SimpleDialogOption(
              child: const Text('Uncategorized'),
              onPressed: () {
                ref
                    .read(bookmarkProvider.notifier)
                    .moveBookmark(bookmarkId, null);
                Navigator.pop(ctx);
              },
            ),
            ...folders.map((f) => SimpleDialogOption(
                  child: Text(f.name),
                  onPressed: () {
                    ref
                        .read(bookmarkProvider.notifier)
                        .moveBookmark(bookmarkId, f.id);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 8: Implement folder tree widget**

```dart
// lib/features/bookmarks/widgets/folder_tree.dart
import 'package:flutter/material.dart';
import '../models/bookmark_model.dart';
import '../models/folder_model.dart';

class FolderTree extends StatelessWidget {
  final List<BookmarkFolder> folders;
  final List<Bookmark> bookmarks;
  final ValueChanged<int> onFolderTap;
  final ValueChanged<String> onBookmarkTap;
  final ValueChanged<int> onBookmarkDelete;
  final ValueChanged<int> onFolderDelete;
  final ValueChanged<int> onBookmarkMove;

  const FolderTree({
    super.key,
    required this.folders,
    required this.bookmarks,
    required this.onFolderTap,
    required this.onBookmarkTap,
    required this.onBookmarkDelete,
    required this.onFolderDelete,
    required this.onBookmarkMove,
  });

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty && bookmarks.isEmpty) {
      return const Center(child: Text('No bookmarks yet'));
    }

    return ReorderableListView(
      onReorder: (oldIndex, newIndex) {
        // Reorder logic — visual only for now
      },
      children: [
        ...folders.map((folder) => ListTile(
              key: ValueKey('folder_${folder.id}'),
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: Text(folder.name),
              onTap: () => onFolderTap(folder.id!),
              onLongPress: () => _showFolderMenu(context, folder),
            )),
        ...bookmarks.map((bookmark) => Dismissible(
              key: ValueKey('bm_${bookmark.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => onBookmarkDelete(bookmark.id!),
              child: ListTile(
                leading: const Icon(Icons.bookmark, color: Colors.blue),
                title: Text(
                  bookmark.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  bookmark.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                onTap: () => onBookmarkTap(bookmark.url),
                onLongPress: () =>
                    _showBookmarkMenu(context, bookmark),
              ),
            )),
      ],
    );
  }

  void _showFolderMenu(BuildContext context, BookmarkFolder folder) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Folder'),
              onTap: () {
                onFolderDelete(folder.id!);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarkMenu(BuildContext context, Bookmark bookmark) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: const Text('Move to Folder'),
              onTap: () {
                Navigator.pop(ctx);
                onBookmarkMove(bookmark.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                onBookmarkDelete(bookmark.id!);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 9: Commit**

```bash
git add lib/features/bookmarks/ test/features/bookmarks/
git commit -m "feat: add bookmarks feature with folder tree and search"
```

---

### Task 12: History Feature

**Files:**
- Create: `lib/features/history/models/history_model.dart`
- Create: `lib/features/history/repositories/history_repository.dart`
- Create: `lib/features/history/providers/history_provider.dart`
- Create: `lib/features/history/widgets/history_screen.dart`
- Test: `test/features/history/history_repository_test.dart`

- [ ] **Step 1: Write history repository test**

```dart
// test/features/history/history_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/features/history/models/history_model.dart';
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/history/history_repository_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Implement history model**

```dart
// lib/features/history/models/history_model.dart
import 'dart:typed_data';

class HistoryModel {
  final int? id;
  final String title;
  final String url;
  final Uint8List? favicon;
  final DateTime visitedAt;

  HistoryModel({
    this.id,
    required this.title,
    required this.url,
    this.favicon,
    DateTime? visitedAt,
  }) : visitedAt = visitedAt ?? DateTime.now();

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      url: map['url'] as String,
      favicon: map['favicon'] as Uint8List?,
      visitedAt: DateTime.parse(map['visited_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'url': url,
      'favicon': favicon,
      'visited_at': visitedAt.toIso8601String(),
    };
  }
}
```

- [ ] **Step 4: Implement history repository**

```dart
// lib/features/history/repositories/history_repository.dart
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
    final rows =
        await db.query('history', orderBy: 'visited_at DESC');
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
    final rows = await db.query(
      'history',
      where: 'title LIKE ? OR url LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'visited_at DESC',
    );
    return rows.map((r) => HistoryModel.fromMap(r)).toList();
  }
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/features/history/history_repository_test.dart
```

Expected: ALL PASS.

- [ ] **Step 6: Implement history provider**

```dart
// lib/features/history/providers/history_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/database/database_helper.dart';
import '../models/history_model.dart';
import '../repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(DatabaseHelper.instance);
});

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryModel>>((ref) {
  return HistoryNotifier(ref.watch(historyRepositoryProvider));
});

class HistoryNotifier extends StateNotifier<List<HistoryModel>> {
  final HistoryRepository _repo;

  HistoryNotifier(this._repo) : super([]);

  Future<void> load() async {
    state = await _repo.getAll();
  }

  Future<void> addEntry(String title, String url) async {
    await _repo.addEntry(title, url);
    // Don't reload full list on every page load — too expensive
  }

  Future<void> deleteEntry(int id) async {
    await _repo.deleteEntry(id);
    state = state.where((e) => e.id != id).toList();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = [];
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      await load();
      return;
    }
    state = await _repo.search(query);
  }
}
```

- [ ] **Step 7: Implement history screen**

```dart
// lib/features/history/widgets/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_model.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(historyProvider.notifier).load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(historyProvider);
    final grouped = _groupByDate(entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search history...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (q) =>
                  ref.read(historyProvider.notifier).search(q),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No history'))
                : ListView.builder(
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final group = grouped[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              group.label,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ...group.entries.map((entry) => Dismissible(
                                key: ValueKey(entry.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                onDismissed: (_) => ref
                                    .read(historyProvider.notifier)
                                    .deleteEntry(entry.id!),
                                child: ListTile(
                                  title: Text(
                                    entry.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    entry.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  onTap: () =>
                                      Navigator.pop(context, entry.url),
                                ),
                              )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<_HistoryGroup> _groupByDate(List<HistoryModel> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayEntries = <HistoryModel>[];
    final yesterdayEntries = <HistoryModel>[];
    final earlierEntries = <HistoryModel>[];

    for (final entry in entries) {
      final date = DateTime(
        entry.visitedAt.year,
        entry.visitedAt.month,
        entry.visitedAt.day,
      );
      if (date == today) {
        todayEntries.add(entry);
      } else if (date == yesterday) {
        yesterdayEntries.add(entry);
      } else {
        earlierEntries.add(entry);
      }
    }

    return [
      if (todayEntries.isNotEmpty)
        _HistoryGroup('Today', todayEntries),
      if (yesterdayEntries.isNotEmpty)
        _HistoryGroup('Yesterday', yesterdayEntries),
      if (earlierEntries.isNotEmpty)
        _HistoryGroup('Earlier', earlierEntries),
    ];
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all browsing history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _HistoryGroup {
  final String label;
  final List<HistoryModel> entries;
  _HistoryGroup(this.label, this.entries);
}
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/history/ test/features/history/
git commit -m "feat: add history feature with date grouping and search"
```

---

### Task 13: Downloads Feature

**Files:**
- Create: `lib/features/downloads/models/download_model.dart`
- Create: `lib/features/downloads/repositories/download_repository.dart`
- Create: `lib/features/downloads/providers/download_provider.dart`
- Create: `lib/features/downloads/widgets/download_screen.dart`
- Create: `lib/features/downloads/widgets/download_item.dart`
- Test: `test/features/downloads/download_repository_test.dart`

- [ ] **Step 1: Write download repository test**

```dart
// test/features/downloads/download_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/features/downloads/models/download_model.dart';
import 'package:zoomview/features/downloads/repositories/download_repository.dart';

void main() {
  late DatabaseHelper dbHelper;
  late DownloadRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting();
    repo = DownloadRepository(dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('addDownload and getAll', () async {
    await repo.addDownload(
      url: 'https://example.com/file.pdf',
      fileName: 'file.pdf',
      filePath: '/downloads/file.pdf',
    );
    final downloads = await repo.getAll();
    expect(downloads.length, 1);
    expect(downloads.first.fileName, 'file.pdf');
    expect(downloads.first.status, DownloadStatus.pending);
  });

  test('updateStatus changes status', () async {
    await repo.addDownload(
      url: 'https://example.com/f.zip',
      fileName: 'f.zip',
      filePath: '/downloads/f.zip',
    );
    final downloads = await repo.getAll();
    await repo.updateStatus(downloads.first.id!, DownloadStatus.downloading);
    final updated = await repo.getAll();
    expect(updated.first.status, DownloadStatus.downloading);
  });

  test('updateProgress updates bytes', () async {
    await repo.addDownload(
      url: 'https://example.com/f.zip',
      fileName: 'f.zip',
      filePath: '/downloads/f.zip',
      totalBytes: 1000,
    );
    final downloads = await repo.getAll();
    await repo.updateProgress(downloads.first.id!, 500);
    final updated = await repo.getAll();
    expect(updated.first.downloadedBytes, 500);
  });

  test('deleteDownload removes entry', () async {
    await repo.addDownload(
      url: 'https://example.com/f.zip',
      fileName: 'f.zip',
      filePath: '/downloads/f.zip',
    );
    final downloads = await repo.getAll();
    await repo.deleteDownload(downloads.first.id!);
    final after = await repo.getAll();
    expect(after, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/downloads/download_repository_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Implement download model**

```dart
// lib/features/downloads/models/download_model.dart
enum DownloadStatus { pending, downloading, paused, completed, failed }

class DownloadModel {
  final int? id;
  final String url;
  final String fileName;
  final String filePath;
  final String? mimeType;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final DateTime createdAt;

  DownloadModel({
    this.id,
    required this.url,
    required this.fileName,
    required this.filePath,
    this.mimeType,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercent =>
      totalBytes > 0 ? downloadedBytes / totalBytes : 0;

  factory DownloadModel.fromMap(Map<String, dynamic> map) {
    return DownloadModel(
      id: map['id'] as int?,
      url: map['url'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      mimeType: map['mime_type'] as String?,
      totalBytes: map['total_bytes'] as int? ?? 0,
      downloadedBytes: map['downloaded_bytes'] as int? ?? 0,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'pending'),
        orElse: () => DownloadStatus.pending,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'url': url,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'total_bytes': totalBytes,
      'downloaded_bytes': downloadedBytes,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

- [ ] **Step 4: Implement download repository**

```dart
// lib/features/downloads/repositories/download_repository.dart
import 'package:sqflite/sqflite.dart';
import 'package:zoomview/core/database/database_helper.dart';
import '../models/download_model.dart';

class DownloadRepository {
  final DatabaseHelper _dbHelper;

  DownloadRepository(this._dbHelper);

  Future<int> addDownload({
    required String url,
    required String fileName,
    required String filePath,
    String? mimeType,
    int totalBytes = 0,
  }) async {
    final db = await _dbHelper.database;
    return db.insert('downloads', {
      'url': url,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'total_bytes': totalBytes,
      'downloaded_bytes': 0,
      'status': DownloadStatus.pending.name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<DownloadModel>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('downloads', orderBy: 'created_at DESC');
    return rows.map((r) => DownloadModel.fromMap(r)).toList();
  }

  Future<void> updateStatus(int id, DownloadStatus status) async {
    final db = await _dbHelper.database;
    await db.update('downloads', {'status': status.name},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProgress(int id, int downloadedBytes) async {
    final db = await _dbHelper.database;
    await db.update('downloads', {'downloaded_bytes': downloadedBytes},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteDownload(int id) async {
    final db = await _dbHelper.database;
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/features/downloads/download_repository_test.dart
```

Expected: ALL PASS.

- [ ] **Step 6: Implement download provider**

```dart
// lib/features/downloads/providers/download_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:zoomview/core/database/database_helper.dart';
import '../models/download_model.dart';
import '../repositories/download_repository.dart';

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepository(DatabaseHelper.instance);
});

final downloadProvider =
    StateNotifierProvider<DownloadNotifier, List<DownloadModel>>((ref) {
  return DownloadNotifier(ref.watch(downloadRepositoryProvider));
});

class DownloadNotifier extends StateNotifier<List<DownloadModel>> {
  final DownloadRepository _repo;

  DownloadNotifier(this._repo) : super([]);

  Future<void> load() async {
    state = await _repo.getAll();
  }

  Future<void> startDownload(String url, String fileName) async {
    final dir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final savePath = '${dir!.path}/downloads';
    await Directory(savePath).create(recursive: true);

    final filePath = '$savePath/$fileName';
    final id = await _repo.addDownload(
      url: url,
      fileName: fileName,
      filePath: filePath,
    );

    await FlutterDownloader.enqueue(
      url: url,
      savedDir: savePath,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
    );

    await _repo.updateStatus(id, DownloadStatus.downloading);
    await load();
  }

  Future<void> pauseDownload(String taskId) async {
    await FlutterDownloader.pause(taskId: taskId);
  }

  Future<void> resumeDownload(String taskId) async {
    await FlutterDownloader.resume(taskId: taskId);
  }

  Future<void> cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  Future<void> deleteRecord(int id) async {
    await _repo.deleteDownload(id);
    state = state.where((d) => d.id != id).toList();
  }
}
```

- [ ] **Step 7: Implement download screen and item**

```dart
// lib/features/downloads/widgets/download_item.dart
import 'package:flutter/material.dart';
import '../models/download_model.dart';

class DownloadItemWidget extends StatelessWidget {
  final DownloadModel download;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;

  const DownloadItemWidget({
    super.key,
    required this.download,
    required this.onDelete,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_statusIcon, color: _statusColor),
      title: Text(
        download.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (download.status == DownloadStatus.downloading)
            LinearProgressIndicator(value: download.progressPercent),
          Text(
            _statusText,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (download.status == DownloadStatus.completed && onOpen != null)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: onOpen,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  IconData get _statusIcon => switch (download.status) {
        DownloadStatus.pending => Icons.hourglass_empty,
        DownloadStatus.downloading => Icons.downloading,
        DownloadStatus.paused => Icons.pause_circle_outline,
        DownloadStatus.completed => Icons.check_circle_outline,
        DownloadStatus.failed => Icons.error_outline,
      };

  Color get _statusColor => switch (download.status) {
        DownloadStatus.completed => Colors.green,
        DownloadStatus.failed => Colors.red,
        DownloadStatus.downloading => Colors.blue,
        _ => Colors.grey,
      };

  String get _statusText => switch (download.status) {
        DownloadStatus.pending => 'Pending',
        DownloadStatus.downloading =>
          '${(download.progressPercent * 100).round()}%',
        DownloadStatus.paused => 'Paused',
        DownloadStatus.completed => 'Completed',
        DownloadStatus.failed => 'Failed',
      };
}
```

```dart
// lib/features/downloads/widgets/download_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../providers/download_provider.dart';
import 'download_item.dart';

class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(downloadProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: downloads.isEmpty
          ? const Center(child: Text('No downloads'))
          : ListView.builder(
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final dl = downloads[index];
                return DownloadItemWidget(
                  download: dl,
                  onDelete: () =>
                      ref.read(downloadProvider.notifier).deleteRecord(dl.id!),
                  onOpen: dl.status == DownloadStatus.completed
                      ? () => _openFile(dl.filePath)
                      : null,
                );
              },
            ),
    );
  }

  void _openFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await launchUrl(Uri.file(path));
    }
  }
}
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/downloads/ test/features/downloads/
git commit -m "feat: add download manager with progress tracking"
```

---

### Task 14: Integration & Polish

**Files:**
- Modify: `lib/features/browser/widgets/browser_screen.dart` — wire up all features, remove placeholders
- Modify: `lib/features/browser/widgets/webview_container.dart` — connect download trigger

- [ ] **Step 1: Wire up bookmark navigation from browser**

In `browser_screen.dart`, update the bookmark navigation to handle return value:

```dart
// In onBookmarks callback:
onBookmarks: () async {
  final url = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => const BookmarkScreen()),
  );
  if (url != null) {
    _activeController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
  }
},
```

- [ ] **Step 2: Wire up history navigation**

Replace `HistoryScreenPlaceholder` reference with real `HistoryScreen`. In the more menu history item:

```dart
ListTile(
  leading: const Icon(Icons.history),
  title: const Text('History'),
  onTap: () async {
    Navigator.pop(ctx);
    final url = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
    if (url != null) {
      _activeController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(url)),
      );
    }
  },
),
```

- [ ] **Step 3: Wire up download interception**

In `browser_screen.dart`, add a listener for `downloadTriggerProvider`:

```dart
// In _BrowserScreenState, add to initState or build:
ref.listen(downloadTriggerProvider, (prev, next) {
  if (next != null) {
    final fileName = next.url.toString().split('/').last;
    ref.read(downloadProvider.notifier).startDownload(
          next.url.toString(),
          fileName.isEmpty ? 'download' : fileName,
        );
  }
});
```

- [ ] **Step 4: Wire up add-bookmark from more menu**

```dart
void _addBookmark() async {
  final tab = ref.read(browserProvider).activeTab;
  await ref.read(bookmarkProvider.notifier).addBookmark(
        tab.title.isEmpty ? tab.url : tab.title,
        tab.url,
      );
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark added')),
    );
  }
}
```

- [ ] **Step 5: Add share_plus import and implement share**

```dart
import 'package:share_plus/share_plus.dart';

void _sharePage() {
  final url = ref.read(browserProvider).activeTab.url;
  Share.share(url);
}
```

- [ ] **Step 6: Implement find-in-page**

```dart
void _showFindInPage() {
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final controller = TextEditingController();
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Find in page...',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (query) {
                  _activeController?.findAllAsync(find: query);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: () =>
                  _activeController?.findNext(forward: false),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              onPressed: () =>
                  _activeController?.findNext(forward: true),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _activeController?.clearMatches();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    },
  );
}
```

- [ ] **Step 7: Remove all placeholder/stub code**

Remove `HistoryScreenPlaceholder` class and `bookmarkAddProvider` from `browser_screen.dart`. Ensure all imports point to real implementations.

- [ ] **Step 8: Add all missing imports**

Ensure `browser_screen.dart` has:

```dart
import 'package:share_plus/share_plus.dart';
import 'package:zoomview/features/history/widgets/history_screen.dart';
import 'package:zoomview/features/downloads/providers/download_provider.dart';
import 'package:zoomview/features/bookmarks/providers/bookmark_provider.dart';
import 'package:zoomview/features/browser/widgets/webview_container.dart';
```

- [ ] **Step 9: Run full test suite and analyze**

```bash
flutter test
flutter analyze --no-fatal-infos
```

Expected: ALL PASS, no errors.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "feat: integrate all features, wire up navigation and downloads"
```

---

### Task 15: Manual Device Testing

> This task requires a physical device or emulator. Cannot be automated.

- [ ] **Step 1: Run on Android emulator or device**

```bash
flutter run
```

- [ ] **Step 2: Verify checklist**

1. App launches with dark theme
2. Google loads in desktop mode (full desktop layout, not mobile)
3. Zoom slider works: drag slider, tap +/-, percentage updates, WebView zooms
4. URL bar: type URL → navigates, type search query → Google search
5. Toolbar: back/forward/refresh/home all functional
6. Tabs: open new tab, switch tabs, close tab, last-tab-close creates new tab
7. Bookmarks: add bookmark from more menu, open bookmark screen, create folder, move bookmark, search
8. History: pages auto-record, date grouping shows correctly, swipe to delete, clear all
9. Downloads: trigger a file download, check download screen shows it
10. Settings: toggle desktop/mobile mode (page reloads with new UA), change search engine, change home page, clear cookies/cache, dark mode toggle
11. Find in page: search text highlights on page

- [ ] **Step 3: Fix any issues found, commit**

```bash
git add -A
git commit -m "fix: address issues found during device testing"
```
