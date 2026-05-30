import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:zoomview/core/database/database_helper.dart';
import '../models/download_model.dart';
import '../repositories/download_repository.dart';

const _portName = 'downloader_send_port';

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepository(DatabaseHelper.instance);
});

final downloadProvider =
    NotifierProvider<DownloadNotifier, List<DownloadModel>>(
        DownloadNotifier.new);

final isDownloadingProvider = Provider<bool>((ref) {
  final downloads = ref.watch(downloadProvider);
  return downloads.any((d) => d.status == DownloadStatus.downloading);
});

class DownloadNotifier extends Notifier<List<DownloadModel>> {
  final _taskToDbId = <String, int>{};
  ReceivePort? _port;

  @override
  List<DownloadModel> build() {
    _bindPort();
    ref.onDispose(_unbindPort);
    return [];
  }

  DownloadRepository get _repo => ref.read(downloadRepositoryProvider);

  void _bindPort() {
    _unbindPort();
    _port = ReceivePort();
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);
    _port!.listen(_onDownloadCallback);
  }

  void _unbindPort() {
    IsolateNameServer.removePortNameMapping(_portName);
    _port?.close();
    _port = null;
  }

  void _onDownloadCallback(dynamic data) {
    final taskId = data[0] as String;
    final statusInt = data[1] as int;
    final progress = data[2] as int;

    debugPrint('[Download] callback: taskId=$taskId status=$statusInt progress=$progress');

    final dbId = _taskToDbId[taskId];
    if (dbId == null) {
      debugPrint('[Download] no DB mapping for taskId=$taskId');
      return;
    }

    final dlStatus = _mapStatus(statusInt);

    state = state.map((d) {
      if (d.id == dbId) {
        return d.copyWith(
          totalBytes: 100,
          downloadedBytes: progress.clamp(0, 100),
          status: dlStatus,
        );
      }
      return d;
    }).toList();

    if (dlStatus == DownloadStatus.completed || dlStatus == DownloadStatus.failed) {
      _repo.updateStatus(dbId, dlStatus);
      _repo.updateProgress(dbId, progress.clamp(0, 100));
      _taskToDbId.remove(taskId);
    }
  }

  DownloadStatus _mapStatus(int status) {
    // flutter_downloader: 1=enqueued, 2=running, 3=complete, 4=failed, 5=canceled, 6=paused
    return switch (status) {
      2 => DownloadStatus.downloading,
      3 => DownloadStatus.completed,
      4 || 5 => DownloadStatus.failed,
      6 => DownloadStatus.paused,
      _ => DownloadStatus.pending,
    };
  }

  Future<void> load() async {
    state = await _repo.getAll();
    await _syncRunningTasks();
  }

  Future<void> _syncRunningTasks() async {
    final tasks = await FlutterDownloader.loadTasks() ?? [];
    debugPrint('[Download] sync: ${tasks.length} flutter_downloader tasks, ${_taskToDbId.length} mapped');
    for (final task in tasks) {
      debugPrint('[Download] task: ${task.taskId} status=${task.status} progress=${task.progress} url=${task.url}');

      if (_taskToDbId.containsKey(task.taskId)) {
        final dlStatus = _mapStatus(task.status.index);
        if (dlStatus == DownloadStatus.completed || dlStatus == DownloadStatus.failed) {
          _onDownloadCallback([task.taskId, task.status.index, task.progress]);
        }
        continue;
      }

      final mappedDbIds = _taskToDbId.values.toSet();
      final match = state.where((d) =>
          d.url == task.url &&
          d.status == DownloadStatus.downloading &&
          d.id != null &&
          !mappedDbIds.contains(d.id)).toList();
      if (match.isNotEmpty) {
        _taskToDbId[task.taskId] = match.first.id!;
        final dlStatus = _mapStatus(task.status.index);
        if (dlStatus != DownloadStatus.downloading) {
          _onDownloadCallback([task.taskId, task.status.index, task.progress]);
        }
      }
    }
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

    debugPrint('[Download] enqueue: url=$url savePath=$savePath fileName=$fileName');

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: savePath,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
    );

    debugPrint('[Download] enqueued: taskId=$taskId dbId=$id');

    if (taskId != null) {
      _taskToDbId[taskId] = id;
    }

    await _repo.updateStatus(id, DownloadStatus.downloading);
    await load();
  }

  Future<void> deleteRecord(int id) async {
    await _repo.deleteDownload(id);
    state = state.where((d) => d.id != id).toList();
  }
}
