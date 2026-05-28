# ZoomView Browser — Design Spec

## Overview

ZoomView is a Flutter mobile browser (iOS + Android) that loads all websites in desktop mode by default, with a precision zoom slider for comfortable reading on mobile screens. Core differentiator: desktop-class browsing experience with fine-grained zoom control.

## Tech Stack

- **Framework:** Flutter (iOS + Android only)
- **WebView:** flutter_inappwebview (Android: system WebView, iOS: WKWebView)
- **State Management:** Riverpod
- **Database:** SQLite (sqflite)
- **Downloads:** flutter_downloader
- **Notifications:** flutter_local_notifications
- **Architecture:** Single-project, feature-based directory structure
- **Theme:** Dark mode by default, Material 3

## Project Structure

```
zoomview/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants.dart
│   │   ├── theme.dart
│   │   └── database/
│   │       ├── database_helper.dart
│   │       └── tables.dart
│   ├── features/
│   │   ├── browser/
│   │   │   ├── models/tab_model.dart
│   │   │   ├── providers/browser_provider.dart
│   │   │   └── widgets/
│   │   │       ├── browser_screen.dart
│   │   │       ├── toolbar.dart
│   │   │       ├── url_bar.dart
│   │   │       ├── zoom_slider.dart
│   │   │       ├── tab_manager.dart
│   │   │       └── webview_container.dart
│   │   ├── bookmarks/
│   │   │   ├── models/bookmark_model.dart
│   │   │   ├── models/folder_model.dart
│   │   │   ├── providers/bookmark_provider.dart
│   │   │   ├── repositories/bookmark_repository.dart
│   │   │   └── widgets/
│   │   │       ├── bookmark_screen.dart
│   │   │       └── folder_tree.dart
│   │   ├── downloads/
│   │   │   ├── models/download_model.dart
│   │   │   ├── providers/download_provider.dart
│   │   │   ├── repositories/download_repository.dart
│   │   │   └── widgets/
│   │   │       ├── download_screen.dart
│   │   │       └── download_item.dart
│   │   ├── history/
│   │   │   ├── models/history_model.dart
│   │   │   ├── providers/history_provider.dart
│   │   │   ├── repositories/history_repository.dart
│   │   │   └── widgets/history_screen.dart
│   │   └── settings/
│   │       ├── models/settings_model.dart
│   │       ├── providers/settings_provider.dart
│   │       ├── repositories/settings_repository.dart
│   │       └── widgets/settings_screen.dart
```

## Feature: Core Browser

### Tab Model

```dart
TabModel {
  id: String (uuid)
  url: String
  title: String
  favicon: Uint8List?
  zoomLevel: double (1.0-3.0)
  scrollPosition: double
  isActive: bool
  createdAt: DateTime
}
```

### WebView Configuration

- Desktop User-Agent by default: `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36`
- `viewportWidth: 1920` to simulate desktop screen
- System zoom controls disabled; only custom slider
- Force-override `user-scalable=no` via JS injection

### Tab Management

- Each tab holds its own `InAppWebViewController`
- Inactive tabs hidden via `Offstage`/`IndexedStack` (state preserved)
- Tab manager view: grid of tab previews, new/close/switch actions

### BrowserProvider State

- `List<TabModel> tabs`
- `int activeTabIndex`
- `bool isLoading`
- `double progress` (for URL bar progress indicator)

### Zoom Slider

- Range: 1.0x – 3.0x, step 0.1
- Per-tab independent zoom memory
- Layout: `[-] ——slider—— [+]` with percentage label (e.g. "150%")
- Calls `controller.setZoomFactor(value)`

### Toolbar (top, left to right)

```
[Home] [Bookmarks] [Refresh] [Back] [Forward] [More…] [Settings] [Tabs] [Download]
```

### More Menu Items

- Share page
- Find in page
- Toggle desktop/mobile mode
- Add bookmark

## Feature: Bookmarks

### Models

```
BookmarkFolder {
  id: int
  name: String
  parentId: int?        // null = root
  sortOrder: int
  createdAt: DateTime
}

Bookmark {
  id: int
  title: String
  url: String
  favicon: Uint8List?
  folderId: int?        // null = uncategorized
  sortOrder: int
  createdAt: DateTime
}
```

### Functionality

- Tree folder structure, nested folders supported
- Long-press drag to reorder
- Long-press context menu: edit, delete, move to folder
- Toolbar bookmark icon → full-screen bookmark page
- More menu → "Add Bookmark" quick-save current page
- Search bar at top: fuzzy match by title/URL

### SQLite Tables

- `bookmark_folders` (id, name, parent_id, sort_order, created_at)
- `bookmarks` (id, title, url, favicon, folder_id, sort_order, created_at)

## Feature: Downloads

### Model

```
DownloadModel {
  id: int
  url: String
  fileName: String
  filePath: String
  mimeType: String?
  totalBytes: int
  downloadedBytes: int
  status: DownloadStatus  // pending, downloading, paused, completed, failed
  createdAt: DateTime
}
```

### Functionality

- Intercept downloads via `onDownloadStartRequest`
- Save to app directory (Android: external storage, iOS: app documents)
- Download list: progress bar, file size, status badge
- Actions: pause/resume, cancel, open file, delete record
- Notification bar progress via flutter_local_notifications
- Max 3 concurrent downloads

### SQLite Table

- `downloads` (id, url, file_name, file_path, mime_type, total_bytes, downloaded_bytes, status, created_at)

## Feature: History

### Model

```
HistoryModel {
  id: int
  title: String
  url: String
  favicon: Uint8List?
  visitedAt: DateTime
}
```

### Functionality

- Auto-record on page load complete
- Grouped by date: Today, Yesterday, Earlier
- Search bar: fuzzy match title/URL
- Swipe to delete single entry, top button to clear all
- Access via More menu or Settings

### SQLite Table

- `history` (id, title, url, favicon, visited_at)

## Feature: Settings

Storage: SQLite `settings` table (key-value), loaded into Riverpod provider at startup.

| Group | Option | Default |
|-------|--------|---------|
| Browsing | UA mode (Desktop/Mobile) | Desktop |
| Browsing | Default search engine (Google/Bing/DuckDuckGo) | Google |
| Browsing | Home URL | https://www.google.com |
| Browsing | Viewport width (1280/1920/2560) | 1920 |
| Zoom | Default zoom level | 1.0x |
| Zoom | Min zoom | 1.0x |
| Zoom | Max zoom | 3.0x |
| Privacy | Clear cookies | Action button |
| Privacy | Clear cache | Action button |
| Privacy | Clear history | Action button |
| Privacy | Clear all data | Action button |
| Appearance | Dark mode | On |
| About | Version, license | — |

## UI Layout (Main Screen)

```
┌─────────────────────────────────┐
│ [Home][BM][↻][←][→][⋯][⚙][▦][↓]│  ← Toolbar
├─────────────────────────────────┤
│ [🔒 https://github.com       ] │  ← URL bar + progress
├─────────────────────────────────┤
│                                 │
│                                 │
│         WebView Content         │
│      (desktop mode, 1920px)     │
│                                 │
│                                 │
├─────────────────────────────────┤
│ [−] ════════●══════════ [+]     │  ← Zoom slider + "150%"
└─────────────────────────────────┘
```

## Dependencies

```yaml
dependencies:
  flutter_inappwebview: ^6.0.0
  flutter_riverpod: ^2.5.0
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  flutter_downloader: ^1.11.0
  flutter_local_notifications: ^17.0.0
  uuid: ^4.0.0
  share_plus: ^9.0.0
  url_launcher: ^6.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```
