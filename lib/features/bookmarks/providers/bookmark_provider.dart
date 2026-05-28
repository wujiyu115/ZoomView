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
    NotifierProvider<BookmarkNotifier, BookmarkState>(BookmarkNotifier.new);

class BookmarkNotifier extends Notifier<BookmarkState> {
  @override
  BookmarkState build() => const BookmarkState();

  BookmarkRepository get _repo => ref.read(bookmarkRepositoryProvider);

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
