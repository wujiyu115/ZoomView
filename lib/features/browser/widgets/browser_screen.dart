import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';
import 'package:zoomview/features/settings/models/settings_model.dart';
import 'package:zoomview/features/settings/providers/settings_provider.dart';
import 'package:zoomview/features/bookmarks/providers/bookmark_provider.dart';
import 'package:zoomview/features/bookmarks/widgets/bookmark_screen.dart';
import 'package:zoomview/features/history/providers/history_provider.dart';
import 'package:zoomview/features/history/widgets/history_screen.dart';
import 'package:zoomview/features/settings/widgets/settings_screen.dart';
import 'package:zoomview/features/downloads/widgets/download_screen.dart';
import 'package:zoomview/features/downloads/providers/download_provider.dart';
import 'package:zoomview/l10n/app_localizations.dart';
import 'toolbar.dart';
import 'url_bar.dart';
import 'zoom_slider.dart';
import 'tab_manager.dart';
import 'webview_container.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  final Map<String, InAppWebViewController> _controllers = {};

  InAppWebViewController? get _activeController {
    final state = ref.read(browserProvider);
    return _controllers[state.activeTab.id];
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(browserProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: Column(
        children: [
          BrowserToolbar(
            onHome: () => _activeController?.loadUrl(
              urlRequest: URLRequest(url: WebUri(settings.homeUrl)),
            ),
            onBookmarks: () async {
              final url = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const BookmarkScreen()),
              );
              if (url != null) {
                _activeController?.loadUrl(
                    urlRequest: URLRequest(url: WebUri(url)));
              }
            },
            onRefresh: () => _activeController?.reload(),
            onBack: () => _activeController?.goBack(),
            onForward: () => _activeController?.goForward(),
            onMore: () => _showMoreMenu(context),
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            onTabs: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TabManager()),
            ),
            onDownloads: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadScreen()),
            ),
          ),
          UrlBar(
            url: browserState.activeTab.url,
            progress: browserState.progress,
            isLoading: browserState.isLoading,
            onSubmitted: (url) {
              _activeController?.loadUrl(
                urlRequest: URLRequest(url: WebUri(url)),
              );
            },
          ),
          Expanded(
            child: IndexedStack(
              index: browserState.activeTabIndex,
              children: List.generate(browserState.tabs.length, (i) {
                final tab = browserState.tabs[i];
                return WebViewContainer(
                  key: ValueKey(tab.id),
                  tabIndex: i,
                  initialUrl: tab.url,
                  onControllerCreated: (controller) {
                    _controllers[tab.id] = controller;
                  },
                  onPageLoaded: (title, url) {
                    ref.read(historyProvider.notifier).addEntry(title, url);
                  },
                  onDownloadRequested: (request) {
                    final fileName = request.url.toString().split('/').last;
                    ref.read(downloadProvider.notifier).startDownload(
                          request.url.toString(),
                          fileName.isEmpty ? 'download' : fileName,
                        );
                  },
                );
              }),
            ),
          ),
          ZoomSlider(
            zoomLevel: browserState.activeTab.zoomLevel,
            minZoom: settings.minZoom,
            maxZoom: settings.maxZoom,
            onChanged: (zoom) {
              ref.read(browserProvider.notifier).updateZoom(
                    browserState.activeTabIndex, zoom);
              _activeController?.zoomBy(
                zoomFactor: zoom,
                animated: false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(l.share),
              onTap: () {
                Navigator.pop(ctx);
                final url = ref.read(browserProvider).activeTab.url;
                SharePlus.instance.share(ShareParams(uri: Uri.parse(url)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(l.findInPage),
              onTap: () {
                Navigator.pop(ctx);
                _showFindInPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.desktop_mac),
              title: Text(
                ref.read(settingsProvider).uaMode == UaMode.desktop
                    ? l.switchToMobileMode
                    : l.switchToDesktopMode,
              ),
              onTap: () {
                Navigator.pop(ctx);
                final current = ref.read(settingsProvider).uaMode;
                ref.read(settingsProvider.notifier).setUaMode(
                      current == UaMode.desktop
                          ? UaMode.mobile
                          : UaMode.desktop,
                    );
                _activeController?.reload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add),
              title: Text(l.addBookmark),
              onTap: () {
                Navigator.pop(ctx);
                final tab = ref.read(browserProvider).activeTab;
                ref.read(bookmarkProvider.notifier).addBookmark(
                      tab.title.isEmpty ? tab.url : tab.title,
                      tab.url,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.bookmarkAdded)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l.history),
              onTap: () async {
                Navigator.pop(ctx);
                final url = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
                if (url != null) {
                  _activeController?.loadUrl(
                      urlRequest: URLRequest(url: WebUri(url)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFindInPage() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: l.findInPageHint,
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                  onSubmitted: (query) {
                    _activeController?.findAllAsync(find: query);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                onPressed: () =>
                    _activeController?.findNext(forward: false),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward),
                onPressed: () =>
                    _activeController?.findNext(forward: true),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _activeController?.clearMatches();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
