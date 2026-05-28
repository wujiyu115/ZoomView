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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        leading: state.currentFolderId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(bookmarkProvider.notifier).load(),
              )
            : null,
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
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search bookmarks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(bookmarkProvider.notifier).search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (query) {
                ref.read(bookmarkProvider.notifier).search(query);
                setState(() {}); // rebuild to show/hide clear button
              },
            ),
          ),
          Expanded(
            child: FolderTree(
              folders: state.folders,
              bookmarks: state.bookmarks,
              onFolderTap: (folder) {
                ref
                    .read(bookmarkProvider.notifier)
                    .load(folderId: folder.id);
              },
              onFolderDelete: (folder) {
                ref
                    .read(bookmarkProvider.notifier)
                    .deleteFolder(folder.id!);
              },
              onBookmarkTap: (bookmark) {
                Navigator.pop(context, bookmark.url);
              },
              onBookmarkDelete: (bookmark) {
                ref
                    .read(bookmarkProvider.notifier)
                    .deleteBookmark(bookmark.id!);
              },
              onBookmarkMove: (bookmark) {
                _showMoveDialog(context, bookmark);
              },
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
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(bookmarkProvider.notifier).createFolder(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(
      BuildContext context, dynamic bookmark) {
    final repo = ref.read(bookmarkRepositoryProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Folder'),
        content: FutureBuilder(
          future: repo.getFolders(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final folders = snapshot.data!;
            if (folders.isEmpty) {
              return const Text('No folders available');
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder_open),
                    title: const Text('Root (no folder)'),
                    onTap: () {
                      ref
                          .read(bookmarkProvider.notifier)
                          .moveBookmark(bookmark.id!, null);
                      Navigator.pop(ctx);
                    },
                  ),
                  ...folders.map((folder) => ListTile(
                        leading:
                            const Icon(Icons.folder, color: Colors.amber),
                        title: Text(folder.name),
                        onTap: () {
                          ref
                              .read(bookmarkProvider.notifier)
                              .moveBookmark(bookmark.id!, folder.id);
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
