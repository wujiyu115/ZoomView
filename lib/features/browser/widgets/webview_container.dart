import 'dart:collection';
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
  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
    ref.listenManual(settingsProvider.select((s) => s.darkMode), (prev, next) {
      debugPrint('[WebView] darkMode changed: $prev -> $next');
      _applyDarkMode(next);
    });
  }

  Future<void> _applyDarkMode(bool darkMode) async {
    final controller = _controller;
    if (controller == null) return;

    await controller.setSettings(
      settings: InAppWebViewSettings(
        algorithmicDarkeningAllowed: darkMode,
      ),
    );

    final scheme = darkMode ? 'dark' : 'light';
    await controller.removeAllUserScripts();
    await controller.addUserScript(userScript: UserScript(
      source: '''
        (function() {
          var scheme = '$scheme';
          var orig = window.matchMedia;
          window.matchMedia = function(q) {
            if (q.indexOf('prefers-color-scheme') !== -1) {
              var m = orig.call(window, q);
              var forced = q.indexOf(scheme) !== -1;
              return Object.defineProperty(
                Object.create(m),
                'matches',
                { get: function() { return forced; } }
              );
            }
            return orig.call(window, q);
          };
          document.documentElement.style.colorScheme = scheme;
        })();
      ''',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ));

    await controller.reload();
    debugPrint('[WebView] applied darkMode=$darkMode, scheme=$scheme');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final ua = settings.uaMode == UaMode.desktop
        ? AppConstants.desktopUserAgent
        : AppConstants.mobileUserAgent;

    final isDark = settings.darkMode;
    final colorSchemeScript = UserScript(
      source: '''
        (function() {
          var scheme = '${isDark ? 'dark' : 'light'}';
          var anti  = '${isDark ? 'light' : 'dark'}';
          var orig = window.matchMedia;
          window.matchMedia = function(q) {
            if (q.indexOf('prefers-color-scheme') !== -1) {
              var m = orig.call(window, q);
              var forced = q.indexOf(scheme) !== -1;
              return Object.defineProperty(
                Object.create(m),
                'matches',
                { get: function() { return forced; } }
              );
            }
            return orig.call(window, q);
          };
          document.documentElement.style.colorScheme = scheme;
        })();
      ''',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    );

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      initialUserScripts: UnmodifiableListView([colorSchemeScript]),
      initialSettings: InAppWebViewSettings(
        userAgent: ua,
        builtInZoomControls: false,
        displayZoomControls: false,
        useWideViewPort: true,
        loadWithOverviewMode: true,
        supportZoom: true,
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        preferredContentMode: settings.uaMode == UaMode.desktop
            ? UserPreferredContentMode.DESKTOP
            : UserPreferredContentMode.MOBILE,
        forceDark: settings.darkMode ? ForceDark.ON : ForceDark.OFF,
        forceDarkStrategy:
            ForceDarkStrategy.PREFER_WEB_THEME_OVER_USER_AGENT_DARKENING,
        algorithmicDarkeningAllowed: settings.darkMode,
      ),
      onWebViewCreated: (controller) async {
        _controller = controller;
        controller.evaluateJavascript(source: '''
          Object.defineProperty(navigator, 'webdriver', {get: () => false});
          if (!window.chrome) { window.chrome = { runtime: {} }; }
          Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
          Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en', 'zh-CN']});
        ''');
        widget.onControllerCreated(controller);
        final s = await controller.getSettings();
        debugPrint('[WebView] created: forceDark=${s?.forceDark}, algorithmicDarkening=${s?.algorithmicDarkeningAllowed}, darkMode=${settings.darkMode}');
      },
      onLoadStart: (controller, url) {
        controller.evaluateJavascript(source: '''
          Object.defineProperty(navigator, 'webdriver', {get: () => false});
          if (!window.chrome) { window.chrome = { runtime: {} }; }
          Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
          Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en', 'zh-CN']});
        ''');
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

        final isDark = ref.read(settingsProvider).darkMode;
        final colorScheme = isDark ? 'dark' : 'light';
        await controller.evaluateJavascript(source: '''
          document.documentElement.style.colorScheme = '$colorScheme';
          var csMeta = document.querySelector('meta[name="color-scheme"]');
          if (!csMeta) {
            csMeta = document.createElement('meta');
            csMeta.name = 'color-scheme';
            document.head.appendChild(csMeta);
          }
          csMeta.setAttribute('content', '$colorScheme');
        ''');
        debugPrint('[WebView] onLoadStop: injected colorScheme=$colorScheme');

        // Force desktop viewport and enable zoom
        final viewportSettings = ref.read(settingsProvider);
        final viewportWidth = viewportSettings.uaMode == UaMode.desktop
            ? viewportSettings.viewportWidth
            : 0;
        if (viewportWidth > 0) {
          await controller.evaluateJavascript(source: '''
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
              meta = document.createElement('meta');
              meta.name = 'viewport';
              document.head.appendChild(meta);
            }
            meta.setAttribute('content', 'width=$viewportWidth, initial-scale=0.25, maximum-scale=10.0, user-scalable=yes');
          ''');
        } else {
          await controller.evaluateJavascript(source: '''
            var meta = document.querySelector('meta[name="viewport"]');
            if (meta) {
              meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=10.0, user-scalable=yes');
            }
          ''');
        }
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
