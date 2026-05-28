import 'package:zoomview/core/database/database_helper.dart';
import '../models/download_model.dart';

class DownloadRepository {
  final DatabaseHelper _dbHelper;
  DownloadRepository(this._dbHelper);

  Future<int> addDownload({
    required String url,
    required String fileName,
    required String filePath,
    String? mimeType,
    int totalBytes = 0,
  }) async {
    final db = await _dbHelper.database;
    return db.insert('downloads', {
      'url': url,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'total_bytes': totalBytes,
      'downloaded_bytes': 0,
      'status': DownloadStatus.pending.name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<DownloadModel>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('downloads', orderBy: 'created_at DESC');
    return rows.map((r) => DownloadModel.fromMap(r)).toList();
  }

  Future<void> updateStatus(int id, DownloadStatus status) async {
    final db = await _dbHelper.database;
    await db.update('downloads', {'status': status.name},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProgress(int id, int downloadedBytes) async {
    final db = await _dbHelper.database;
    await db.update('downloads', {'downloaded_bytes': downloadedBytes},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteDownload(int id) async {
    final db = await _dbHelper.database;
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }
}
