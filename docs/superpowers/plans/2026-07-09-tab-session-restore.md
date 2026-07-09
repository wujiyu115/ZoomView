# Tab Session Restore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist open tabs when the app closes and restore them on next launch, gated by a user setting (default on).

**Architecture:** Serialize the in-memory tab list to JSON stored in the existing `settings` table via a new `SessionRepository`. Save on app lifecycle `paused`/`detached` (capturing live scroll from webview controllers); restore in `BrowserScreen.initState` after settings load. Scroll position is reapplied per-tab after page load, mirroring the existing zoom-restore path.

**Tech Stack:** Flutter, Dart, Riverpod (Notifier), sqflite, flutter_inappwebview 6.1.5, flutter_test + sqflite_common_ffi.

## Global Constraints

- Tests use `sqflite_common_ffi`: call `sqfliteFfiInit()` + `databaseFactory = databaseFactoryFfi` in `setUpAll`, and `DatabaseHelper.forTesting()` (in-memory) per test.
- `flutter_inappwebview` 6.1.5: `getScrollY()` returns `Future<int?>`; `scrollTo({required int x, required int y, bool animated})` takes `int`. `TabModel.scrollPosition` is `double` — convert at boundaries.
- Localized strings live in `lib/l10n/app_en.arb` (template) and `lib/l10n/app_zh.arb`; regenerate with `flutter gen-l10n` after editing arb files. Access via `AppLocalizations.of(context)!`.
- Settings persist as string key/value in the `settings` table; bool convention is `.toString()` / `!= 'false'` (default true) or `== 'true'` (default false).
- Commit after every task.

---

### Task 1: TabModel JSON serialization

**Files:**
- Modify: `lib/features/browser/models/tab_model.dart`
- Test: `test/features/browser/tab_model_test.dart` (create)

**Interfaces:**
- Consumes: existing `TabModel` constructor (`url`, `title`, `zoomLevel`, `scrollPosition`, `showStartPage`).
- Produces: `Map<String, dynamic> TabModel.toJson()` and `factory TabModel.fromJson(Map<String, dynamic>)`. Persisted keys: `url`, `title`, `zoomLevel`, `scrollPosition`. On `fromJson`, `showStartPage` is derived from `url.isEmpty`; `id` is a fresh UUID; `favicon`/`isActive` are not persisted.

- [ ] **Step 1: Write the failing test**

Create `test/features/browser/tab_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zoomview/features/browser/models/tab_model.dart';

void main() {
  test('toJson serializes persisted fields', () {
    final tab = TabModel(
      url: 'https://example.com',
      title: 'Example',
      zoomLevel: 1.5,
      scrollPosition: 240,
    );
    expect(tab.toJson(), {
      'url': 'https://example.com',
      'title': 'Example',
      'zoomLevel': 1.5,
      'scrollPosition': 240.0,
    });
  });

  test('fromJson restores persisted fields', () {
    final tab = TabModel.fromJson({
      'url': 'https://example.com',
      'title': 'Example',
      'zoomLevel': 1.5,
      'scrollPosition': 240,
    });
    expect(tab.url, 'https://example.com');
    expect(tab.title, 'Example');
    expect(tab.zoomLevel, 1.5);
    expect(tab.scrollPosition, 240.0);
    expect(tab.showStartPage, false);
  });

  test('fromJson with empty url derives showStartPage true', () {
    final tab = TabModel.fromJson({'url': ''});
    expect(tab.showStartPage, true);
    expect(tab.zoomLevel, 1.0);
    expect(tab.scrollPosition, 0.0);
  });

  test('round-trip preserves values', () {
    final original = TabModel(
        url: 'https://a.com', title: 'A', zoomLevel: 2.0, scrollPosition: 10);
    final restored = TabModel.fromJson(original.toJson());
    expect(restored.url, original.url);
    expect(restored.title, original.title);
    expect(restored.zoomLevel, original.zoomLevel);
    expect(restored.scrollPosition, original.scrollPosition);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/browser/tab_model_test.dart`
Expected: FAIL — `toJson`/`fromJson` not defined.

- [ ] **Step 3: Add serialization to TabModel**

In `lib/features/browser/models/tab_model.dart`, add these methods inside the `TabModel` class (after `copyWith`, before the closing brace):

```dart
  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'zoomLevel': zoomLevel,
        'scrollPosition': scrollPosition,
      };

  factory TabModel.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    return TabModel(
      url: url,
      title: json['title'] as String? ?? '',
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0,
      showStartPage: url.isEmpty,
    );
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/browser/tab_model_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/browser/models/tab_model.dart test/features/browser/tab_model_test.dart
git commit -m "feat: add TabModel JSON serialization"
```

---

