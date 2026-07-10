import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/core/widgets/ios_nav_header.dart';
import 'package:zoomview/core/widgets/grouped_card.dart';
import 'package:zoomview/core/widgets/colored_icon_box.dart';
import 'package:zoomview/l10n/app_localizations.dart';
import 'dart:io';
import '../providers/download_provider.dart';
import '../models/download_model.dart';

class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});
  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(downloadProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadProvider);
    final colors = context.appColors;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            IosNavHeader(title: l.downloads),
            Expanded(
              child: downloads.isEmpty
                  ? Center(
                      child: Text(l.noDownloads, style: TextStyle(color: colors.muted)),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        GroupedCard(
                          children: downloads.map((dl) {
                            return _DownloadRow(
                              download: dl,
                              onDelete: () => ref.read(downloadProvider.notifier).deleteRecord(dl.id!),
                              onShare: dl.status == DownloadStatus.completed
                                  ? () => _shareFile(dl)
                                  : null,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareFile(DownloadModel dl) async {
    final file = File(dl.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failed)),
        );
      }
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(dl.filePath, mimeType: _mimeTypeFor(dl.filePath))],
      ),
    );
  }

  String? _mimeTypeFor(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return null;
    final ext = path.substring(dot + 1).toLowerCase();
    const map = {
      'zip': 'application/zip',
      'gz': 'application/gzip',
      'tgz': 'application/gzip',
      'bz2': 'application/x-bzip2',
      'xz': 'application/x-xz',
      'rar': 'application/vnd.rar',
      '7z': 'application/x-7z-compressed',
      'tar': 'application/x-tar',
      'apk': 'application/vnd.android.package-archive',
      'ipa': 'application/octet-stream',
      'dmg': 'application/x-apple-diskimage',
      'exe': 'application/vnd.microsoft.portable-executable',
      'msi': 'application/x-msi',
      'pkg': 'application/octet-stream',
      'deb': 'application/vnd.debian.binary-package',
      'rpm': 'application/x-rpm',
      'iso': 'application/x-iso9660-image',
      'img': 'application/octet-stream',
      'bin': 'application/octet-stream',
      'pdf': 'application/pdf',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
      'txt': 'text/plain',
      'json': 'application/json',
    };
    return map[ext];
  }
}

class _DownloadRow extends StatelessWidget {
  final DownloadModel download;
  final VoidCallback onDelete;
  final VoidCallback? onShare;

  const _DownloadRow({
    required this.download,
    required this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ColoredIconBox.settings(
            color: _statusColor,
            icon: _statusIcon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  download.fileName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (download.status == DownloadStatus.downloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(
                      value: download.progressPercent,
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(2),
                      color: colors.accent,
                      backgroundColor: colors.border,
                    ),
                  ),
                Text(
                  _statusText(l),
                  style: TextStyle(fontSize: 12, color: colors.muted),
                ),
              ],
            ),
          ),
          if (download.status == DownloadStatus.completed && onShare != null)
            IconButton(
              icon: Icon(Icons.share_outlined, size: 18, color: colors.accent),
              onPressed: onShare,
            ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: colors.muted),
            onPressed: onDelete,
          ),
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
        DownloadStatus.completed => const Color(0xFF17A34A),
        DownloadStatus.failed => const Color(0xFFCF222E),
        DownloadStatus.downloading => const Color(0xFF0969DA),
        _ => const Color(0xFF8B949E),
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
