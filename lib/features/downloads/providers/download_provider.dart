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
const _log = 'Download';

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
    if (Platform.isAndroid) _bindPort();
    ref.onDispose(() {
      if (Platform.isAndroid) _unbindPort();
      _stopPolling();
    });
    return [];
  }

  DownloadRepository get _repo => ref.read(downloadRepositoryProvider);

  // --- Android: FlutterDownloader port/poll ---

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
      _updateState(dbId, dlStatus, progress);
    }
  }

  void _onDownloadCallback(dynamic data) {
    final taskId = data[0] as String;
    final statusInt = data[1] as int;
    final progress = data[2] as int;
    AppLogger.instance.d(_log, 'callback: taskId=$taskId status=$statusInt progress=$progress');
    final dbId = _taskToDbId[taskId];
    if (dbId == null) return;
    final dlStatus = _mapStatus(statusInt);
    _updateState(dbId, dlStatus, progress.clamp(0, 100));
    if (dlStatus == DownloadStatus.completed || dlStatus == DownloadStatus.failed) {
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

  // --- Shared state update ---

  void _updateState(int dbId, DownloadStatus dlStatus, int progress) {
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
    }
  }

  // --- Load & sync ---

  Future<void> load() async {
    state = await _repo.getAll();
    if (Platform.isAndroid) await _syncRunningTasks();
  }

  Future<void> _syncRunningTasks() async {
    final tasks = await FlutterDownloader.loadTasks() ?? [];
    AppLogger.instance.i(_log, 'sync: ${tasks.length} tasks, ${_taskToDbId.length} mapped');
    bool hasActive = false;
    for (final task in tasks) {
      AppLogger.instance.d(_log, 'task: ${task.taskId} status=${task.status} progress=${task.progress} url=${task.url}');
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
    _updateState(dbId, dlStatus, progress);
    if (dlStatus == DownloadStatus.completed || dlStatus == DownloadStatus.failed) {
      _taskToDbId.remove(task.taskId);
    }
  }

  // --- Download entry point ---

  bool _looksLikeZipSource(Uri uri) {
    final host = uri.host;
    final path = uri.path.toLowerCase();
    if (host == 'github.com') {
      if (path.contains('/releases/download/')) return true;
      if (path.contains('/archive/')) return true;
      if (path.contains('/actions/') && path.contains('/artifacts/')) return true;
      if (path.contains('/suites/') && path.contains('/artifacts/')) return true;
    }
    if (host == 'codeload.github.com') return true;
    if (host.endsWith('.githubusercontent.com')) return true;
    return false;
  }

  Future<void> startDownload(String url, String fileName) async {
    final dir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final savePath = '${dir!.path}/downloads';
    await Directory(savePath).create(recursive: true);

    if (!fileName.contains('.')) {
      final uri = Uri.tryParse(url);
      if (uri != null && _looksLikeZipSource(uri)) {
        fileName = '$fileName.zip';
      }
    }

    final targetFile = File('$savePath/$fileName');
    if (await targetFile.exists()) {
      await targetFile.delete();
      AppLogger.instance.i(_log, 'deleted existing file: $savePath/$fileName');
    }

    final id = await _repo.addDownload(
      url: url,
      fileName: fileName,
      filePath: '$savePath/$fileName',
    );

    await _repo.updateStatus(id, DownloadStatus.downloading);
    await load();

    if (Platform.isIOS) {
      await _downloadWithDart(id, url, '$savePath/$fileName');
    } else {
      await _downloadWithFlutterDownloader(id, url, savePath, fileName);
    }
    await load();
  }

  // --- iOS: Dart HttpClient download ---

  Future<void> _downloadWithDart(int dbId, String url, String filePath) async {
    AppLogger.instance.i(_log, 'dart download: url=$url filePath=$filePath');

    String cookieHeader = '';
    try {
      final cookies = await CookieManager.instance().getCookies(url: WebUri(url));
      if (cookies.isNotEmpty) {
        cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');
      }
    } catch (e) {
      AppLogger.instance.e(_log, 'failed to get cookies: $e');
    }

    _updateState(dbId, DownloadStatus.downloading, 0);

    try {
      final client = HttpClient();
      client.userAgent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1';

      final request = await client.getUrl(Uri.parse(url));
      if (cookieHeader.isNotEmpty) {
        request.headers.set('Cookie', cookieHeader);
      }

      final response = await request.close();

      if (response.statusCode >= 400) {
        AppLogger.instance.e(_log, 'HTTP ${response.statusCode} for $url');
        _updateState(dbId, DownloadStatus.failed, 0);
        client.close();
        return;
      }

      AppLogger.instance.i(_log, 'HTTP ${response.statusCode} contentLength=${response.contentLength}');

      final file = File(filePath);
      final sink = file.openWrite();
      final totalBytes = response.contentLength;
      int received = 0;
      int lastReportedPercent = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (totalBytes > 0) {
          final percent = (received * 100 ~/ totalBytes).clamp(0, 100);
          if (percent > lastReportedPercent) {
            lastReportedPercent = percent;
            _updateState(dbId, DownloadStatus.downloading, percent);
          }
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      final fileSize = await file.length();
      AppLogger.instance.i(_log, 'completed: received=$received fileSize=$fileSize path=$filePath');
      _updateState(dbId, DownloadStatus.completed, 100);
    } catch (e) {
      AppLogger.instance.e(_log, 'dart download failed: $e');
      _updateState(dbId, DownloadStatus.failed, 0);
    }
  }

  // --- Android: FlutterDownloader ---

  Future<void> _downloadWithFlutterDownloader(
      int dbId, String url, String savePath, String fileName) async {
    try {
      final oldTasks = await FlutterDownloader.loadTasks() ?? [];
      for (final t in oldTasks) {
        if (t.url == url && (t.status == DownloadTaskStatus.failed ||
            t.status == DownloadTaskStatus.canceled ||
            t.status == DownloadTaskStatus.complete)) {
          await FlutterDownloader.remove(taskId: t.taskId, shouldDeleteContent: true);
        }
      }
    } catch (e) {
      AppLogger.instance.w(_log, 'failed to clean old tasks: $e');
    }

    final headers = <String, String>{};
    try {
      final cookies = await CookieManager.instance().getCookies(url: WebUri(url));
      if (cookies.isNotEmpty) {
        headers['Cookie'] = cookies.map((c) => '${c.name}=${c.value}').join('; ');
      }
    } catch (e) {
      AppLogger.instance.e(_log, 'failed to get cookies: $e');
    }

    AppLogger.instance.i(_log, 'enqueue: url=$url fileName=$fileName savePath=$savePath');

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: savePath,
      fileName: fileName,
      headers: headers,
      showNotification: true,
      openFileFromNotification: true,
    );

    AppLogger.instance.i(_log, 'enqueued: taskId=$taskId dbId=$dbId');

    if (taskId != null) {
      _taskToDbId[taskId] = dbId;
    }
    _startPolling();
  }

  Future<void> deleteRecord(int id) async {
    await _repo.deleteDownload(id);
    state = state.where((d) => d.id != id).toList();
  }
}
