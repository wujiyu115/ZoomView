import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../providers/download_provider.dart';
import '../models/download_model.dart';
import 'download_item.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: downloads.isEmpty
          ? const Center(child: Text('No downloads'))
          : ListView.builder(
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final dl = downloads[index];
                return DownloadItemWidget(
                  download: dl,
                  onDelete: () =>
                      ref.read(downloadProvider.notifier).deleteRecord(dl.id!),
                  onOpen: dl.status == DownloadStatus.completed
                      ? () async {
                          final file = File(dl.filePath);
                          if (await file.exists()) {
                            await launchUrl(Uri.file(dl.filePath));
                          }
                        }
                      : null,
                );
              },
            ),
    );
  }
}
