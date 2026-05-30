import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/core/widgets/ios_nav_header.dart';
import 'package:zoomview/core/widgets/grouped_card.dart';
import 'package:zoomview/core/widgets/colored_icon_box.dart';
import 'package:zoomview/core/widgets/search_bar_widget.dart';
import 'package:zoomview/core/widgets/section_header.dart';
import 'package:zoomview/l10n/app_localizations.dart';
import '../models/bookmark_model.dart';
import '../models/folder_model.dart';
import '../providers/bookmark_provider.dart';

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
    Future.microtask(() => ref.read(bookmarkProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarkProvider);
    final colors = context.appColors;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            IosNavHeader(
              title: l.bookmarks,
              showBack: state.currentFolderId != null || Navigator.canPop(context),
              trailing: GestureDetector(
                onTap: () => _showCreateFolderDialog(context),
                child: Text(
                  l.edit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.accent,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBarWidget(
                hint: l.searchBookmarks,
                controller: _searchController,
                onChanged: (query) {
                  ref.read(bookmarkProvider.notifier).search(query);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildContent(state, colors, l),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(dynamic state, dynamic colors, AppLocalizations l) {
    final folders = state.folders as List<BookmarkFolder>;
    final bookmarks = state.bookmarks as List<Bookmark>;

    if (folders.isEmpty && bookmarks.isEmpty) {
      return Center(
        child: Text(l.noBookmarksYet, style: TextStyle(color: colors.muted)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (folders.isNotEmpty) ...[
          SectionHeader(label: l.bookmarks),
          GroupedCard(
            children: folders.map((folder) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ref.read(bookmarkProvider.notifier).load(folderId: folder.id),
                onLongPress: () => _showFolderMenu(context, folder),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      ColoredIconBox(
                        color: colors.accent,
                        icon: Icons.folder,
                        size: 36,
                        borderRadius: 10,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          folder.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: colors.fg,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: colors.border),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (bookmarks.isNotEmpty) ...[
          if (folders.isNotEmpty) const SizedBox(height: 8),
          GroupedCard(
            children: bookmarks.map((bookmark) {
              final domain = Uri.tryParse(bookmark.url)?.host ?? bookmark.url;
              final letter = bookmark.title.isNotEmpty
                  ? bookmark.title[0].toUpperCase()
                  : '?';

              return Dismissible(
                key: ValueKey(bookmark.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: colors.danger,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => ref.read(bookmarkProvider.notifier).deleteBookmark(bookmark.id!),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context, bookmark.url),
                  onLongPress: () => _showBookmarkMenu(context, bookmark),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        ColoredIconBox(
                          color: colors.urlBg,
                          letter: letter,
                          size: 36,
                          borderRadius: 10,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookmark.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: colors.fg,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                domain,
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
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.newFolder),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.folderName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(bookmarkProvider.notifier).createFolder(name);
                Navigator.pop(ctx);
              }
            },
            child: Text(l.create),
          ),
        ],
      ),
    );
  }

  void _showFolderMenu(BuildContext context, BookmarkFolder folder) {
    final l = AppLocalizations.of(context)!;
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 5,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.delete, color: colors.danger),
                title: Text(l.deleteFolder, style: TextStyle(color: colors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(bookmarkProvider.notifier).deleteFolder(folder.id!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookmarkMenu(BuildContext context, Bookmark bookmark) {
    final l = AppLocalizations.of(context)!;
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 5,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.drive_file_move, color: colors.accent),
                title: Text(l.moveToFolder),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMoveDialog(context, bookmark);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: colors.danger),
                title: Text(l.delete, style: TextStyle(color: colors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(bookmarkProvider.notifier).deleteBookmark(bookmark.id!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveDialog(BuildContext context, Bookmark bookmark) {
    final l = AppLocalizations.of(context)!;
    final repo = ref.read(bookmarkRepositoryProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.moveToFolder),
        content: FutureBuilder(
          future: repo.getFolders(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final folders = snapshot.data!;
            if (folders.isEmpty) {
              return Text(l.noFoldersAvailable);
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder_open),
                    title: Text(l.rootNoFolder),
                    onTap: () {
                      ref.read(bookmarkProvider.notifier).moveBookmark(bookmark.id!, null);
                      Navigator.pop(ctx);
                    },
                  ),
                  ...folders.map((folder) => ListTile(
                        leading: const Icon(Icons.folder, color: Colors.amber),
                        title: Text(folder.name),
                        onTap: () {
                          ref.read(bookmarkProvider.notifier).moveBookmark(bookmark.id!, folder.id);
                          Navigator.pop(ctx);
                        },
                      )),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
        ],
      ),
    );
  }
}
