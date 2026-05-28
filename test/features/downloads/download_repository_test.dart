import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/features/downloads/models/download_model.dart';
import 'package:zoomview/features/downloads/repositories/download_repository.dart';

void main() {
  late DatabaseHelper dbHelper;
  late DownloadRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting();
    repo = DownloadRepository(dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('addDownload and getAll', () async {
    await repo.addDownload(
      url: 'https://example.com/file.pdf',
      fileName: 'file.pdf',
      filePath: '/downloads/file.pdf',
    );
    final downloads = await repo.getAll();
    expect(downloads.length, 1);
    expect(downloads.first.fileName, 'file.pdf');
    expect(downloads.first.status, DownloadStatus.pending);
  });

  test('updateStatus changes status', () async {
    await repo.addDownload(
      url: 'https://example.com/f.zip',
      fileName: 'f.zip',
      filePath: '/downloads/f.zip',
    );
    final downloads = await repo.getAll();
    await repo.updateStatus(downloads.first.id!, DownloadStatus.downloading);
    final updated = await repo.getAll();
    expect(updated.first.status, DownloadStatus.downloading);
  });

  test('updateProgress updates bytes', () async {
    await repo.addDownload(
      url: 'https://example.com/f.zip',
      fileName: 'f.zip',
      filePath: '/downloads/f.zip',
      totalBytes: 1000,
    );
    final downloads = await repo.getAll();
    await repo.updateProgress(downloads.first.id!, 500);
    final updated = await repo.getAll();
    expect(updated.first.downloadedBytes, 500);
  });

  test('deleteDownload removes entry', () async {
    await repo.addDownload(
      url: 'https://example.com/f.zip',
      fileName: 'f.zip',
      filePath: '/downloads/f.zip',
    );
    final downloads = await repo.getAll();
    await repo.deleteDownload(downloads.first.id!);
    final after = await repo.getAll();
    expect(after, isEmpty);
  });
}
