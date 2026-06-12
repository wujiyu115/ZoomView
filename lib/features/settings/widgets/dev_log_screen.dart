import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/core/logger/app_logger.dart';
import 'package:zoomview/core/widgets/ios_nav_header.dart';
import 'package:zoomview/l10n/app_localizations.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DevLogScreen extends StatelessWidget {
  const DevLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            IosNavHeader(
              title: l.viewLogs,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      final text = AppLogger.instance.export();
                      if (text.isEmpty) return;
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.logsCopied)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.copy, size: 20, color: colors.accent),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _exportLogs(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.ios_share, size: 20, color: colors.accent),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      AppLogger.instance.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.clearLogs)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.delete_outline, size: 20, color: colors.danger),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: AppLogger.instance,
                builder: (context, _) {
                  final entries = AppLogger.instance.entries;
                  if (entries.isEmpty) {
                    return Center(
                      child: Text(l.noLogs, style: TextStyle(color: colors.muted)),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[entries.length - 1 - index];
                      return _LogRow(entry: entry);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportLogs(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final text = AppLogger.instance.export();
    if (text.isEmpty) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/zoomview_log.txt');
    await file.writeAsString(text);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.exportLogs)),
      );
    }
  }
}

class _LogRow extends StatelessWidget {
  final LogEntry entry;
  const _LogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final time = '${entry.time.hour.toString().padLeft(2, '0')}:'
        '${entry.time.minute.toString().padLeft(2, '0')}:'
        '${entry.time.second.toString().padLeft(2, '0')}';

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: entry.formatted));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: TextStyle(fontSize: 11, color: colors.muted, fontFamily: 'Menlo'),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _levelColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _levelLabel,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _levelColor),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '[${entry.tag}] ${entry.message}',
                style: TextStyle(fontSize: 12, color: colors.fg2, fontFamily: 'Menlo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _levelLabel => switch (entry.level) {
        LogLevel.debug => 'DBG',
        LogLevel.info => 'INF',
        LogLevel.warning => 'WRN',
        LogLevel.error => 'ERR',
      };

  Color get _levelColor => switch (entry.level) {
        LogLevel.debug => const Color(0xFF8B949E),
        LogLevel.info => const Color(0xFF0969DA),
        LogLevel.warning => const Color(0xFFE8590C),
        LogLevel.error => const Color(0xFFCF222E),
      };
}
