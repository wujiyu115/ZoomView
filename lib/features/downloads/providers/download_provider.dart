import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:zoomview/core/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  Timer? _pollTimer;

  @override
  List<DownloadModel> build() {
    _bindPort();
    ref.onDispose(() {
      _unbindPort();
      _stopPolling();
    });
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

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pollProgress());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollProgress() async {
    if (!state.any((d) => d.status == DownloadStatus.downloading)) {
      _stopPolling();
      return;
    }

    final tasks = await FlutterDownloader.loadTasks() ?? [];
    for (final task in tasks) {
      final dbId = _taskToDbId[task.taskId];
      if (dbId == null) continue;

      final dlStatus = _mapStatus(task.status.index);
      final progress = task.progress.clamp(0, 100);

      final current = state.where((d) => d.id == dbId).firstOrNull;
      if (current == null) continue;
      if (current.downloadedBytes == progress && current.status == dlStatus) continue;

      state = state.map((d) {
        if (d.id == dbId) {
          return d.copyWith(
            totalBytes: 100,
            downloadedBytes: progress,
            status: dlStatus,
          );
        }
        return d;
      }).toList();

      if (dlStatus == DownloadStatus.completed || dlStatus == DownloadStatus.failed) {
        _repo.updateStatus(dbId, dlStatus);
        _repo.updateProgress(dbId, progress);
        _taskToDbId.remove(task.taskId);
      }
    }
  }

  void _onDownloadCallback(dynamic data) {
    final taskId = data[0] as String;
    final statusInt = data[1] as int;
    final progress = data[2] as int;

    AppLogger.instance.d('Download', 'callback: taskId=$taskId status=$statusInt progress=$progress');

    final dbId = _taskToDbId[taskId];
    if (dbId == null) {
      AppLogger.instance.w('Download', 'no DB mapping for taskId=$taskId');
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
    AppLogger.instance.i('Download', 'sync: ${tasks.length} tasks, ${_taskToDbId.length} mapped');
    bool hasActive = false;

    for (final task in tasks) {
      AppLogger.instance.d('Download', 'task: ${task.taskId} status=${task.status} progress=${task.progress} url=${task.url}');

      if (_taskToDbId.containsKey(task.taskId)) {
        _applyTaskUpdate(task);
        if (task.status == DownloadTaskStatus.running || task.status == DownloadTaskStatus.enqueued) {
          hasActive = true;
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
        _applyTaskUpdate(task);
        if (task.status == DownloadTaskStatus.running || task.status == DownloadTaskStatus.enqueued) {
          hasActive = true;
        }
      }
    }

    if (hasActive) _startPolling();
  }

  void _applyTaskUpdate(DownloadTask task) {
    final dbId = _taskToDbId[task.taskId];
    if (dbId == null) return;

    final dlStatus = _mapStatus(task.status.index);
    final progress = task.progress.clamp(0, 100);

    state = state.map((d) {
      if (d.id == dbId) {
        return d.copyWith(
          totalBytes: 100,
          downloadedBytes: progress,
          status: dlStatus,
        );
      }
      return d;
    }).toList();

    if (dlStatus == DownloadStatus.completed || dlStatus == DownloadStatus.failed) {
      _repo.updateStatus(dbId, dlStatus);
      _repo.updateProgress(dbId, progress);
      _taskToDbId.remove(task.taskId);
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

    final headers = <String, String>{};
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri(url));
      if (cookies.isNotEmpty) {
        headers['Cookie'] =
            cookies.map((c) => '${c.name}=${c.value}').join('; ');
      }
    } catch (e) {
      AppLogger.instance.e('Download', 'failed to get cookies: $e');
    }

    AppLogger.instance.i('Download', 'enqueue: url=$url fileName=$fileName');

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: savePath,
      fileName: fileName,
      headers: headers,
      showNotification: true,
      openFileFromNotification: true,
    );

    AppLogger.instance.i('Download', 'enqueued: taskId=$taskId dbId=$id');

    if (taskId != null) {
      _taskToDbId[taskId] = id;
    }

    await _repo.updateStatus(id, DownloadStatus.downloading);
    await load();
    _startPolling();
  }

  Future<void> deleteRecord(int id) async {
    await _repo.deleteDownload(id);
    state = state.where((d) => d.id != id).toList();
  }
}
