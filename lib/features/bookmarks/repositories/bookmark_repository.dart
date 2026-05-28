import 'package:zoomview/core/database/database_helper.dart';
import '../models/bookmark_model.dart';
import '../models/folder_model.dart';

class BookmarkRepository {
  final DatabaseHelper _dbHelper;
  BookmarkRepository(this._dbHelper);

  Future<int> createFolder(String name, {int? parentId}) async {
    final db = await _dbHelper.database;
    return db.insert('bookmark_folders', {
      'name': name,
      'parent_id': parentId,
      'sort_order': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<BookmarkFolder>> getFolders({int? parentId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query('bookmark_folders',
        where: parentId == null ? 'parent_id IS NULL' : 'parent_id = ?',
        whereArgs: parentId == null ? null : [parentId],
        orderBy: 'sort_order ASC, name ASC');
    return rows.map((r) => BookmarkFolder.fromMap(r)).toList();
  }

  Future<void> deleteFolder(int id) async {
    final db = await _dbHelper.database;
    await db.delete('bookmark_folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addBookmark(String title, String url, {int? folderId}) async {
    final db = await _dbHelper.database;
    return db.insert('bookmarks', {
      'title': title,
      'url': url,
      'folder_id': folderId,
      'sort_order': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Bookmark>> getBookmarks({int? folderId}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> rows;
    if (folderId == null) {
      rows = await db.query('bookmarks',
          orderBy: 'sort_order ASC, created_at DESC');
    } else {
      rows = await db.query('bookmarks',
          where: 'folder_id = ?',
          whereArgs: [folderId],
          orderBy: 'sort_order ASC, created_at DESC');
    }
    return rows.map((r) => Bookmark.fromMap(r)).toList();
  }

  Future<void> deleteBookmark(int id) async {
    final db = await _dbHelper.database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> moveBookmark(int bookmarkId, int? folderId) async {
    final db = await _dbHelper.database;
    await db.update('bookmarks', {'folder_id': folderId},
        where: 'id = ?', whereArgs: [bookmarkId]);
  }

  Future<List<Bookmark>> searchBookmarks(String query) async {
    final db = await _dbHelper.database;
    final rows = await db.query('bookmarks',
        where: 'title LIKE ? OR url LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'created_at DESC');
    return rows.map((r) => Bookmark.fromMap(r)).toList();
  }
}
