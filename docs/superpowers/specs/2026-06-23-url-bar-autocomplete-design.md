# URL Bar Autocomplete & Bug Fix

## Problem

1. **Bug**: `_isEditing` flag in `UrlBar` set `true` on tap, only reset on submit. If user taps URL bar then navigates via bookmark/history/back, flag stays `true` forever — URL bar stops updating.
2. **Feature**: No autocomplete in URL bar. Users must type full URLs or navigate to history/bookmark screens.

## Solution

### Bug Fix: `_isEditing` reset on focus loss

- Add `FocusNode` to URL bar `TextField`
- Listen for focus changes: set `_isEditing = false` when focus lost
- This also naturally dismisses autocomplete dropdown

### Feature: Autocomplete dropdown

**Data sources**: History (`HistoryRepository`) + Bookmarks (`BookmarkRepository`)

**Query flow**:
1. User types in URL bar → `onChanged` fires
2. Debounce 300ms
3. Query `HistoryRepository.search(query)` + `BookmarkRepository.searchBookmarks(query)` in parallel
4. Merge results: deduplicate by URL, history items first, then bookmarks
5. Max 8 suggestions

**UI**:
- `Overlay` positioned below URL bar using `LayerLink` + `CompositedTransformFollower`
- Each item: title (primary) + URL (secondary, muted), with source icon (history clock / bookmark star)
- Tap item → call `onSubmitted(url)`, dismiss dropdown
- Styling matches app theme (`AppColors`)

**Dismiss triggers**:
- User submits text (Enter/Go)
- Focus lost (tap outside, navigate away, press back)
- Input cleared to empty

**Architecture**: Self-contained in `UrlBar` widget. No new provider needed. Queries repositories directly.

## Files to modify

| File | Change |
|------|--------|
| `lib/features/browser/widgets/url_bar.dart` | Add FocusNode, autocomplete overlay, debounced search |
| `lib/features/history/repositories/history_repository.dart` | Verify `search()` method works (already exists) |
| `lib/features/bookmarks/repositories/bookmark_repository.dart` | Verify `searchBookmarks()` exists (already exists) |

## Out of scope

- Search engine remote suggestions
- Frecency scoring (visit frequency × recency)
- Keyboard navigation of suggestions (up/down arrow)
