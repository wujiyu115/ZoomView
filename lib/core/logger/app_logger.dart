import 'package:flutter/foundation.dart';

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

  bool enabled = false;
  final List<LogEntry> _entries = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void _log(LogLevel level, String tag, String message) {
    debugPrint('[$tag] $message');
    if (!enabled) return;

    _entries.add(LogEntry(
      time: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    ));
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
    notifyListeners();
  }

  void d(String tag, String message) => _log(LogLevel.debug, tag, message);
  void i(String tag, String message) => _log(LogLevel.info, tag, message);
  void w(String tag, String message) => _log(LogLevel.warning, tag, message);
  void e(String tag, String message) => _log(LogLevel.error, tag, message);

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  String export() => _entries.map((e) => e.formatted).join('\n');
}
