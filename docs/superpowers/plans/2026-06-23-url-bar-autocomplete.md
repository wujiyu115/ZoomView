# URL Bar Autocomplete & Bug Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix URL bar `_isEditing` bug and add autocomplete dropdown from history + bookmarks.

**Architecture:** Self-contained in `UrlBar` widget. Add `FocusNode` to fix `_isEditing` stuck-true bug. On text change, debounce 300ms, query `HistoryRepository.search()` + `BookmarkRepository.searchBookmarks()` in parallel, merge/deduplicate, show max 8 suggestions in an `Overlay` dropdown below the URL bar.

**Tech Stack:** Flutter, Riverpod, sqflite, dart:async (Timer for debounce)

## Global Constraints

- Flutter 3.x, Riverpod 3.x (`Notifier` pattern)
- Theme via `AppColors` extension (`context.appColors`)
- Database via singleton `DatabaseHelper.instance`
- Existing `HistoryRepository.search(query)` and `BookmarkRepository.searchBookmarks(query)` — use directly, no modifications needed

---

### Task 1: Fix `_isEditing` bug — add FocusNode to UrlBar

**Files:**
- Modify: `lib/features/browser/widgets/url_bar.dart`

**Interfaces:**
- Consumes: existing `UrlBar` widget API (no changes to public interface)
- Produces: `_isEditing` correctly resets on focus loss; `_focusNode` available for Task 2

- [ ] **Step 1: Add FocusNode and focus listener**

In `_UrlBarState`, add a `FocusNode`, initialize in `initState`, dispose in `dispose`, and listen for focus changes to reset `_isEditing`:

```dart
class _UrlBarState extends State<UrlBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.url);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() => _isEditing = false);
      _controller.text = widget.url;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
```

- [ ] **Step 2: Wire FocusNode to TextField**

In the `TextField` widget, add `focusNode: _focusNode`:

```dart
TextField(
  controller: _controller,
  focusNode: _focusNode,
  style: TextStyle(fontSize: 14, color: colors.fg2),
  // ... rest unchanged
)
```

- [ ] **Step 3: Verify build succeeds**

Run: `cd /home/ejoy/git/zoomview && flutter build apk --debug 2>&1 | tail -20`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add lib/features/browser/widgets/url_bar.dart
git commit -m "fix: reset _isEditing on URL bar focus loss"
```

---

### Task 2: Add autocomplete dropdown to UrlBar

**Files:**
- Modify: `lib/features/browser/widgets/url_bar.dart`

**Interfaces:**
- Consumes: `HistoryRepository.search(String query) → Future<List<HistoryModel>>`, `BookmarkRepository.searchBookmarks(String query) → Future<List<Bookmark>>`, `DatabaseHelper.instance`, `FocusNode` from Task 1
- Produces: complete autocomplete UI — dropdown overlay with suggestions from history + bookmarks

- [ ] **Step 1: Add imports and state fields for autocomplete**

Add imports and new state fields to `_UrlBarState`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/features/history/repositories/history_repository.dart';
import 'package:zoomview/features/history/models/history_model.dart';
import 'package:zoomview/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:zoomview/features/bookmarks/models/bookmark_model.dart';
```

In `_UrlBarState`, add:

```dart
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<_Suggestion> _suggestions = [];
  Timer? _debounce;
  final _historyRepo = HistoryRepository(DatabaseHelper.instance);
  final _bookmarkRepo = BookmarkRepository(DatabaseHelper.instance);
```

And define the unified suggestion model at file bottom:

```dart
enum _SuggestionSource { history, bookmark }

class _Suggestion {
  final String title;
  final String url;
  final _SuggestionSource source;

  const _Suggestion({
    required this.title,
    required this.url,
    required this.source,
  });
}
```

- [ ] **Step 2: Add debounced search method**

Add `_onSearchChanged` and `_performSearch` methods to `_UrlBarState`:

```dart
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _dismissOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final results = await Future.wait([
      _historyRepo.search(query),
      _bookmarkRepo.searchBookmarks(query),
    ]);

    final historyItems = (results[0] as List<HistoryModel>)
        .map((h) => _Suggestion(
              title: h.title,
              url: h.url,
              source: _SuggestionSource.history,
            ));

    final bookmarkItems = (results[1] as List<Bookmark>)
        .map((b) => _Suggestion(
              title: b.title,
              url: b.url,
              source: _SuggestionSource.bookmark,
            ));

    final seen = <String>{};
    final merged = <_Suggestion>[];
    for (final item in [...historyItems, ...bookmarkItems]) {
      if (seen.add(item.url) && merged.length < 8) {
        merged.add(item);
      }
    }

    if (!mounted) return;
    setState(() => _suggestions = merged);

    if (merged.isEmpty) {
      _dismissOverlay();
    } else {
      _showOverlay();
    }
  }
```

- [ ] **Step 3: Add overlay show/dismiss methods**

```dart
  void _showOverlay() {
    _dismissOverlay();
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _dismissOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay() {
    final colors = context.appColors;
    return Positioned(
      width: MediaQuery.of(context).size.width - 32,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 48),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: colors.surfaceElevated,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions.map((s) => _buildSuggestionTile(s, colors)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(_Suggestion suggestion, AppColors colors) {
    return InkWell(
      onTap: () {
        _focusNode.unfocus();
        _dismissOverlay();
        widget.onSubmitted(suggestion.url);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              suggestion.source == _SuggestionSource.history
                  ? Icons.history
                  : Icons.bookmark_outline,
              size: 16,
              color: colors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: TextStyle(fontSize: 14, color: colors.fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    suggestion.url,
                    style: TextStyle(fontSize: 12, color: colors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 4: Update _onFocusChange to dismiss overlay**

Update the existing `_onFocusChange` from Task 1:

```dart
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() => _isEditing = false);
      _controller.text = widget.url;
      _dismissOverlay();
    }
  }
```

- [ ] **Step 5: Update dispose to clean up debounce timer and overlay**

```dart
  @override
  void dispose() {
    _debounce?.cancel();
    _dismissOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
```

- [ ] **Step 6: Wire onChanged to TextField and wrap container in CompositedTransformTarget**

In `build()`, wrap the URL bar `Container` with `CompositedTransformTarget`:

```dart
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            decoration: BoxDecoration(
              color: colors.urlBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: colors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: TextStyle(fontSize: 14, color: colors.fg2),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onTap: () => setState(() => _isEditing = true),
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      _dismissOverlay();
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
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: widget.progress,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: colors.accent,
            ),
          ),
      ],
    );
  }
```

- [ ] **Step 7: Verify build succeeds**

Run: `cd /home/ejoy/git/zoomview && flutter build apk --debug 2>&1 | tail -20`
Expected: BUILD SUCCESSFUL

- [ ] **Step 8: Commit**

```bash
git add lib/features/browser/widgets/url_bar.dart
git commit -m "feat: add autocomplete dropdown to URL bar from history and bookmarks"
```
