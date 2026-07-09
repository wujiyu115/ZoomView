import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/constants.dart';
import 'package:zoomview/core/logger/app_logger.dart';
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
  double _lastObservedScale = 0;
  bool _scrollRestored = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(settingsProvider.select((s) => s.darkMode), (prev, next) {
      AppLogger.instance.d('WebView', 'darkMode changed: $prev -> $next');
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
    AppLogger.instance.i('WebView', 'applied darkMode=$darkMode, scheme=$scheme');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final ua = settings.uaMode == UaMode.desktop
        ? AppConstants.desktopUserAgent
        : AppConstants.mobileUserAgent;

    final isDark = settings.darkMode;
    final scheme = isDark ? 'dark' : 'light';

    final stealthScript = UserScript(
      source: '''
(function() {
  // --- color scheme override ---
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

  // --- anti-detection ---
  try { Object.defineProperty(navigator, 'webdriver', {get: () => false}); } catch(e) {}

  // realistic plugins (matches Chrome on iOS)
  var FakePlugin = function(n, d, f) { this.name = n; this.description = d; this.filename = f; this.length = 0; };
  var fakePlugins = [
    new FakePlugin('Chrome PDF Plugin', 'Portable Document Format', 'internal-pdf-viewer'),
    new FakePlugin('Chrome PDF Viewer', '', 'mhjfbmdgcfjbbpaeojofohoefgiehjai'),
    new FakePlugin('Native Client', '', 'internal-nacl-plugin'),
  ];
  fakePlugins.refresh = function() {};
  fakePlugins.item = function(i) { return this[i] || null; };
  fakePlugins.namedItem = function(n) { for (var i=0;i<this.length;i++) if(this[i].name===n) return this[i]; return null; };
  try { Object.defineProperty(navigator, 'plugins', {get: () => fakePlugins}); } catch(e) {}

  try { Object.defineProperty(navigator, 'languages', {get: () => ['zh-CN', 'zh', 'en-US', 'en']}); } catch(e) {}

  // hide automation markers
  try { delete navigator.__proto__.webdriver; } catch(e) {}
  try { delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array; } catch(e) {}
  try { delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise; } catch(e) {}
  try { delete window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol; } catch(e) {}

  // chrome object
  if (!window.chrome) window.chrome = {};
  window.chrome.app = {isInstalled: false, InstallState: {DISABLED:'disabled',INSTALLED:'installed',NOT_INSTALLED:'not_installed'}, RunningState: {CANNOT_RUN:'cannot_run',READY_TO_RUN:'ready_to_run',RUNNING:'running'}};
  window.chrome.runtime = {OnInstalledReason: {CHROME_UPDATE:'chrome_update',INSTALL:'install',SHARED_MODULE_UPDATE:'shared_module_update',UPDATE:'update'}, OnRestartRequiredReason: {APP_UPDATE:'app_update',OS_UPDATE:'os_update',PERIODIC:'periodic'}, PlatformArch: {ARM:'arm',MIPS:'mips',MIPS64:'mips64',X86_32:'x86-32',X86_64:'x86-64'}, PlatformNaclArch: {ARM:'arm',MIPS:'mips',MIPS64:'mips64',X86_32:'x86-32',X86_64:'x86-64'}, PlatformOs: {ANDROID:'android',CROS:'cros',LINUX:'linux',MAC:'mac',OPENBSD:'openbsd',WIN:'win'}, RequestUpdateCheckStatus: {NO_UPDATE:'no_update',THROTTLED:'throttled',UPDATE_AVAILABLE:'update_available'}};
  window.chrome.csi = function() { return {startE: Date.now(), onloadT: Date.now(), pageT: 0, tran: 15}; };
  window.chrome.loadTimes = function() { return {commitLoadTime: Date.now()/1000, connectionInfo: 'h2', finishDocumentLoadTime: 0, finishLoadTime: 0, firstPaintAfterLoadTime: 0, firstPaintTime: 0, navigationType: 'Other', npnNegotiatedProtocol: 'h2', requestTime: Date.now()/1000-0.3, startLoadTime: Date.now()/1000-0.3, wasAlternateProtocolAvailable: false, wasFetchedViaSpdy: true, wasNpnNegotiated: true}; };

  // hardware fingerprint consistency
  try { Object.defineProperty(navigator, 'hardwareConcurrency', {get: () => 8}); } catch(e) {}
  try { Object.defineProperty(navigator, 'deviceMemory', {get: () => 8}); } catch(e) {}
  try { Object.defineProperty(navigator, 'maxTouchPoints', {get: () => 5}); } catch(e) {}
  try { Object.defineProperty(navigator, 'vendor', {get: () => 'Apple Computer, Inc.'}); } catch(e) {}
  try { Object.defineProperty(navigator, 'platform', {get: () => 'iPhone'}); } catch(e) {}

  // Permissions API
  if (!navigator.permissions) {
    navigator.permissions = {
      query: function(desc) {
        return Promise.resolve({state: desc.name === 'notifications' ? 'denied' : 'prompt', onchange: null});
      }
    };
  }

  // Notification API stub
  if (!window.Notification) {
    window.Notification = function() {};
    window.Notification.permission = 'default';
    window.Notification.requestPermission = function() { return Promise.resolve('default'); };
  }

  // hide InAppWebView markers (keep flutter_inappwebview bridge functional)
  try { delete window.__InAppBrowser; } catch(e) {}
  try { Object.defineProperty(window, 'flutter_inappwebview', { enumerable: false }); } catch(e) {}

  // WebGL vendor/renderer consistency (Apple GPU)
  var origGetParameter = WebGLRenderingContext.prototype.getParameter;
  WebGLRenderingContext.prototype.getParameter = function(p) {
    if (p === 37445) return 'Apple Inc.';
    if (p === 37446) return 'Apple GPU';
    return origGetParameter.call(this, p);
  };
  if (typeof WebGL2RenderingContext !== 'undefined') {
    var origGetParameter2 = WebGL2RenderingContext.prototype.getParameter;
    WebGL2RenderingContext.prototype.getParameter = function(p) {
      if (p === 37445) return 'Apple Inc.';
      if (p === 37446) return 'Apple GPU';
      return origGetParameter2.call(this, p);
    };
  }
})();
      ''',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    );

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl.isEmpty ? 'about:blank' : widget.initialUrl)),
      initialUserScripts: UnmodifiableListView([stealthScript]),
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
        AppLogger.instance.d('Download', 'shouldOverrideUrlLoading: url=$uri isDownload=${uri != null ? _isDownloadUrl(uri) : false}');
        if (uri != null && _isDownloadUrl(uri)) {
          final fileName = _extractFileName(uri);
          AppLogger.instance.i('Download', 'INTERCEPTED download url=$uri fileName=$fileName');
          widget.onDownloadUrlDetected?.call(uri.toString(), fileName);
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
      onReceivedError: (controller, request, error) {
        AppLogger.instance.e('WebView', 'error: isMainFrame=${request.isForMainFrame} type=${error.type} desc=${error.description} url=${request.url}');
      },
      onConsoleMessage: (controller, consoleMessage) {
        AppLogger.instance.d('WebView', 'JS ${consoleMessage.messageLevel}: ${consoleMessage.message}');
      },
      onWebViewCreated: (controller) async {
        _controller = controller;
        controller.addJavaScriptHandler(
          handlerName: 'onDownloadLink',
          callback: (args) {
            AppLogger.instance.i('Download', 'JS bridge onDownloadLink: args=$args');
            if (args.isNotEmpty) {
              final url = args[0].toString();
              final fileName =
                  args.length > 1 ? args[1].toString() : 'download';
              widget.onDownloadUrlDetected?.call(url, fileName);
            }
            return null;
          },
        );
        widget.onControllerCreated(controller);
        final s = await controller.getSettings();
        AppLogger.instance.i('WebView', 'created: forceDark=${s?.forceDark}, algorithmicDarkening=${s?.algorithmicDarkeningAllowed}, darkMode=${settings.darkMode}');
      },
      onLoadStart: (controller, url) {
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
        AppLogger.instance.d('WebView', 'onLoadStop: injected colorScheme=$colorScheme');

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

        await controller.evaluateJavascript(source: '''
          (function() {
            if (window.__dlInterceptorInstalled) return;
            window.__dlInterceptorInstalled = true;
            var exts = ['.zip','.gz','.tgz','.bz2','.xz','.rar','.7z','.apk','.ipa','.dmg','.exe','.msi','.pkg','.deb','.rpm','.iso','.img','.bin','.tar'];
            function isDl(href) {
              try {
                var u = new URL(href, location.href);
                var p = u.pathname.toLowerCase();
                for (var i = 0; i < exts.length; i++) { if (p.endsWith(exts[i])) return true; }
                var h = u.hostname;
                if (h === 'github.com') {
                  if (p.indexOf('/releases/download/') !== -1) return true;
                  if (p.indexOf('/archive/') !== -1) return true;
                  if (p.indexOf('/actions/') !== -1 && p.indexOf('/artifacts/') !== -1) return true;
                  if (p.indexOf('/suites/') !== -1 && p.indexOf('/artifacts/') !== -1) return true;
                }
                if (h.endsWith('.githubusercontent.com') || h === 'codeload.github.com') return true;
              } catch(e) {}
              return false;
            }
            document.addEventListener('click', function(e) {
              var el = e.target;
              var tag = el ? (el.tagName || '') + '.' + (el.className || '') : 'null';
              var link = el ? el.closest('a[href]') : null;
              if (!link) {
                console.log('[DL-INTERCEPT] click on non-link: tag=' + tag + ' outerHTML=' + (el ? el.outerHTML.substring(0, 200) : 'null'));
                return;
              }
              var href = link.getAttribute('href');
              if (!href) return;
              var hasDlAttr = link.hasAttribute('download');
              var matchesDl = isDl(href);
              console.log('[DL-INTERCEPT] click on link: href=' + href + ' download=' + hasDlAttr + ' isDl=' + matchesDl);
              if (hasDlAttr || matchesDl) {
                try {
                  var u = new URL(href, location.href);
                  var name = u.pathname.split('/').pop() || 'download';
                  var bridgeOk = !!(window.flutter_inappwebview && window.flutter_inappwebview.callHandler);
                  console.log('[DL-INTERCEPT] MATCH: url=' + u.href + ' name=' + name + ' bridge=' + bridgeOk);
                  if (bridgeOk) {
                    e.preventDefault();
                    e.stopPropagation();
                    window.flutter_inappwebview.callHandler('onDownloadLink', u.href, name);
                  }
                } catch(err) { console.log('[DL-INTERCEPT] ERROR: ' + err.message); }
              }
            }, true);
          })();
        ''');

        _baseScale = null;
        _lastObservedScale = 0;
        final myLoadId = _loadId;
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (!mounted || _loadId != myLoadId) return;
          _baseScale = _lastObservedScale > 0 ? _lastObservedScale : null;
          final storedZoom =
              ref.read(browserProvider).tabs[widget.tabIndex].zoomLevel;
          if (storedZoom != 1.0 && _controller != null) {
            await _controller!.zoomBy(
                zoomFactor: storedZoom, animated: false);
          }
          final storedScroll =
              ref.read(browserProvider).tabs[widget.tabIndex].scrollPosition;
          if (!_scrollRestored && storedScroll > 0 && _controller != null) {
            await _controller!
                .scrollTo(x: 0, y: storedScroll.toInt(), animated: false);
          }
          _scrollRestored = true;
          if (mounted && _loadId == myLoadId) {
            _ignoreZoomChanges = false;
          }
        });
      },
      onZoomScaleChanged: (controller, oldScale, newScale) {
        if (newScale <= 0) return;
        if (_ignoreZoomChanges) {
          _lastObservedScale = newScale;
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
      onNavigationResponse: (controller, navigationResponse) async {
        if (!navigationResponse.isForMainFrame) {
          return NavigationResponseAction.ALLOW;
        }
        final response = navigationResponse.response;
        if (response == null) return NavigationResponseAction.ALLOW;

        final mimeType = response.mimeType?.toLowerCase() ?? '';
        final url = response.url;
        final headers = response.headers ?? {};
        final contentDisposition = headers['Content-Disposition']?.toLowerCase()
            ?? headers['content-disposition']?.toLowerCase()
            ?? '';
        final isAttachment = contentDisposition.contains('attachment');

        AppLogger.instance.d('Download', 'onNavigationResponse: url=$url mime=$mimeType canShow=${navigationResponse.canShowMIMEType} isAttachment=$isAttachment isDownloadUrl=${url != null ? _isDownloadUrl(url) : false}');

        if (!navigationResponse.canShowMIMEType ||
            isAttachment ||
            (mimeType.isNotEmpty && !_isWebMimeType(mimeType)) ||
            (url != null && _isDownloadUrl(url))) {
          final fileName = response.suggestedFilename ??
              _fileNameFromDisposition(contentDisposition) ??
              (url != null ? _extractFileName(url) : 'download');
          widget.onDownloadUrlDetected?.call(
              url?.toString() ?? '', fileName);
          Future.microtask(() async {
            if (await controller.canGoBack()) {
              controller.goBack();
            } else {
              controller.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
              ref.read(browserProvider.notifier).showStartPageAt(widget.tabIndex);
              ref.read(browserProvider.notifier).updateUrl(widget.tabIndex, '');
            }
          });
          return NavigationResponseAction.CANCEL;
        }
        return NavigationResponseAction.ALLOW;
      },
      onProgressChanged: (controller, progress) {
        ref.read(browserProvider.notifier).setProgress(progress / 100.0);
      },
      onDownloadStartRequest: (controller, request) {
        AppLogger.instance.i('Download', 'onDownloadStartRequest: url=${request.url} mime=${request.mimeType} filename=${request.suggestedFilename} contentLength=${request.contentLength}');
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
  if (host == 'github.com') {
    if (path.contains('/releases/download/')) return true;
    if (path.contains('/archive/')) return true;
    if (path.contains('/actions/') && path.contains('/artifacts/')) return true;
    if (path.contains('/suites/') && path.contains('/artifacts/')) return true;
  }
  if (host.endsWith('.githubusercontent.com') ||
      host == 'codeload.github.com') {
    return true;
  }
  return false;
}

bool _isWebMimeType(String mimeType) {
  if (mimeType.startsWith('text/')) return true;
  if (mimeType.startsWith('image/')) return true;
  if (mimeType.startsWith('audio/')) return true;
  if (mimeType.startsWith('video/')) return true;
  const webTypes = [
    'application/json',
    'application/javascript',
    'application/xml',
    'application/xhtml+xml',
    'application/pdf',
    'application/x-javascript',
    'application/ecmascript',
    'application/rss+xml',
    'application/atom+xml',
    'application/wasm',
    'application/manifest+json',
    'multipart/form-data',
  ];
  return webTypes.contains(mimeType);
}

String? _fileNameFromDisposition(String disposition) {
  if (disposition.isEmpty) return null;
  final regex = RegExp(r'''filename\*?=(?:UTF-8''|"?)([^";]+)"?''', caseSensitive: false);
  final match = regex.firstMatch(disposition);
  if (match != null) {
    final name = Uri.decodeFull(match.group(1)!.trim());
    if (name.isNotEmpty) return name;
  }
  return null;
}

String _extractFileName(Uri uri) {
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return 'download';
  return segments.last;
}
