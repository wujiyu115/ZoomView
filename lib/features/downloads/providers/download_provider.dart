import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:zoomview/core/database/database_helper.dart';
import '../models/download_model.dart';
import '../repositories/download_repository.dart';

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepository(DatabaseHelper.instance);
});

final downloadProvider =
    NotifierProvider<DownloadNotifier, List<DownloadModel>>(
        DownloadNotifier.new);

class DownloadNotifier extends Notifier<List<DownloadModel>> {
  @override
  List<DownloadModel> build() => [];

  DownloadRepository get _repo => ref.read(downloadRepositoryProvider);

  Future<void> load() async {
    state = await _repo.getAll();
  }

  Future<void> startDownload(String url, String fileName) async {
    final dir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final savePath = '${dir!.path}/downloads';
    await Directory(savePath).create(recursive: true);

    final id = await _repo.addDownload(
      url: url,
      fileName: fileName,
      filePath: '$savePath/$fileName',
    );

    await FlutterDownloader.enqueue(
      url: url,
      savedDir: savePath,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
    );

    await _repo.updateStatus(id, DownloadStatus.downloading);
    await load();
  }

  Future<void> deleteRecord(int id) async {
    await _repo.deleteDownload(id);
    state = state.where((d) => d.id != id).toList();
  }
}
