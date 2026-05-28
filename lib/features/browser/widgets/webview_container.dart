import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/constants.dart';
import 'package:zoomview/features/settings/models/settings_model.dart';
import 'package:zoomview/features/settings/providers/settings_provider.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';

class WebViewContainer extends ConsumerStatefulWidget {
  final int tabIndex;
  final String initialUrl;
  final void Function(InAppWebViewController) onControllerCreated;
  final void Function(String title, String url)? onPageLoaded;
  final void Function(DownloadStartRequest request)? onDownloadRequested;

  const WebViewContainer({
    super.key,
    required this.tabIndex,
    required this.initialUrl,
    required this.onControllerCreated,
    this.onPageLoaded,
    this.onDownloadRequested,
  });

  @override
  ConsumerState<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends ConsumerState<WebViewContainer> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final ua = settings.uaMode == UaMode.desktop
        ? AppConstants.desktopUserAgent
        : AppConstants.mobileUserAgent;

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      initialSettings: InAppWebViewSettings(
        userAgent: ua,
        builtInZoomControls: false,
        displayZoomControls: false,
        useWideViewPort: true,
        loadWithOverviewMode: true,
        supportZoom: true,
        javaScriptEnabled: true,
      ),
      onWebViewCreated: (controller) {
        widget.onControllerCreated(controller);
      },
      onLoadStart: (controller, url) {
        ref.read(browserProvider.notifier).setLoading(true);
        if (url != null) {
          ref
              .read(browserProvider.notifier)
              .updateUrl(widget.tabIndex, url.toString());
        }
      },
      onLoadStop: (controller, url) async {
        ref.read(browserProvider.notifier).setLoading(false);
        final title = await controller.getTitle() ?? '';
        ref.read(browserProvider.notifier).updateTitle(widget.tabIndex, title);

        if (url != null && title.isNotEmpty) {
          widget.onPageLoaded?.call(title, url.toString());
        }

        // Force enable zoom on pages that disable it
        await controller.evaluateJavascript(source: '''
          var meta = document.querySelector('meta[name="viewport"]');
          if (meta) {
            meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=10.0, user-scalable=yes');
          }
        ''');
      },
      onProgressChanged: (controller, progress) {
        ref.read(browserProvider.notifier).setProgress(progress / 100.0);
      },
      onDownloadStartRequest: (controller, request) {
        widget.onDownloadRequested?.call(request);
      },
    );
  }
}