### Task 2: SessionRepository

**Files:**
- Create: `lib/features/browser/repositories/session_repository.dart`
- Test: `test/features/browser/session_repository_test.dart` (create)

**Interfaces:**
- Consumes: `DatabaseHelper` (from `lib/core/database/database_helper.dart`), `TabModel.toJson`/`fromJson` (Task 1), `AppLogger` (`lib/core/logger/app_logger.dart`).
- Produces:
  - `class SessionData { final List<TabModel> tabs; final int activeIndex; SessionData(this.tabs, this.activeIndex); }`
  - `class SessionRepository { SessionRepository(DatabaseHelper); Future<void> save(List<TabModel> tabs, int activeIndex); Future<SessionData?> load(); Future<void> clear(); }`
  - `load()` returns `null` when nothing stored, the list is empty, or JSON is malformed. Storage keys in `settings` table: `session_tabs` (JSON array string), `session_active` (int string).

- [ ] **Step 1: Write the failing test**

Create `test/features/browser/session_repository_test.dart`:

```dart
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/browser/session_repository_test.dart`
Expected: FAIL — `session_repository.dart` does not exist.

- [ ] **Step 3: Create SessionRepository**

Create `lib/features/browser/repositories/session_repository.dart`:

```dart
import 'dart:convert';
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/browser/session_repository_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/browser/repositories/session_repository.dart test/features/browser/session_repository_test.dart
git commit -m "feat: add SessionRepository for tab persistence"
```

---

### Task 3: BrowserNotifier.restoreTabs

**Files:**
- Modify: `lib/features/browser/providers/browser_provider.dart`
- Test: `test/features/browser/browser_provider_test.dart:64` (add tests before final `}`)

**Interfaces:**
- Consumes: existing `BrowserState`, `TabModel`.
- Produces: `void BrowserNotifier.restoreTabs(List<TabModel> tabs, int activeIndex)` — replaces state with the given tabs; clamps `activeIndex` into range; ignores an empty list (state unchanged).

- [ ] **Step 1: Write the failing test**

In `test/features/browser/browser_provider_test.dart`, add an import at top:

```dart
import 'package:zoomview/features/browser/models/tab_model.dart';
```

and add these tests before the closing `}` of `main`:

```dart
  test('restoreTabs replaces state with given tabs and index', () {
    container.read(browserProvider.notifier).restoreTabs([
      TabModel(url: 'https://a.com'),
      TabModel(url: 'https://b.com'),
    ], 1);
    final state = container.read(browserProvider);
    expect(state.tabs.length, 2);
    expect(state.activeTabIndex, 1);
    expect(state.tabs[1].url, 'https://b.com');
  });

  test('restoreTabs clamps out-of-range activeIndex', () {
    container.read(browserProvider.notifier)
        .restoreTabs([TabModel(url: 'https://a.com')], 5);
    expect(container.read(browserProvider).activeTabIndex, 0);
  });

  test('restoreTabs ignores empty list', () {
    container.read(browserProvider.notifier).restoreTabs([], 0);
    expect(container.read(browserProvider).tabs.length, 1);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/browser/browser_provider_test.dart`
Expected: FAIL — `restoreTabs` not defined.

- [ ] **Step 3: Add restoreTabs method**

In `lib/features/browser/providers/browser_provider.dart`, add inside `BrowserNotifier` (after `build()`):

```dart
  void restoreTabs(List<TabModel> tabs, int activeIndex) {
    if (tabs.isEmpty) return;
    final index = activeIndex.clamp(0, tabs.length - 1);
    state = BrowserState(tabs: tabs, activeTabIndex: index);
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/browser/browser_provider_test.dart`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/browser/providers/browser_provider.dart test/features/browser/browser_provider_test.dart
git commit -m "feat: add restoreTabs to BrowserNotifier"
```

---

### Task 4: sessionRestore setting

**Files:**
- Modify: `lib/features/settings/models/settings_model.dart`
- Modify: `lib/features/settings/providers/settings_provider.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`
- Modify: `lib/features/settings/widgets/settings_screen.dart:69` (add row in browsing GroupedCard)
- Test: `test/features/settings/settings_repository_test.dart` (add default assertion + round-trip)

**Interfaces:**
- Consumes: `SettingsRepository.set`/`loadAll`, existing `SettingsModel`.
- Produces: `SettingsModel.sessionRestore` (bool, default `true`); `SettingsNotifier.setSessionRestore(bool)`; settings key `session_restore` (`'false'` disables, anything else / absent = enabled). New l10n getters `l.sessionRestore`, `l.sessionRestoreSubtitle`.

- [ ] **Step 1: Write the failing test**

In `test/features/settings/settings_repository_test.dart`, add to the "returns defaults" test:

```dart
    expect(settings.sessionRestore, true);
