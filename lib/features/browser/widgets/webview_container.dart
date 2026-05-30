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
  final void Function(String url, String suggestedFilename)?
      onDownloadUrlDetected;

  const WebViewContainer({
    super.key,
    required this.tabIndex,
    required this.initialUrl,
    required this.onControllerCreated,
    this.onPageLoaded,
    this.onDownloadRequested,
    this.onDownloadUrlDetected,
  });

  @override
  ConsumerState<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends ConsumerState<WebViewContainer> {
  InAppWebViewController? _controller;
  double? _baseScale;
  bool _ignoreZoomChanges = false;
  int _loadId = 0;

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
            var result = orig.call(window, q);
            if (q.indexOf('prefers-color-scheme') !== -1) {
              var forced = q.indexOf(scheme) !== -1;
              return new Proxy(result, {
                get: function(target, prop) {
                  if (prop === 'matches') return forced;
                  var val = target[prop];
                  if (typeof val === 'function') return val.bind(target);
                  return val;
                }
              });
            }
            return result;
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
          var orig = window.matchMedia;
          window.matchMedia = function(q) {
            var result = orig.call(window, q);
            if (q.indexOf('prefers-color-scheme') !== -1) {
              var forced = q.indexOf(scheme) !== -1;
              return new Proxy(result, {
                get: function(target, prop) {
                  if (prop === 'matches') return forced;
                  var val = target[prop];
                  if (typeof val === 'function') return val.bind(target);
                  return val;
                }
              });
            }
            return result;
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
        useShouldOverrideUrlLoading: true,
        useOnDownloadStart: true,
        allowsBackForwardNavigationGestures: true,
        preferredContentMode: settings.uaMode == UaMode.desktop
            ? UserPreferredContentMode.DESKTOP
            : UserPreferredContentMode.MOBILE,
        forceDark: settings.darkMode ? ForceDark.ON : ForceDark.OFF,
        forceDarkStrategy:
            ForceDarkStrategy.PREFER_WEB_THEME_OVER_USER_AGENT_DARKENING,
        algorithmicDarkeningAllowed: settings.darkMode,
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final uri = navigationAction.request.url;
        if (uri != null && _isDownloadUrl(uri)) {
          final fileName = _extractFileName(uri);
          widget.onDownloadUrlDetected?.call(uri.toString(), fileName);
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
      onReceivedError: (controller, request, error) {
        debugPrint('[WebView] error: isMainFrame=${request.isForMainFrame} type=${error.type} desc=${error.description} url=${request.url}');
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint('[WebView][JS ${consoleMessage.messageLevel}] ${consoleMessage.message}');
      },
      onWebViewCreated: (controller) async {
        _controller = controller;
        controller.evaluateJavascript(source: '''
          try {
            Object.defineProperty(navigator, 'webdriver', {get: () => false});
          } catch(e) {}
          try {
            if (!window.chrome) { window.chrome = { runtime: {} }; }
            Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
            Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en', 'zh-CN']});
          } catch(e) {}
          void(0);
        ''');
        widget.onControllerCreated(controller);
        final s = await controller.getSettings();
        debugPrint('[WebView] created: forceDark=${s?.forceDark}, algorithmicDarkening=${s?.algorithmicDarkeningAllowed}, darkMode=${settings.darkMode}');
      },
      onLoadStart: (controller, url) {
        controller.evaluateJavascript(source: '''
          try {
            Object.defineProperty(navigator, 'webdriver', {get: () => false});
          } catch(e) {}
          try {
            if (!window.chrome) { window.chrome = { runtime: {} }; }
            Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
            Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en', 'zh-CN']});
          } catch(e) {}
          void(0);
        ''');
        _ignoreZoomChanges = true;
        _loadId++;
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

        ref.read(browserProvider.notifier).updateZoom(widget.tabIndex, 1.0);
        _baseScale = null;
        final myLoadId = _loadId;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _loadId == myLoadId) {
            _ignoreZoomChanges = false;
          }
        });
      },
      onZoomScaleChanged: (controller, oldScale, newScale) {
        if (newScale <= 0) return;
        if (_ignoreZoomChanges) {
          _baseScale = newScale;
          return;
        }
        if (_baseScale == null || _baseScale! <= 0) {
          _baseScale = oldScale > 0 ? oldScale : newScale;
          return;
        }
        final logicalZoom = newScale / _baseScale!;
        final clamped =
            logicalZoom.clamp(AppConstants.minZoom, AppConstants.maxZoom);
        final rounded = double.parse(clamped.toStringAsFixed(1));
        final currentZoom =
            ref.read(browserProvider).tabs[widget.tabIndex].zoomLevel;
        if ((rounded - currentZoom).abs() >= 0.05) {
          ref.read(browserProvider.notifier).updateZoom(widget.tabIndex, rounded);
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

bool _isDownloadUrl(Uri uri) {
  final path = uri.path.toLowerCase();
  const exts = [
    '.zip', '.gz', '.tgz', '.bz2', '.xz', '.rar', '.7z',
    '.apk', '.ipa', '.dmg', '.exe', '.msi', '.pkg', '.deb', '.rpm',
    '.iso', '.img', '.bin', '.tar',
  ];
  for (final ext in exts) {
    if (path.endsWith(ext)) return true;
  }
  final host = uri.host;
  if (host == 'github.com' &&
      (path.contains('/releases/download/') || path.contains('/archive/'))) {
    return true;
  }
  if (host == 'objects.githubusercontent.com' ||
      host == 'codeload.github.com') {
    return true;
  }
  return false;
}

String _extractFileName(Uri uri) {
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return 'download';
  return segments.last;
}
