import 'package:flutter/material.dart';
import 'package:zoomview/l10n/app_localizations.dart';
import '../models/download_model.dart';

class DownloadItemWidget extends StatelessWidget {
  final DownloadModel download;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;

  const DownloadItemWidget({
    super.key,
    required this.download,
    required this.onDelete,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListTile(
      leading: Icon(_statusIcon, color: _statusColor),
      title:
          Text(download.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (download.status == DownloadStatus.downloading)
            LinearProgressIndicator(value: download.progressPercent),
          Text(_statusText(l),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (download.status == DownloadStatus.completed && onOpen != null)
            IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                onPressed: onOpen),
          IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete),
        ],
      ),
    );
  }

  IconData get _statusIcon => switch (download.status) {
        DownloadStatus.pending => Icons.hourglass_empty,
        DownloadStatus.downloading => Icons.downloading,
        DownloadStatus.paused => Icons.pause_circle_outline,
        DownloadStatus.completed => Icons.check_circle_outline,
        DownloadStatus.failed => Icons.error_outline,
      };

  Color get _statusColor => switch (download.status) {
        DownloadStatus.completed => Colors.green,
        DownloadStatus.failed => Colors.red,
        DownloadStatus.downloading => Colors.blue,
        _ => Colors.grey,
      };

  String _statusText(AppLocalizations l) => switch (download.status) {
        DownloadStatus.pending => l.pending,
        DownloadStatus.downloading =>
          '${(download.progressPercent * 100).round()}%',
        DownloadStatus.paused => l.paused,
        DownloadStatus.completed => l.completed,
        DownloadStatus.failed => l.failed,
      };
}