```

and add a new test before the closing `}`:

```dart
  test('session_restore false round-trips', () async {
    await repo.set('session_restore', 'false');
    final settings = await repo.loadAll();
    expect(settings.sessionRestore, false);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings/settings_repository_test.dart`
Expected: FAIL — `sessionRestore` not a member of `SettingsModel`.

- [ ] **Step 3: Add field to SettingsModel**

In `lib/features/settings/models/settings_model.dart`:

1. Add field after `devLogEnabled`:
```dart
  final bool sessionRestore;
```
2. Add to constructor params (after `this.devLogEnabled = false,`):
```dart
    this.sessionRestore = true,
```
3. Add to `copyWith` params (after `bool? devLogEnabled,`):
```dart
    bool? sessionRestore,
```
4. Add to `copyWith` return (after `devLogEnabled: devLogEnabled ?? this.devLogEnabled,`):
```dart
      sessionRestore: sessionRestore ?? this.sessionRestore,
```
5. Add to `fromMap` return (after `devLogEnabled: map['dev_log_enabled'] == 'true',`):
```dart
      sessionRestore: map['session_restore'] != 'false',
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/settings/settings_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Add setter to SettingsNotifier**

In `lib/features/settings/providers/settings_provider.dart`, add after `setDevLogEnabled`:

```dart
  Future<void> setSessionRestore(bool enabled) async {
    await _repo.set('session_restore', enabled.toString());
    state = state.copyWith(sessionRestore: enabled);
  }
```

- [ ] **Step 6: Add l10n strings**

In `lib/l10n/app_en.arb`, before the closing `}` (add comma to previous last entry `"logsCopied": "Logs copied",`):

```json
  "sessionRestore": "Restore Tabs",
  "sessionRestoreSubtitle": "Reopen last session's tabs on launch"
```

In `lib/l10n/app_zh.arb`, before the closing `}` (add comma to previous `"logsCopied": "日志已复制",`):

```json
  "sessionRestore": "恢复标签页",
  "sessionRestoreSubtitle": "启动时重新打开上次的标签页"
```

- [ ] **Step 7: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: no errors; `l.sessionRestore` / `l.sessionRestoreSubtitle` now available.

- [ ] **Step 8: Add toggle row to settings UI**

In `lib/features/settings/widgets/settings_screen.dart`, add this `_SettingsRow` inside the browsing `GroupedCard` children, immediately after the viewportWidth row (currently ends at line 69, before the `],` at line 70):

```dart
                      _SettingsRow(
                        icon: Icons.restore,
                        iconColor: const Color(0xFF17A34A),
                        title: l.sessionRestore,
                        subtitle: l.sessionRestoreSubtitle,
                        trailing: IosToggle(
                          value: settings.sessionRestore,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setSessionRestore(v),
                        ),
                      ),
```

- [ ] **Step 9: Verify build**

Run: `flutter analyze lib/features/settings`
Expected: no errors.

- [ ] **Step 10: Commit**

```bash
git add lib/features/settings/ lib/l10n/ test/features/settings/settings_repository_test.dart
git commit -m "feat: add sessionRestore setting with toggle"
```

---

### Task 5: Wire save + restore into BrowserScreen

**Files:**
- Modify: `lib/features/browser/widgets/browser_screen.dart:33-47`

**Interfaces:**
- Consumes: `SessionRepository` + `sessionRepositoryProvider` (defined in this task), `settingsProvider`, `browserProvider.notifier.restoreTabs` (Task 3), `_controllers` map (existing, keyed by `tab.id`), `InAppWebViewController.getScrollY()`.
- Produces: `sessionRepositoryProvider` (a `Provider<SessionRepository>`); lifecycle-driven save + startup restore. No new public interface for later tasks.

- [ ] **Step 1: Add sessionRepositoryProvider**

In `lib/features/browser/repositories/session_repository.dart`, add at the top after imports:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

and at the end of the file:

```dart
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(DatabaseHelper.instance);
});
```

- [ ] **Step 2: Make BrowserScreen observe lifecycle + restore**

In `lib/features/browser/widgets/browser_screen.dart`:

1. Add import (with the other feature imports):
```dart
import 'package:zoomview/features/browser/repositories/session_repository.dart';
```

2. Change the state class declaration (line 33) to mix in `WidgetsBindingObserver`:
```dart
class _BrowserScreenState extends ConsumerState<BrowserScreen>
    with WidgetsBindingObserver {
```

3. Replace `initState` (lines 43-47) with:
```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      await ref.read(settingsProvider.notifier).load();
      if (!ref.read(settingsProvider).sessionRestore) return;
      final data = await ref.read(sessionRepositoryProvider).load();
      if (data != null) {
        ref
            .read(browserProvider.notifier)
            .restoreTabs(data.tabs, data.activeIndex);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.detached) {
      _saveSession();
    }
  }

  Future<void> _saveSession() async {
    if (!ref.read(settingsProvider).sessionRestore) return;
    final state = ref.read(browserProvider);
    final tabs = <TabModel>[];
    for (final tab in state.tabs) {
      final controller = _controllers[tab.id];
      var scroll = tab.scrollPosition;
      if (controller != null) {
        scroll = (await controller.getScrollY())?.toDouble() ?? scroll;
      }
      tabs.add(tab.copyWith(scrollPosition: scroll));
    }
    await ref
        .read(sessionRepositoryProvider)
        .save(tabs, state.activeTabIndex);
  }
```

4. Add the `TabModel` import if not already present (check top of file; add with other browser imports):
```dart
import 'package:zoomview/features/browser/models/tab_model.dart';
```

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/features/browser/widgets/browser_screen.dart lib/features/browser/repositories/session_repository.dart`
Expected: no errors.

- [ ] **Step 4: Run full test suite (regression check)**

Run: `flutter test`
Expected: PASS (no regressions).

- [ ] **Step 5: Manual verification**

Cannot be unit-tested (requires webview + app lifecycle). On a device/emulator:
1. Enable "Restore Tabs" in Settings (default on).
2. Open 2-3 tabs with different URLs, adjust zoom on one, scroll down on one.
3. Background the app fully (swipe away / kill), relaunch.
4. Expected: same tabs reopen, active tab preserved, zoom restored (scroll applied after Task 6).
5. Toggle "Restore Tabs" off, repeat: relaunch shows single blank tab.

- [ ] **Step 6: Commit**

```bash
git add lib/features/browser/widgets/browser_screen.dart lib/features/browser/repositories/session_repository.dart
git commit -m "feat: save and restore tab session on app lifecycle"
```

---

### Task 6: Apply scroll position on restore

**Files:**
- Modify: `lib/features/browser/widgets/webview_container.dart:374-386`

**Interfaces:**
- Consumes: existing post-load delayed callback (`Future.delayed(500ms)` with `_loadId` guard), `browserProvider` tab list, `_controller`, `InAppWebViewController.scrollTo`.
- Produces: no new interface. Reapplies stored `scrollPosition` after zoom on page load.

- [ ] **Step 1: Add scroll restore in the post-load callback**

In `lib/features/browser/widgets/webview_container.dart`, inside the existing `Future.delayed(const Duration(milliseconds: 500), () async { ... })` block, after the zoom-restore `if` (which ends around line 382, after `await _controller!.zoomBy(...)`) and before the `if (mounted && _loadId == myLoadId)` block, add:

```dart
          final storedScroll =
              ref.read(browserProvider).tabs[widget.tabIndex].scrollPosition;
          if (storedScroll > 0 && _controller != null) {
            await _controller!
                .scrollTo(x: 0, y: storedScroll.toInt(), animated: false);
          }
```

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze lib/features/browser/widgets/webview_container.dart`
Expected: no errors.

- [ ] **Step 3: Manual verification**

On a device/emulator: open a long page, scroll down, background+kill the app, relaunch. Expected: the tab reopens scrolled to approximately the previous position (may be off on late-rendering SPA pages; the 500ms delay mitigates this).

- [ ] **Step 4: Commit**

```bash
git add lib/features/browser/widgets/webview_container.dart
git commit -m "feat: restore scroll position on tab reload"
```

---

## Self-Review

**Spec coverage:**
- Storage (SessionRepository, settings table, JSON) → Task 2 ✓
- Serialization (TabModel toJson/fromJson) → Task 1 ✓
- Restore path (restoreTabs) → Task 3 ✓
- Settings toggle (field, setter, UI, l10n) → Task 4 ✓
- Save timing (lifecycle observer) + restore wiring → Task 5 ✓
- Scroll capture (getScrollY at save) → Task 5; scroll apply → Task 6 ✓
- Edge cases (null/empty/malformed/clamp/startpage) → Tasks 2 & 3 tests ✓

**Type consistency:** `SessionData(tabs, activeIndex)` positional constructor used consistently. `restoreTabs(List<TabModel>, int)` signature matches Task 3 def and Task 5 call. `getScrollY()?.toDouble()` (save) and `scrollPosition.toInt()` (apply) honor the int/double boundary. `sessionRepositoryProvider` defined in Task 5 Step 1, consumed in Task 5 Step 2.

**Notes:** Tasks 5 & 6 (webview + lifecycle) are verified manually — not unit-testable without a webview harness. All logic tasks (1-4) are TDD with real DB tests.
