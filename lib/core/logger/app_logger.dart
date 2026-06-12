import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  const LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get formatted {
    final t = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
    final l = level.name.toUpperCase();
    return '$t [$l] [$tag] $message';
  }
}

class AppLogger extends ChangeNotifier {
  AppLogger._();
  static final instance = AppLogger._();

  static const _maxEntries = 500;
  static const _logFileName = 'zoomview_debug.log';

  bool _enabled = false;
  final List<LogEntry> _entries = [];
  File? _logFile;
  IOSink? _sink;

  bool get enabled => _enabled;

  set enabled(bool value) {
    _enabled = value;
    if (value) {
      _openSink();
    } else {
      _closeSink();
    }
  }

  List<LogEntry> get entries => List.unmodifiable(_entries);

  Future<void> init() async {
    final dir = await getTemporaryDirectory();
    _logFile = File('${dir.path}/$_logFileName');
    if (_enabled) {
      await _loadFromFile();
      _openSink();
    }
  }

  void _openSink() {
    _closeSink();
    final file = _logFile;
    if (file == null) return;
    _sink = file.openWrite(mode: FileMode.append);
  }

  void _closeSink() {
    _sink?.flush();
    _sink?.close();
    _sink = null;
  }

  Future<void> _loadFromFile() async {
    final file = _logFile;
    if (file == null || !file.existsSync()) return;

    try {
      final lines = await file.readAsLines();
      final levelMap = {
        'DEBUG': LogLevel.debug,
        'INFO': LogLevel.info,
        'WARNING': LogLevel.warning,
        'ERROR': LogLevel.error,
      };
      final regex = RegExp(
        r'^(\d{2}:\d{2}:\d{2}\.\d{3}) \[(\w+)\] \[([^\]]+)\] (.*)$',
      );
      for (final line in lines) {
        final match = regex.firstMatch(line);
        if (match == null) continue;
        final timeParts = match.group(1)!.split(RegExp(r'[:.]'));
        final level = levelMap[match.group(2)!] ?? LogLevel.debug;
        final tag = match.group(3)!;
        final message = match.group(4)!;
        final now = DateTime.now();
        _entries.add(LogEntry(
          time: DateTime(
            now.year, now.month, now.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            int.parse(timeParts[2]),
            int.parse(timeParts[3]),
          ),
          level: level,
          tag: tag,
          message: message,
        ));
      }
      if (_entries.length > _maxEntries) {
        _entries.removeRange(0, _entries.length - _maxEntries);
      }
      notifyListeners();
    } catch (_) {}
  }

  void _log(LogLevel level, String tag, String message) {
    debugPrint('[$tag] $message');
    if (!_enabled) return;

    final entry = LogEntry(
      time: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
    _sink?.writeln(entry.formatted);
    notifyListeners();
  }

  void d(String tag, String message) => _log(LogLevel.debug, tag, message);
  void i(String tag, String message) => _log(LogLevel.info, tag, message);
  void w(String tag, String message) => _log(LogLevel.warning, tag, message);
  void e(String tag, String message) => _log(LogLevel.error, tag, message);

  void clear() {
    _entries.clear();
    _closeSink();
    _logFile?.deleteSync();
    if (_enabled) _openSink();
    notifyListeners();
  }

  String export() => _entries.map((e) => e.formatted).join('\n');
}
