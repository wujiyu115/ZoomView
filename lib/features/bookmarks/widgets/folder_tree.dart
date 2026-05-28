import 'package:flutter/material.dart';
import 'package:zoomview/l10n/app_localizations.dart';
import '../models/bookmark_model.dart';
import '../models/folder_model.dart';

class FolderTree extends StatelessWidget {
  final List<BookmarkFolder> folders;
  final List<Bookmark> bookmarks;
  final ValueChanged<BookmarkFolder> onFolderTap;
  final ValueChanged<BookmarkFolder> onFolderDelete;
  final ValueChanged<Bookmark> onBookmarkTap;
  final ValueChanged<Bookmark> onBookmarkDelete;
  final void Function(Bookmark bookmark) onBookmarkMove;

  const FolderTree({
    super.key,
    required this.folders,
    required this.bookmarks,
    required this.onFolderTap,
    required this.onFolderDelete,
    required this.onBookmarkTap,
    required this.onBookmarkDelete,
    required this.onBookmarkMove,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (folders.isEmpty && bookmarks.isEmpty) {
      return Center(
        child: Text(l.noBookmarksYet, style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      children: [
        ...folders.map((folder) => ListTile(
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: Text(folder.name),
              onTap: () => onFolderTap(folder),
              onLongPress: () => _showFolderMenu(context, folder),
            )),
        ...bookmarks.map((bookmark) => Dismissible(
              key: ValueKey(bookmark.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => onBookmarkDelete(bookmark),
              child: ListTile(
                leading: const Icon(Icons.bookmark, color: Colors.blue),
                title: Text(bookmark.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(bookmark.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => onBookmarkTap(bookmark),
                onLongPress: () => _showBookmarkMenu(context, bookmark),
              ),
            )),
      ],
    );
  }

  void _showFolderMenu(BuildContext context, BookmarkFolder folder) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(l.deleteFolder),
              onTap: () {
                Navigator.pop(ctx);
                onFolderDelete(folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarkMenu(BuildContext context, Bookmark bookmark) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: Text(l.moveToFolder),
              onTap: () {
                Navigator.pop(ctx);
                onBookmarkMove(bookmark);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(l.delete),
              onTap: () {
                Navigator.pop(ctx);
                onBookmarkDelete(bookmark);
              },
            ),
          ],
        ),
      ),
    );
  }
}
