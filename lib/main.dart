import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'app.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  FlutterDownloader.registerCallback(downloadCallback);

  runApp(
    const ProviderScope(
      child: ZoomViewApp(),
    ),
  );
}
