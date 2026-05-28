import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zoomview/core/database/database_helper.dart';
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
      await repo.addBookmark('GitHub', 'https://github.com', folderId: folderId);
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
