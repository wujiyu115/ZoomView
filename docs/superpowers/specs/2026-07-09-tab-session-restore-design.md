# Tab Session Restore — Design

Date: 2026-07-09
Status: Approved

## Problem

zoomview holds tab state entirely in memory. When the app closes, all open
tabs are lost; next launch always starts with a single blank tab. Users lose
their browsing session.

## Goal

Persist open tabs on app close and restore them on next launch, gated behind a
user-controlled setting (default on).

## Non-goals

- Persisting favicon (reloaded from the page on restore).
- Persisting full navigation history (back/forward stack) per tab.
- Cross-device / cloud session sync.

## Decisions (from brainstorming)

| Decision      | Choice                                                        |
|---------------|--------------------------------------------------------------|
| Restore gate  | Setting toggle `sessionRestore`, default **on**              |
| Save timing   | App lifecycle (`paused` / `detached`) via WidgetsBindingObserver |
| Storage       | `settings` table, JSON value (no DB migration needed)        |
| Per-tab data  | `url`, `title`, `zoomLevel`, `scrollPosition`                |

## Architecture

### Storage — `SessionRepository`

New file `lib/features/browser/repositories/session_repository.dart`. Uses
`DatabaseHelper` directly against the existing `settings` table (key/value).
Two keys:

- `session_tabs` — JSON array of serialized tabs.
- `session_active` — active tab index (string int).

Kept separate from `SettingsRepository` because that repo maps rows into the
typed `SettingsModel`; the session JSON does not fit that shape. Isolation keeps
each repository single-purpose.

Interface:

```dart
class SessionRepository {
  SessionRepository(this._dbHelper);
  Future<void> save(List<TabModel> tabs, int activeIndex);
  Future<SessionData?> load(); // null when no session stored
  Future<void> clear();
}

class SessionData {
  final List<TabModel> tabs;
  final int activeIndex;
}
```

Provider: `sessionRepositoryProvider` (mirrors `settingsRepositoryProvider`).

### Serialization — `TabModel`

Add to `lib/features/browser/models/tab_model.dart`:

```dart
Map<String, dynamic> toJson() => {
  'url': url,
  'title': title,
  'zoomLevel': zoomLevel,
  'scrollPosition': scrollPosition,
};

factory TabModel.fromJson(Map<String, dynamic> json) => TabModel(
  url: json['url'] as String? ?? '',
  title: json['title'] as String? ?? '',
  zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
  scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0,
  showStartPage: (json['url'] as String? ?? '').isEmpty,
);
```

- `id` is regenerated (fresh UUID) on restore — controllers key off id, and a
  new session needs fresh keys.
- `favicon` omitted; reloaded from the page.
- `isActive` omitted; active tab derived from `session_active` index.
- `showStartPage` derived: empty url → start page.

### Restore path — `BrowserNotifier`

Add to `lib/features/browser/providers/browser_provider.dart`:

```dart
void restoreTabs(List<TabModel> tabs, int activeIndex) {
  if (tabs.isEmpty) return;
  final index = activeIndex.clamp(0, tabs.length - 1);
  state = BrowserState(tabs: tabs, activeTabIndex: index);
}
```

`build()` still returns the default single blank tab synchronously; restore
happens after async DB read (see wiring).

### Settings toggle

`lib/features/settings/models/settings_model.dart`: add
`final bool sessionRestore;` (default `true`), wire into constructor,
`copyWith`, and `fromMap` (`map['session_restore'] != 'false'`).

`lib/features/settings/providers/settings_provider.dart`: add

```dart
Future<void> setSessionRestore(bool enabled) async {
  await _repo.set('session_restore', enabled.toString());
  state = state.copyWith(sessionRestore: enabled);
}
```

`lib/features/settings/widgets/settings_screen.dart`: add a `SwitchListTile`
(follow existing dark-mode / dev-log switch pattern). Add l10n strings to
`lib/l10n/app_en.arb` and `app_zh.arb` (e.g. `sessionRestoreTitle`,
`sessionRestoreSubtitle`).

### Wiring — `browser_screen.dart`

Make `_BrowserScreenState` a `WidgetsBindingObserver`.

**Restore** (in `initState`, after settings load):

```dart
Future.microtask(() async {
  await ref.read(settingsProvider.notifier).load();
  if (!ref.read(settingsProvider).sessionRestore) return;
  final data = await ref.read(sessionRepositoryProvider).load();
  if (data != null) {
    ref.read(browserProvider.notifier).restoreTabs(data.tabs, data.activeIndex);
  }
});
```

**Save** (`didChangeAppLifecycleState`, on `paused` / `detached`):

```dart
if (!ref.read(settingsProvider).sessionRestore) return;
final state = ref.read(browserProvider);
final tabs = <TabModel>[];
for (final tab in state.tabs) {
  final controller = _controllers[tab.id];
  double scroll = tab.scrollPosition;
  if (controller != null) {
    scroll = (await controller.getScrollY())?.toDouble() ?? scroll;
  }
  tabs.add(tab.copyWith(scrollPosition: scroll));
}
await ref.read(sessionRepositoryProvider).save(tabs, state.activeTabIndex);
```

Register observer in `initState` (`WidgetsBinding.instance.addObserver(this)`),
remove in `dispose`. `TabModel.copyWith` already accepts `scrollPosition`
(tab_model.dart:33).

### Scroll apply — `webview_container.dart`

Mirror the existing zoom-restore block (webview_container.dart:377-386) inside
the same post-load delayed callback: after applying stored zoom, read the tab's
`scrollPosition` and call
`controller.scrollTo(x: 0, y: stored.toInt(), animated: false)` when > 0. Reuse
the existing 500ms delay + `_loadId` guard so SPA / late-layout pages have
settled before scrolling.

Note on types: `getScrollY()` returns `Future<int?>` and `scrollTo` takes
`int` x/y (flutter_inappwebview 6.1.5), while `TabModel.scrollPosition` is a
`double`. Convert at the boundaries: `getScrollY()?.toDouble()` on save,
`scrollPosition.toInt()` on apply.

## Edge cases

- **No stored session** → `load()` returns null → keep default blank tab.
- **Stored empty list** → treated as no session.
- **Toggle off** → skip both save and restore. (Existing stored session left
  as-is; not cleared. Turning back on restores it next launch.)
- **Malformed JSON** → `load()` catches, returns null, logs via AppLogger.
- **activeIndex out of range** → clamped in `restoreTabs`.
- **Tab that was on start page** (`url == ''`) → restored as start-page tab.

## Testing

- `TabModel` JSON round-trip (unit): toJson → fromJson preserves url/title/zoom/
  scroll; empty url → showStartPage true.
- `SessionRepository` save/load/clear against `DatabaseHelper.forTesting()`
  (in-memory sqflite): round-trip a multi-tab session; load with no data →
  null; malformed value → null.
- `BrowserNotifier.restoreTabs`: replaces state, clamps activeIndex, ignores
  empty list.

## Out of scope for this change

Back/forward stack persistence, favicon caching, session-history (multiple named
sessions), tab groups.
